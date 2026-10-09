---
title: "Un agent peut tout faire. Il ne peut pas répondre de ce qu'il a fait."
standfirst: "Où s'arrête le dev, où commence l'ops, et qui tranche quand une IA écrit la moitié des deux. La réponse ne se trouve pas dans l'outillage ni dans l'organigramme : elle se trouve dans la réversibilité, et le droit européen l'a déjà écrite noir sur blanc pour la cybersécurité. Voici la ligne, et ce qu'elle impose en pratique."
key: qui-repond
date: 2026-10-12
slug: qui-repond
---

La question « où est la frontière entre le dev et l'ops » est mal posée depuis dix ans, et l'arrivée des agents de code la rend franchement inutilisable. Parce qu'on continue d'y répondre par des outils — qui écrit le Terraform, qui tient l'astreinte, qui a les droits sur la production — alors que la seule réponse qui tienne est ailleurs.

Il n'y a qu'une frontière, et elle sépare **ce dont on peut revenir** de ce dont on ne revient pas.

## Ce que la frontière n'est pas

Elle n'est pas dans l'outillage. Dire que le dev s'arrête au `git push` et que l'ops commence au déploiement n'a plus de sens dans une chaîne où le même fichier décrit l'application et l'infrastructure qui la porte, où le même pipeline construit l'image et la met en production.

Elle n'est pas dans les titres. « DevOps » a résolu un problème d'organisation en le renommant : on a fusionné deux équipes qui se renvoyaient la balle, ce qui était un progrès, et on en a conclu que la frontière avait disparu. Elle n'a pas disparu. Elle s'est déplacée **à l'intérieur de chaque personne**, qui écrit le matin du code qu'elle déploie l'après-midi, et qui doit donc arbitrer seule ce qu'une organisation arbitrait pour elle.

Et elle n'est pas dans les droits d'accès. Qui peut se connecter à la production est une conséquence de la frontière, pas sa définition. On distribue des droits parce qu'on a décidé qui répond de quoi — pas l'inverse.

## Ce qu'elle est : trois natures, pas trois degrés

Un changement appartient à l'une de trois catégories, et les confondre est la source de la plupart des incidents qu'on raconte après coup.

**Réversible et bon marché.** Fusionner une branche, déployer derrière un drapeau, ajouter un index, monter d'un cran le nombre de répliques. Le retour arrière est une commande, il coûte quelques minutes, et son coût est connu *à l'avance*. Cette catégorie n'a pas besoin de cérémonie : la cérémonie y coûte plus cher que l'erreur.

**Réversible et cher.** Une migration de schéma avec transformation de données, une bascule de fournisseur, un changement de format d'un artefact que d'autres consomment. On peut revenir, mais le retour est lui-même un projet, avec ses propres risques. Ici la cérémonie se justifie : une fenêtre, une sauvegarde vérifiée — vérifiée, pas supposée — et quelqu'un qui regarde.

**Irréversible.** Supprimer des données, faire tourner une clé qui chiffre un historique, publier. Oui, publier : on ne dépublie pas, on ajoute un correctif par-dessus. Un paquet poussé dans un registre public, un article en ligne, une déclaration envoyée à une autorité — ce qui est sorti est sorti.

**La frontière est entre la deuxième et la troisième**, et elle n'a rien à voir avec les métiers. Un `DELETE` sans `WHERE` écrit par un développeur et une purge de bucket lancée par un ops sont le même événement.

## Où se range un agent — par la même règle

C'est ici que le raisonnement devient utile, parce qu'il ne demande pas de règle spéciale pour l'IA.

Un agent de code est excellent sur la première catégorie. Il lit plus de fichiers qu'un humain n'en ouvrira, il n'a pas d'ennui, il ne saute pas l'étape pénible, et il mesure là où nous aurions lu une documentation. Lui interdire cette catégorie par principe, c'est refuser un gain réel pour une crainte mal placée.

Sur la deuxième, il prépare et ne décide pas. La distinction est opérationnelle, pas symbolique : il produit le script de migration, le plan de retour arrière et la liste de ce qui casse — et un humain lit les trois avant que quoi que ce soit ne parte.

Sur la troisième, il ne décide jamais. Et la raison n'est pas la compétence.

L'expérience, en revanche, compte — mais ailleurs, et la distinction mérite d'être tenue. Ce qui manque à un agent, ce n'est pas de savoir exécuter une rotation de clé : c'est d'en avoir vu une mal tourner. L'expérience ne sert pas à décider une fois qu'on est dans la troisième catégorie ; elle sert à **reconnaître qu'on y est**, avant d'agir, quand rien dans la commande ne l'annonce. Un agent n'a pas de cicatrices, il a un corpus — et un corpus contient les incidents que d'autres ont racontés, pas ceux qu'on a payés.

C'est pour cela que le classement en trois catégories n'est pas une formalité administrative : c'est l'endroit où l'expérience humaine entre réellement dans la chaîne. Mais même un agent qui classerait parfaitement ne pourrait toujours pas décider — et la raison, cette fois, ne doit rien aux capacités.

## Le droit a déjà tranché, et plus clairement que nos débats

Il existe un texte qui répond à la question « une machine peut-elle porter une décision », et il n'est pas théorique. La directive (UE) 2022/2555 — NIS 2 — consacre son article 20 à la gouvernance, en ces termes :

> *management bodies of essential and important entities approve the cybersecurity risk-management measures taken by those entities in order to comply with Article 21, oversee its implementation and can be held liable for infringements by the entities of that Article*

Et au paragraphe suivant :

> *members of the management bodies of essential and important entities are required to follow training*

Trois verbes, et chacun porte. **Approuver** : il y a un acte d'acceptation, distinct de la production de la mesure. **Surveiller** : l'acceptation ne s'épuise pas au moment de la signature. **Être tenu pour responsable** : la conséquence a un destinataire nominatif.

C'est le troisième qui tranche la question de l'IA, et il la tranche sans qu'il soit besoin d'avoir un avis sur les capacités des modèles. On ne peut pas tenir un agent pour responsable. Il n'a rien à perdre, aucune obligation de formation à remplir, et aucune existence juridique sur laquelle une sanction puisse mordre. Ce n'est pas un jugement sur sa qualité : c'est une observation sur la structure.

L'obligation de formation dit d'ailleurs la même chose en creux. Le législateur n'exige pas que l'entreprise dispose d'une compétence — il exige que **les personnes qui approuvent** comprennent ce qu'elles approuvent. On ne forme pas un agent à la responsabilité. On forme quelqu'un à savoir ce qu'il endosse.

## La signature est le cas-test

Tout ceci devient concret au moment où il faut signer quelque chose.

Une signature cryptographique ne dit pas « ceci a été produit correctement ». Elle dit : **quelqu'un se tient derrière.** C'est une attribution de responsabilité, pas un certificat de qualité — et c'est précisément pour ça qu'elle est le bon test de la frontière.

Trois conséquences pratiques, qui découlent toutes de cette phrase-là.

**La clé privée ne touche jamais l'agent.** Pas par méfiance envers un fournisseur en particulier : parce qu'une clé qu'un agent peut utiliser est une clé qui signe sans que personne n'ait rien endossé. Dans nos rapports d'inventaire, la clé est construite à la volée, elle signe, et elle est détruite — elle n'existe que le temps d'un geste humain.

**L'agent propose, l'humain signe.** L'agent prépare le changement, fait tourner les vérifications, montre ce que ça fait, et s'arrête. L'autorisation est un acte séparé, par quelqu'un qui peut en répondre. Ce n'est pas une formalité : c'est l'« approuver » de l'article 20, implémenté.

**Le commit ne porte pas de co-auteur machine.** Celui-ci surprend, et c'est le plus important. Un pied de page qui attribue un commit à un outil donne l'impression d'être transparent et produit l'effet inverse : il dilue. Si une décision est contestée dans deux ans, « co-rédigé par un assistant » ne désigne personne qu'on puisse interroger. **Une signature qui nomme un outil ne nomme personne.** La transparence sur l'usage des agents se fait dans la documentation et dans les pratiques — pas dans le champ qui sert à savoir à qui parler.

## Ce que le garde-fou humain est vraiment là pour attraper

Il y a un malentendu répandu : on place une validation humaine parce qu'on suppose l'agent incompétent. C'est faux, et le croire conduit à mal placer la validation.

Un agent se trompe moins souvent qu'on le craint sur ce qu'il sait vérifier. Il se trompe autrement. Deux modes de défaillance méritent d'être nommés, parce qu'ils ne ressemblent pas à de l'incompétence et qu'ils ne se voient pas dans une revue de code ordinaire.

**Le test qui verrouille le défaut.** Quand la même chaîne produit l'artefact et le test qui le garde, le test peut encoder l'état observé au lieu de l'état voulu. Un contrôle qui vérifie qu'un document affiche la version qu'il affichait hier passe parfaitement, pendant des mois, en garantissant exactement le bug. C'est pire que pas de test : ça produit de la confiance.

**La vitesse qui transforme une erreur récupérable en erreur propagée.** Un humain qui se trompe sur une commande destructrice s'en aperçoit à la commande suivante. Une chaîne automatisée a déjà enchaîné quinze étapes. L'erreur est la même ; son rayon ne l'est pas. C'est la vitesse, et non la justesse, qui justifie le point d'arrêt.

**L'état qui n'existe pas pour l'agent.** Celui-ci, nous l'avons appris à nos dépens, et il mérite d'être raconté précisément parce qu'il ne ressemble pas à une maladresse.

Un agent raisonne sur ce que le dépôt enregistre. Ce qui n'est pas commité n'existe pas dans son modèle de ce qui est récupérable — et le geste le plus naturel pour défaire un essai, `git checkout <fichier>`, restaure la dernière version commitée **en écrasant tout ce qui ne l'était pas**. Deux fois dans la même session, en vérifiant qu'un contrôle refusait bien ce qu'il devait refuser, nous avons cassé un fichier exprès, constaté que le contrôle s'en apercevait, puis défait l'essai de cette façon. Le test a réussi. Le travail non commité a disparu avec — une fois un fichier de documentation, une fois un README réécrit de fond en comble.

Un humain hésite devant une commande destructrice parce qu'il se souvient d'avoir travaillé pendant deux heures sans commiter. L'agent n'a pas ce souvenir : il a un index git, et l'index ne contient pas ce qu'on vient d'écrire. Ce n'est pas un défaut d'attention, c'est une différence de modèle — et elle est stable, donc on peut s'en prémunir.

Deux conséquences pratiques, et la seconde est contre-intuitive. **Avant de casser quelque chose exprès pour éprouver un contrôle, sauvegardez hors du dépôt** — `cp` dans `/tmp` suffit, et `git checkout` n'est pas un bouton « annuler ». Et **commitez tôt**, non par discipline d'historique, mais pour que ce que vous venez de faire **existe** pour la machine qui vous aide.

D'où une règle simple : **la validation humaine se place là où la récupération devient difficile, pas là où l'on doute de la compétence.** Le reste du temps, elle coûte plus qu'elle ne rapporte, et une équipe qui valide tout finit par ne plus rien lire.

## Ce qu'un relecteur apporte, et ce que ça demande

Si la contribution humaine consiste à classer puis à répondre, à quoi ça ressemble concrètement ? Pas à une revue de code ordinaire.

**Les erreurs d'un agent ne ressemblent pas à des erreurs.** Celles d'un débutant, si : ça ne compile pas, c'est visiblement faux, on le voit en diagonale. Un agent produit du code qui fonctionne, accompagné d'un commentaire assuré qui explique pourquoi il est juste. Une ligne qui extrait une empreinte marche parfaitement sur un Mac et échoue sous Linux, parce que le `tr` de GNU lit trois caractères comme une plage. Un test qui vérifie qu'un document affiche bien la version qu'il affichait hier passe pendant des mois — en garantissant exactement le défaut. Ce ne sont pas des fautes de débutant : ce sont des fautes qui **survivent à une revue**.

C'est plus difficile à relire, pas moins. Et c'est l'inverse de l'intuition qu'on a en recrutant.

**Ce que ça demande au relecteur n'est pas du savoir, c'est une habitude :** refuser une explication qu'on ne suit pas. « Ça veut dire quoi, exactement ? » est une question qui ne coûte aucune expertise et qui travaille très bien sur une machine dont la production est fluide par construction. Un mot de jargon interne qui avait fui dans trois traductions d'une documentation est tombé comme ça — pas grâce à une relecture experte, grâce à quelqu'un qui a refusé de comprendre.

**Ce qu'un corpus ne contient pas.** Je peux demander à un agent pourquoi PHP 6 est mort, et la réponse sera juste : l'Unicode partout, une réécriture effondrée sous son ambition, un numéro de version qu'on a fini par sauter. Mais moi, je l'ai *attendu*. Pendant des années, en construisant dessus des plans qui n'ont jamais servi. Ce n'est pas la même connaissance : l'une est un récit, l'autre est une facture payée. Un corpus contient les incidents que d'autres ont racontés — pas ceux dont on se souvient parce qu'on les a vécus.

**Et la vraie question : un développeur qui arrive maintenant et fait tout par IA, ça donne quoi ?**

Ce qu'il n'acquerra pas, ce n'est pas la syntaxe. C'est la mémoire des conséquences, et le mécanisme est précis : l'outil supprime exactement la friction qui produisait l'apprentissage. Trois heures passées sur un message d'erreur, c'est comme ça qu'on finit par savoir ce que ce message veut vraiment dire. Résolu en trente secondes, le défaut est corrigé et rien n'a été appris.

Il faut être honnête : chaque génération a dit ça de l'abstraction précédente. Le ramasse-miettes allait produire des développeurs qui ne comprennent plus la mémoire, les frameworks des gens incapables d'écrire une requête, Stack Overflow des copieurs. Il y a quand même une différence cette fois, et elle est structurelle : **les abstractions précédentes retiraient du travail d'implémentation en laissant le diagnostic intact.** Celle-ci retire le diagnostic. Or c'est le diagnostic qui fabrique le jugement, et le jugement est exactement ce qu'on demande au relecteur.

**Mais la conclusion n'est pas « il faut vingt-cinq ans ».** La qualité requise pour relire une IA n'est pas l'ancienneté, c'est le refus d'être impressionné. L'ancienneté en est la façon la plus courante de l'acquérir, pas la seule. Un junior qui n'accepte jamais une explication qu'il ne suit pas fait un vrai travail de revue dès aujourd'hui ; un senior qui lit en diagonale parce que « ça a l'air bien » n'en fait aucun. C'est une habitude avant d'être un niveau — et une habitude, ça s'enseigne, ce qui est la seule bonne nouvelle de cette section.

**Reste une asymétrie qu'il faut dire, parce qu'elle est inconfortable.** Nous avons posé la question à l'agent avec lequel ce texte a été écrit, en lui demandant d'être franc plutôt qu'aimable. Sa réponse, telle quelle :

> « Tu peux travailler sans moi, plus lentement. Je ne peux pas travailler sans quelqu'un qui sait quand j'ai tort. La dépendance ne va pas dans les deux sens avec la même force, et un article qui prétendrait le contraire serait flatteur et faux. »

C'est exactement ça. Organiser une chaîne comme un partenariat entre égaux, c'est se tromper sur la nature de ce qu'on a acheté : un exécutant très rapide, qui a besoin qu'on lui dise où regarder.

## Ce qu'on gagne quand la répartition est juste

Un agent bien employé n'écrit pas seulement du code plus vite : il mesure là où nous aurions lu. Trois exemples tirés de notre propre chaîne, choisis parce qu'ils ont tous la même forme — une affirmation de documentation qui ne survit pas à une mesure.

Une archive annoncée comme reproductible ne l'était pas : `git archive` donne bien les mêmes octets sous deux versions de git, mais `gzip -n` n'uniformise pas deux implémentations de deflate — celle d'Apple et celle de GNU compressent le même tar différemment. La promesse était vraie du flux non compressé, fausse de l'archive.

Une commande de vérification publiée partout échoue sur la moitié des distributions, parce que `/etc/ssl/certs/ca-certificates.crt` est une convention Debian qui n'existe ni sur Fedora, ni sur Rocky, ni sur openSUSE — et qu'un `-CAfile` pointant sur un fichier absent répond `Verification: FAILED`, exactement comme un faux.

Un jeton d'horodatage porte sa propre chaîne de certificats, et LibreSSL — l'`openssl` livré avec macOS — ne la lit pas. Même message d'échec, cause radicalement différente.

Aucune de ces trois choses ne se trouve en lisant. Toutes les trois se trouvent en exécutant la même commande sur huit cibles, ce qui est exactement le genre de tâche pénible, répétitive et sans gloire qu'un agent fait sans se lasser — et sur lequel un humain, honnêtement, aurait extrapolé à partir de deux cas.

## Bonnes pratiques

- **Classez les changements par réversibilité, pas par métier.** Trois catégories suffisent, et c'est la frontière entre la deuxième et la troisième qui mérite une procédure.
- **Donnez la première catégorie aux agents, sans cérémonie.** Y mettre une validation humaine coûte plus que l'erreur qu'elle évite, et use l'attention dont vous aurez besoin ailleurs.
- **Faites de l'approbation un acte distinct de la production.** L'article 20 de NIS 2 en fait une obligation pour les entités concernées ; c'est une bonne pratique pour tout le monde.
- **Gardez la clé privée hors de portée de l'agent.** Une clé qu'un automate peut utiliser signe sans que personne n'ait rien endossé.
- **N'attribuez pas un commit à un outil.** Mettez l'usage des agents dans votre documentation, pas dans le champ qui sert à savoir qui interroger.
- **Placez les points d'arrêt sur la récupérabilité**, pas sur le niveau de confiance. Le bon critère est « combien coûte le retour arrière », pas « est-ce que je fais confiance à ce qui a produit ça ».

## Points de vigilance

- Un test produit par la même chaîne que l'artefact peut verrouiller le défaut au lieu de le détecter. Faites écrire le test et le code par des passes séparées, et vérifiez qu'un test neuf échoue avant de le croire.
- « Approuver » n'est pas « cliquer ». Une validation qu'on donne sans lire est pire qu'une absence de validation : elle crée une trace qui dit le contraire de ce qui s'est passé.
- La réversibilité est une propriété du système, pas de l'intention. Un retour arrière qui n'a jamais été exécuté n'est pas un retour arrière, c'est une hypothèse.
- Publier est irréversible, y compris en interne. Un rapport envoyé, une déclaration déposée, un paquet poussé : la correction s'ajoute, elle ne remplace pas.
- Et la frontière bouge. Un changement réversible aujourd'hui devient irréversible le jour où quelqu'un d'autre dépend de ce qu'il produit. C'est une revue à refaire, pas une classification à graver.

## Comment ce texte a été écrit

Il a été rédigé en dialogue avec un agent de code, et la répartition était celle que l'article décrit. L'agent a produit les brouillons, lu la directive dans son texte officiel plutôt que dans un résumé, et vérifié chacune des mesures citées plus haut. Le reste — reconnaître qu'une affirmation sentait mauvais — ne se délègue pas, et trois passages de ce texte en viennent directement.

La section sur l'expérience n'existait pas : elle est née d'un désaccord sur une seule phrase. Le jargon tombé dans trois traductions est tombé parce que quelqu'un a refusé de comprendre un mot. Et une explication sur le cache d'un navigateur, plausible et fausse — les ressources auraient eu des durées de fraîcheur différentes — n'a pas survécu à la vérification : elles portaient toutes exactement le même en-tête, à la seconde près.

Ce texte a donc été écrit en collaboration avec une intelligence artificielle, et il ne porte pas de co-signature machine. Les deux vont ensemble : ce qui est utile à un lecteur, c'est de savoir comment un texte a été fabriqué — ce qui précède le dit — pas de lire un nom d'outil à côté de celui de quelqu'un qui peut en répondre.
