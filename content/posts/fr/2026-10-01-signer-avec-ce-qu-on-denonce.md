---
title: "Notre outil dénonce Ed25519. Il signe avec Ed25519."
standfirst: "Pourquoi ce n'est pas une incohérence, ce que ça révèle du post-quantique que presque tout le monde rate, et pourquoi il n'y aura pas de chaîne de blocs."
key: signer-avec-ce-qu-on-denonce
date: 2026-10-01
slug: signer-avec-ce-qu-on-denonce
---

On écrit un outil qui inventorie la cryptographie d'un projet et qui dit, pour chaque usage, combien de temps la protection tiendra. Il s'appelle Sablier, il est [ouvert](https://github.com/mesa-black/sablier), et il classe Ed25519 parmi les algorithmes à migrer : c'est une courbe elliptique, donc l'algorithme de Shor en vient à bout.

Puis vient le moment de signer ses propres rapports. Et là, aucune issue : **PHP ne propose aucune signature post-quantique.** RSA, ECDSA, Ed25519 — les trois schémas disponibles tombent devant le même algorithme de Shor. Le choix n'était donc pas « Ed25519 ou rien », mais « Ed25519 ou tout aussi exposé ». On a pris le plus sain des trois : moderne, compact, sans paramètre à rater.

L'outil signe donc avec exactement ce qu'il pointe du doigt. La tentation est de masquer le problème — signer sans le dire, ou ne pas signer du tout. On a fait l'inverse : le rapport imprime la contradiction, avec l'année de péremption remplie dedans. Parce qu'en la regardant en face, on tombe sur la distinction que la quasi-totalité du discours post-quantique escamote.

## Le besoin, avant la solution

Un rapport de ce genre finit devant quelqu'un : un client, un auditeur, un régulateur. Trois questions se posent alors, et elles sont distinctes.

Le contenu a-t-il été modifié depuis sa production ? Vient-il bien de l'outil et de la personne annoncés ? Existait-il à la date affichée ?

La première appelle une empreinte. La deuxième une signature. La troisième un tiers qui date, ou un registre en ajout seul.

## Pourquoi ce ne sera pas une chaîne de blocs

C'est la première réponse qui vient, et elle résout le seul problème qu'on n'a pas.

Une chaîne de blocs existe pour se passer de tiers de confiance entre des parties qui ne se font pas confiance, au prix d'une dépense de calcul et d'une infrastructure permanente. Monter la sienne, c'est un nœud, donc une personne : exactement aussi crédible que la signature qu'elle prétendrait remplacer, avec une machine à maintenir pour toujours en plus. Utiliser une chaîne publique, c'est envoyer l'empreinte dehors — et notre rapport promet noir sur blanc de ne rien émettre.

Le dosage juste tenait en trois choses déjà disponibles. Une empreinte des constats dans le document. Une signature détachée, avec une clé qu'on contrôle. Et pour une date opposable, un horodateur normalisé, en une requête, le jour où quelqu'un a vraiment besoin d'une date qu'il ne tient pas de nous.

Une précision de conception qui compte : **on ne signe pas le fichier, on signe les constats.** Deux exécutions de la même analyse produisent des octets différents — une date de rendu, une durée d'exécution — en disant rigoureusement la même chose. Le même inventaire rendu en français et en espagnol donne la même empreinte. Signer le fichier aurait produit des alertes à chaque rendu et aurait entraîné, en six mois, l'habitude de les ignorer.

Et la clé publique attendue vit dans la déclaration versionnée du projet. Une signature qui se vérifie avec la clé livrée à côté d'elle ne prouve qu'une chose : quelqu'un possédait une clé. En la mettant sous revue de code, en changer devient un commit qu'on relit.

## La distinction que tout le monde rate

Reste la contradiction. Elle se dissout sur une phrase : **une signature ne se récolte pas.**

Le modèle de menace du post-quantique s'appelle *récolte maintenant, déchiffrement plus tard*. Un adversaire capture aujourd'hui du trafic chiffré et le conserve jusqu'au jour où il pourra l'ouvrir. Pour une donnée confidentielle, la date de compromission est donc le jour du chiffrement, pas celui de l'attaque — c'est ce qui rend l'échéance présente et non future.

Rien de tout cela ne s'applique à une signature. Personne ne capture une signature pour la « déchiffrer » plus tard : il n'y a rien dedans. Le jour où la courbe tombe, un adversaire peut forger de nouvelles signatures — pas antidater celles de 2026 dans un monde qui a déjà vu l'algorithme mourir et qui ne les accepte plus.

La conséquence pratique est nette, et elle dépend entièrement de la durée de vie de ce que la signature doit prouver.

Une signature dont l'utilité se compte en mois — un rapport qu'on présente ce trimestre — est parfaitement servie par Ed25519 aujourd'hui. Une signature qui doit rester vérifiable dans quinze ans ne l'est pas du tout. Et cette seconde catégorie a un nom : les **ancres de confiance à longue durée**. Signature de code, autorité de certification interne, micrologiciel, horodatage. Et, précisément, un rapport de conformité qu'il faudra peut-être produire devant un tribunal en 2041.

C'est le même raisonnement que l'outil applique aux données. La question n'est jamais « cet algorithme est-il post-quantique ». La question est « combien de temps faut-il que ça tienne ».

## Ce qu'on écrit dans le rapport

Alors le rapport le dit, avec l'année remplie dedans :

> Cette signature est en Ed25519 — que ce rapport classe lui-même comme vulnérable au quantique. Une signature ne se récolte pas : elle tient aussi longtemps que la courbe. La seule question qui compte est donc celle-ci : devez-vous encore prouver l'authenticité de ce rapport après 2035 ? Si oui, Ed25519 ne suffira pas.

Ce n'est pas un avertissement de conformité, c'est une question qu'on retourne au lecteur, parce que lui seul connaît la réponse. Personne ne sait, depuis le code, si un rapport sera archivé quinze ans ou jeté au trimestre suivant.

Pour les cas où la réponse est « oui », la sortie existe et elle est même élégante : les signatures fondées sur les fonctions de hachage. Elles ne reposent sur aucune structure mathématique riche, seulement sur la solidité de SHA-256 — ce qui les rend insensibles à Shor par construction. Le prix est en octets : une signature de dix à quarante kilooctets là où Ed25519 en demande soixante-quatre. Pour un rapport archivé quinze ans, c'est une facture dérisoire. C'est la suite prévue, et elle attend un besoin réel plutôt qu'une envie.

## Ce que ça a donné

- **Les constats signés, pas le fichier** : deux rendus du même inventaire, dans deux langues, portent la même empreinte.
- **La clé publique attendue dans la déclaration versionnée** : en changer est un commit relu, pas un détail de ligne de commande.
- **Trois échecs distingués** à la vérification — contenu modifié, autre clé que celle déclarée, bloc illisible — parce qu'un « invalide » sec n'apprend rien à qui doit décider.
- **Zéro dépendance ajoutée**, zéro infrastructure, zéro chaîne de blocs.
- **La contradiction imprimée dans le document**, avec l'année de péremption dedans.

## Bonnes pratiques

- Séparer les trois besoins avant de choisir un outil : intégrité, authenticité, date opposable. Ils n'appellent pas la même réponse, et les confondre amène à construire dix fois trop.
- Signer ce qui a un sens, pas ce qui a des octets : signer un rendu produit des alertes à chaque exécution, et une alerte systématique finit ignorée.
- Mettre la clé publique attendue sous revue de code. Sinon la vérification ne prouve que l'existence d'une clé.
- Juger une signature à la durée de vie de ce qu'elle prouve, pas à la mode de son algorithme.
- Écrire la réserve dans le livrable, avec ses chiffres, plutôt que dans une note de bas de page que personne n'ouvre.

## Points de vigilance

- **Une signature ne date rien.** Elle dit qui, pas quand : le champ de date est déclaratif et signé par celui qui l'écrit. Une date opposable demande un tiers, et il faut le dire plutôt que laisser croire le contraire.
- Une chaîne de blocs privée est un tiers de confiance déguisé en protocole. Si l'on doit être cru sur parole de toute façon, autant signer et l'assumer.
- Les signatures fondées sur le hachage ont un état à gérer dans certaines variantes : en choisir une sans stockage d'état, sous peine de transformer une sauvegarde restaurée en catastrophe silencieuse.
- **Le vrai risque ici n'est pas l'algorithme, c'est l'habitude.** Une signature qu'on ne vérifie jamais ne vaut rien, quelle que soit sa courbe. La commande de vérification doit tenir dans une ligne, sinon personne ne la tapera.
