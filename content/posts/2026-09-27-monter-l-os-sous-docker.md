---
title: "Monter l'OS sous Docker : ce qui reste couplé, et ce que rien ne valide"
standfirst: "L'application vit dans une image, donc la distribution ne peut rien lui faire. Restent quatre points de couplage — et l'un d'eux se trouve dans un angle mort qu'aucune chaîne d'intégration ne couvre."
date: 2026-09-27
slug: monter-l-os-sous-docker
draft: true
---

Show me the REX tourne sur un hôte unique : un Postgres, un Redis, un proxy frontal, et l'application déployée en blue-green — deux instances identiques, « bleue » et « verte », dont une seule sert le trafic à la fois. La nouvelle version est démarrée sur celle qui dort, et quand elle répond correctement, on bascule le proxy dessus. Au moment où nous écrivons, cet hôte sert 52 REX publiés et un peu plus de 16 000 vues cumulées.

Ce dispositif protège une livraison : si la nouvelle version se comporte mal, rebasculer prend une seconde et personne ne s'en aperçoit. Il ne protège rien du tout contre la machine elle-même, puisque les deux instances vivent sur ce même hôte — arrêtez-le, vous les arrêtez toutes les deux.

L'hôte unique est un choix assumé, pas une négligence : pas de redondance tant que le trafic ne la justifie pas, et le seuil de révision est écrit — mille visites par jour. En dessous, une seconde machine coûte bien plus en complexité (réplication, bascule, cohérence) qu'elle ne rapporte en disponibilité, et la complexité dont personne n'a encore besoin est la chose la plus chère qu'on puisse construire.

Assumer ce choix crée une obligation, en revanche. Si on accepte qu'un redémarrage coupe le service, on se doit d'avoir le chiffre exact de ce que ça coûte. C'est précisément là qu'on s'est plantés cette nuit-là, et on y revient à la fin.

Nous avons fait passer cet hôte d'une version d'Ubuntu à la suivante. L'opération est passée, et ce n'est pas l'intéressant. L'intéressant, c'est que la conteneurisation a réduit ce qu'une telle montée peut encore casser à une liste très courte — et que nous y avons trouvé précisément l'élément que rien, dans notre chaîne, ne surveillait.

## Ce que la conteneurisation a réellement découplé

L'application est immunisée contre une montée de version, et il vaut la peine d'être précis sur le pourquoi : elle n'utilise rien de l'hôte. Son PHP, ses extensions, ses bibliothèques système, son magasin de certificats voyagent dans l'image. On peut remplacer intégralement le `ca-certificates` de la machine : nos appels sortants vers VIES, le prestataire de paiement et le stockage objet n'en savent rien, parce qu'ils ne lisent jamais ce magasin.

C'est pour ça que les équipes en sont venues à traiter une montée d'OS sur un hôte de conteneurs comme une routine. C'est presque vrai, et c'est ce « presque » qui coûte.

## Les quatre points de couplage qui restent

Une fois qu'on a mis en image tout ce qui pouvait l'être, ce qui appartient encore à l'hôte tient en une liste courte — et c'est la même sur n'importe quel serveur conteneurisé :

1. **Le noyau.** Les conteneurs le partagent. Un saut majeur change le sol sous une base de données bien davantage que sous un processus web.
2. **Le démon Docker.** Il n'est pas dans votre image : c'est un paquet de l'hôte, installé depuis un dépôt tiers.
3. **Les sources apt de ce démon.** Ce qui décide si le point précédent recevra encore un correctif de sécurité un jour.
4. **Le contrat de redémarrage.** Quels conteneurs reviennent seuls après un boot, et lesquels, délibérément, non — l'instance en sommeil, par exemple, doit rester à terre, sinon deux versions de l'application se disputeraient la même base.

Rien d'autre ne compte vraiment. Cette liste est assez courte pour être vérifiée à la main, avant et après — ce qui rend impardonnable de ne pas la vérifier.

## Le seul dégât durable est tombé sur le point trois

Une montée de version désactive ou supprime les sources apt tierces. Ce n'est pas un défaut : ces sources sont compilées pour la version qu'on quitte, et les garder actives pendant le saut est la meilleure façon de casser le système. L'outil a raison de le faire, et il le dit.

Ce qu'il ne fait pas, c'est vous le rappeler ensuite. Notre source Docker avait disparu. Rien n'était cassé : le démon tournait, les conteneurs avec, le site servait. Mais le paquet installé était compilé pour la distribution précédente, et plus aucun dépôt n'était en mesure de le remplacer. **Le mode de défaillance n'est pas un service qui s'arrête ; c'est un gestionnaire de paquets qui devient à la fois autoritaire et vide.** Il annonce que tout est à jour, et il dit vrai à propos d'un univers qu'il ne voit plus.

Rétablir la source tient en quatre lignes, sans redémarrage. Ça a révélé sur-le-champ sept versions mineures de dérive accumulées en silence. Rien n'aurait jamais levé la main : ni le démon, qui fonctionne ; ni la supervision que nous n'avons pas ; ni `apt`, qui n'avait plus rien à quoi se comparer.

## L'angle mort : les fichiers compose

Vient ensuite le constat structurel, celui qui mérite d'être emporté.

Notre service de base de données n'avait pas de politique de redémarrage. Après un boot, tous les autres conteneurs seraient revenus, et pas Postgres. Le défaut est trivial : une ligne manquante. Sa durée de vie ne l'est pas : il était là depuis des mois, et il ne pouvait se manifester qu'au redémarrage de l'hôte — lequel n'était pas survenu de tout ce temps.

La bonne question n'est pas comment il a été écrit. C'est pourquoi rien ne l'a attrapé. Et la réponse se généralise bien au-delà de notre installation : **les fichiers compose sont la seule configuration de production que personne ne possède.** Ils ne sont pas cuits dans l'image, donc la construction ne les voit jamais. Aucun test ne les exerce, parce que les tests tournent contre l'application, pas contre la topologie de l'hôte. Et notre job de déploiement ne les copie même pas : il ouvre une session SSH et lance un script. Ils sont édités dans le dépôt, appliqués à la main, et validés par rien.

Dans une chaîne par ailleurs entièrement automatisée — tests, analyse statique, construction d'image, déploiement sans coupure — c'est là qu'un défaut peut dormir indéfiniment. Pas dans le code que la chaîne relit vingt fois par jour, mais dans la poignée de lignes de YAML qu'elle n'ouvre jamais.

## Ce que le noyau aurait pu casser, et ce que nous n'avons pas vérifié

Un saut majeur de noyau sous un Postgres conteneurisé mérite mieux que « ça a redémarré ». Trois questions valent d'être posées, et nous ne pouvons en trancher que deux :

- *Le répertoire de données.* Il vit dans un volume nommé, sur le même système de fichiers, avec le même pilote de stockage. Rien n'a bougé — et c'est la raison pour laquelle la montée était survivable, pas la chance.
- *Les profils de confinement du démon.* Les valeurs par défaut seccomp et AppArmor arrivent avec le paquet Docker, pas avec la distribution : c'est pourquoi les conteneurs ont retrouvé le même environnement de l'autre côté.
- *La sémantique de durabilité.* Savoir si un nouveau noyau change quoi que ce soit pour Postgres avec nos options de montage est une question à laquelle nous n'avons pas répondu. Ça a tenu, ce qui ne prouve rien. Nous l'écrivons plutôt que de revendiquer une vérification que nous n'avons pas faite.

## La mesure existait déjà

Reste l'obligation posée en introduction : connaître le coût réel de la coupure qu'on a choisi d'accepter. Nous avons annoncé une durée en lisant les journaux des conteneurs : l'écart entre la dernière erreur d'un processus et le démarrage du suivant. Ce nombre décrit l'hôte, pas les visiteurs. Il exclut l'arrêt qui précède et la montée en charge qui suit, et il peut se tromper d'un facteur trois.

Pendant ce temps, tout notre trafic passe par un CDN qui avait déjà enregistré, requête par requête, exactement ce que les gens ont reçu sur cette fenêtre. **La mesure qu'on croyait ne pas avoir avait été prise pour nous, par un équipement qu'on payait et qu'on n'avait jamais interrogé.**

Le réflexe à corriger n'est pas « ajouter de l'instrumentation ». C'est inventorier ce qui mesure déjà avant d'ajouter quoi que ce soit : le CDN, les journaux du proxy lui-même, la console du fournisseur. Nos maladresses de procédure cette nuit-là — un nom de conteneur deviné, des variables de shell qui ne survivent pas à une reconnexion SSH, un grep assez large pour remonter 41 lignes pour 2 erreurs — appartiennent toutes à la même famille et valent exactement une phrase : un runbook résout ce dont il a besoin, il ne le fige jamais. Savoir quelle instance sert le trafic en est le cas d'école : ça change à chaque déploiement.

## Pourquoi on publie tout ça — et la seule chose qu'on garde

Un REX n'a de valeur que s'il est précis, celui-ci porte donc les commandes, les modes de défaillance et les trous. Ce qui soulève une question légitime : publier tout ça, n'est-ce pas offrir une carte à un attaquant ?

Notre règle tient en une phrase. **Le problème n'est jamais de nommer une version. C'est de nommer une version sur laquelle on est encore vulnérable.**

« On était en version X, ça nous a coûté ça, c'est corrigé » est une pratique de post-mortem ordinaire. Le même texte publié avant le correctif est une faiblesse encore vraie avec la cible attachée — un REX est signé, il nomme une entreprise et un domaine. Donc : corriger d'abord, raconter ensuite, et généraliser ce qui n'apprend rien. L'*écart* — sept versions de dérive silencieuse — c'est la leçon ; la chaîne de version exacte de notre serveur, non. Ce qu'on ne publie jamais, c'est l'autre catégorie, celle qui ne s'apprend pas mais se recopie : noms de machines, chemins, la chaîne de clés qui déchiffre une sauvegarde. La frontière n'est pas « sensible ou anodin », elle est : **est-ce que ça enseigne, ou est-ce que ça ouvre ?**

## Ce que ça a donné

- **Quatre points de couplage** isolés entre une application conteneurisée et son hôte : noyau, démon, sources apt du démon, contrat de redémarrage. Assez peu nombreux pour être vérifiés à la main, avant et après.
- **Une voie de mise à jour gelée, rétablie** : le démon avait dérivé de sept versions mineures sans que rien puisse le signaler.
- **Un angle mort structurel, nommé** : les fichiers compose, seule configuration de production qu'aucune construction, aucun test et aucun déploiement ne lisent jamais.
- **Une mesure récupérée plutôt que construite** : le CDN avait déjà enregistré ce que les visiteurs ont vu, gratuitement.

## Bonnes pratiques

- Écrire ses points de couplage une fois pour toutes. Sur un hôte de conteneurs il y en a quatre, ce sont toujours les mêmes, et les vérifier prend dix minutes.
- Après une montée de version, re-vérifier d'abord les sources tierces : un gestionnaire de paquets qui n'a plus rien à quoi se comparer annonce que tout est à jour, et il ne ment pas.
- Chercher ce que l'automatisation ne possède pas. Dans une chaîne entièrement automatisée, le défaut qui survit est dans le fichier que la chaîne n'ouvre jamais.
- Inventorier ce qui mesure déjà — CDN, proxy, console du fournisseur — avant d'ajouter de l'instrumentation. Le chiffre qui vous manque a souvent déjà été enregistré.
- Un runbook résout, il ne fige pas : quelle instance sert le trafic, son nom de conteneur, l'identifiant du service — tout ça se demande au moment de l'appel.

## Points de vigilance

- La panne dangereuse n'est pas le service qui s'arrête, c'est celui qui continue de fonctionner en perdant sa capacité à être mis à jour. Il n'émet rien.
- « Ça a redémarré » ne prouve rien sur la durabilité. Écrire les questions auxquelles on n'a pas répondu plutôt que revendiquer une vérification qu'on n'a pas faite.
- Un défaut qui ne peut se manifester qu'au redémarrage de l'hôte a la durée de vie de l'intervalle entre deux redémarrages. Sur un serveur qui se tient bien, c'est des mois.
- Un journal interne dit quand un processus est mort, jamais quand les visiteurs ont cessé d'être servis. Seule une mesure prise devant la pile le dit.
- **Corriger avant de raconter : un REX qui décrit une faiblesse encore ouverte, signé de son nom, n'est pas de la transparence — c'est une notice d'utilisation.**
