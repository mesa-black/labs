---
title: "« On dit ce qu'on fait » : trois fois en deux jours, ce blog a dit faux."
standfirst: "Une signature qui ne couvrait pas la page qu'elle scellait. Trois empreintes là où le document en promettait une. Un article cité comme publié et jamais paru. Chacune trouvée en faisant ce que la phrase décrivait, et ce texte raconte comment — parce que la transparence n'est pas une intention, c'est un dispositif."
key: on-dit-ce-qu-on-fait
date: 2026-10-06
slug: on-dit-ce-qu-on-fait
---

« On dit ce qu'on fait et on fait ce qu'on dit » est une phrase qu'on lit sur beaucoup de sites, et qui ne coûte rien à écrire. Elle ne devient intéressante qu'à l'endroit où les deux moitiés s'écartent — et elles s'écartent toujours, parce qu'une affirmation est écrite une fois et que le code continue de bouger.

Alors la question utile n'est pas « sommes-nous transparents ». C'est : **par quel dispositif une phrase fausse se fait-elle attraper, et en combien de temps ?**

Voici les trois dernières, toutes datées des 5 et 6 octobre, toutes imprimées par nos propres outils.

## 1. Une signature qui ne couvre pas la page qu'elle scelle, et ne la couvrira jamais

Ce site publie désormais son propre inventaire cryptographique, produit par [Sablier](https://github.com/mesa-black/sablier) et signé. Le lien est dans l'en-tête de chaque page, le fichier `.sig` est à côté, et quatre commandes suffisent à le vérifier sans nous.

En ajoutant ce rapport, nous y avons écrit une phrase : *« le rapport n'a pas changé depuis sa signature »*.

Une heure plus tard, la vérification de bout en bout — télécharger le rapport depuis le site, sa signature depuis le site, la déclaration depuis GitHub, et vérifier — a donné ceci :

```
signature valide, Ed25519 et post-quantique
  + ML-DSA-65 : vérifiée
```

Puis nous avons **modifié un mot dans le rapport** et relancé la même commande. Même réponse : valide.

La phrase était fausse, et c'était le pire genre de faux : elle invitait un lecteur à faire confiance à des octets que la signature ne touche pas. La cause est structurelle et aucun mécanisme ne la répare — **un rapport affiche sa propre signature, donc il ne peut pas la contenir.** Le HTML est écrit après que le bloc existe ; signer les octets rendus serait circulaire.

Ce qui est signé est l'empreinte des *constats*, ce qui est le bon choix : deux rendus du même inventaire dans deux langues doivent donner la même valeur. Le seul moyen de rattacher une page à cette empreinte est de rejouer l'analyse sur la même source et de comparer — et **un dépôt public est précisément ce qui rend ce recalcul possible**. C'est devenu l'instruction imprimée, avant la phrase qui dit ce que la signature établit.

## 2. Trois empreintes là où le document en promettait une

La correction précédente a ajouté au rapport la phrase qui manquait : *« deux rendus du même inventaire, dans deux langues, donnent la même valeur »*.

Le lendemain, une question simple — *si je lis en espagnol, le lien ne devrait-il pas pointer vers l'audit en espagnol ?* — nous a fait générer le rapport dans les trois langues. Les empreintes sont sorties ainsi :

```
fr  1839cd93…      en  abb8b217…      es  0e5b2727…
```

Trois valeurs, sous un paragraphe qui promettait la même. Deux causes, dont une sérieuse.

La petite : le libellé d'un domaine *non déclaré* est traduit — « non déclaré », « undeclared », « no declarado » — et il entrait dans le calcul.

La grosse : la sonde réseau fabriquait ses constats avec des phrases traduites, et l'identifiant d'un constat est haché depuis ce texte. Donc le même serveur produisait un identifiant différent par langue.

Pourquoi c'est pire qu'un désaccord d'empreinte : cet identifiant sert à accepter un constat — à écrire, dans un fichier versionné, « nous avons vu celui-là, voici pourquoi nous le laissons ». Un identifiant qui change avec la langue signifie qu'**une décision enregistrée en français cesse silencieusement de s'appliquer à une analyse lancée en anglais**. Rien ne l'aurait signalé : le constat réapparaît simplement, sans sa décision.

Partout ailleurs dans cet outil, la preuve d'un constat est une ligne de code source — intraduisible par nature. Côté sonde, c'est désormais le fait que la poignée de main a retourné, et la phrase qui l'explique vit dans un champ séparé, comme chez tous les autres détecteurs.

## 3. Un article cité comme publié, et jamais paru

Le texte programmé pour le 8 octobre — pas encore paru quand ces lignes sont écrites — s'ouvrait sur : *« Le 2 octobre, un texte publié ici se terminait sur une phrase inconfortable… »*

Ce texte n'a jamais paru. Il était écrit, programmé pour le 2 octobre, et retiré la veille avec un autre. Vérification : absent du sitemap, absent des quatre versions déposées sur le serveur, et son URL répond 404.

Un lecteur qui aurait suivi la référence n'aurait rien trouvé — la pire erreur possible dans un article dont le sujet est de vérifier ce qu'on affirme. La phrase dit maintenant ce qui s'est passé : écrit, programmé, retiré la veille, et sa dernière ligne a tenu. **Le retrait fait partie de l'histoire plutôt qu'il ne la gêne.**

## Ce que les trois ont en commun

Aucune n'a été trouvée en relisant. Les trois ont été trouvées **en faisant ce que la phrase décrivait** : altérer un rapport publié pour voir si la signature s'en apercevait, générer le document dans les trois langues, suivre sa propre référence.

C'est la seule méthode qui marche, et elle a un nom moins noble que « transparence » : **vérifier plutôt que supposer**. La même erreur s'est d'ailleurs produite deux fois dans l'outillage pendant ces deux jours, sous une forme encore plus bête — une vérification qui interrogeait un code de statut au lieu d'un contenu. Le serveur de développement de PHP répond `200` et la page d'accueil pour une URL inexistante : notre contrôle affichait donc « en ligne » pour un article qui avait été reconstruit hors d'existence. **Un code de statut n'est pas une vérification.**

## Le dispositif, maintenant

Une phrase fausse ne se corrige pas en promettant d'être plus attentif. Elle se corrige en rendant son démenti automatique.

- **Un budget de mots.** Le questionnaire d'entretien avait atteint 986 mots de texte à lire pour répondre à deux questions par sujet. Il en fait 235, et un test échoue au-delà de 260. Un second échoue si un mot de métier revient sur le chemin du lecteur. Parce que la prose arrive un paragraphe justifié à la fois, et que rien d'autre ne l'attrape.
- **Des tests qui portent sur l'affirmation**, pas sur le code : trois langues donnent une empreinte ; trois langues donnent un identifiant ; aucun chemin de fichier n'apparaît devant la personne interrogée ; un rapport non signé n'affirme rien de ce qu'une signature prouverait.
- **Des artefacts rejouables.** Le rapport de ce site, sa signature et la déclaration qui désigne la clé sont publics. La commande de vérification est imprimée dans le document, et ce qu'elle établit — comme ce qu'elle n'établit pas — juste en dessous.
- **Des retraits assumés.** Deux articles écrits, programmés, puis retirés la veille. Le mécanisme de parution a été corrigé dans la foulée : une version datée que plus aucun article ne réclame est supprimée du serveur, sinon elle serait servie le jour venu avec le texte retiré dedans.

## Ce qu'on a décidé de ne pas mesurer

La transparence sert aussi à dire ce qu'on ne fait pas, et pourquoi.

Ce site **ne compte pas ses visites**. Il n'y a aucun journal d'accès : vérifié, zéro ligne de requête enregistrée. Ajouter un compteur honnête est possible — le journal de Caddy, l'adresse IP supprimée à la source, aucune donnée personnelle conservée — mais il compterait des *requêtes*, pas des personnes, et les robots gonfleraient le chiffre. Un compteur qui annonce des « visiteurs » en comptant des requêtes est exactement la fausse assurance que tout le reste de ce travail refuse. Alors non.

Il **n'a pas de commentaires** non plus. Il faudrait un exécutable sur le serveur, une base, de la modération, de l'anti-spam et le stockage du nom des autres — cinq choses dont ce site est défini par l'absence. À la place, une adresse en bas de chaque article. Elle coûte une ligne et filtre toute seule : qui prend la peine d'écrire a quelque chose à dire.

## Ce que ça a donné

- **Trois affirmations fausses corrigées en deux jours**, chacune avec le test qui échoue si elle revient.
- **Un défaut sérieux trouvé par ricochet** : des décisions d'audit qui se détachaient silencieusement de leur constat selon la langue d'exécution.
- **Deux vérifications réécrites** parce qu'elles mesuraient un code de statut plutôt qu'un contenu.
- **Zéro ligne de communication ajoutée.** Il n'y a pas de page « nos engagements » sur ce site, et il n'y en aura pas.

## Bonnes pratiques

- Faire ce que la phrase décrit, en vrai, une fois. Altérer le fichier signé, générer dans les trois langues, suivre son propre lien : c'est là que les affirmations tombent, pas en relecture.
- Écrire d'abord ce qu'une garantie **ne** couvre **pas**. C'est la moitié qu'on oublie, et c'est celle qui fabrique la confiance mal placée.
- Transformer chaque phrase tenue en test qui échoue quand elle cesse de l'être. Une affirmation sans démenti automatique est une affirmation qui sera fausse un jour sans que personne le sache.
- Vérifier un contenu, jamais un code de statut.
- Dire ce qu'on a retiré. Un retrait expliqué coûte un paragraphe ; un trou dans un historique public coûte la confiance qu'on essayait de construire.

## Points de vigilance

- **Un dispositif n'est pas une vertu.** Rien de ce qui précède ne garantit la prochaine phrase. Ça garantit seulement qu'une affirmation déjà testée ne se dégradera pas en silence.
- Les trois erreurs de ce texte ont été trouvées en deux jours parce que quelqu'un **utilisait** ces outils ce jour-là. Un outil qu'on n'utilise pas garde ses affirmations fausses indéfiniment, et aucun test ne les écrit à notre place.
- Publier ses erreurs a un coût qu'il faut nommer : ça ressemble à de l'amateurisme pour qui lit vite. On continue quand même, parce que l'alternative — corriger en silence — protège l'auteur et laisse le lecteur avec la version fausse.

---

*Correction du 9 octobre 2026.* Le titre de la section 1 était à l'imparfait —
« une signature qui ne **couvrait** pas la page qu'elle scellait » — ce qui
laissait entendre qu'elle la couvre désormais. Le corps dit l'inverse depuis le
premier jour : la cause est structurelle, aucun mécanisme ne la répare, et ce
qui est signé est l'empreinte des constats, ce qui est le bon choix. Seul le
titre entretenait l'ambiguïté ; il est au présent maintenant. Rien d'autre n'a
changé, et le rapport en ligne porte toujours la phrase que cette section a fait
écrire : *« Sans ce recalcul, une page modifiée à la main se vérifie quand
même. »*
