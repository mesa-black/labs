---
title: "La fonctionnalité la moins chère est celle qu'on ne construit pas"
standfirst: "Trois signaux qui disent « n'écris pas ce code », et ce qu'ils nous ont fait économiser en une seule journée."
date: 2026-09-27
slug: le-code-qu-on-n-ecrit-pas
draft: true
---

La sobriété numérique se pose presque toujours comme un problème d'optimisation : des images plus légères, un meilleur cache, une région plus propre. Tout est vrai, et tout est marginal. Sur notre propre plateforme, l'hébergement émet peu : un seul serveur en France, sur l'un des mix électriques les moins carbonés d'Europe.

Le vrai gaspillage est ailleurs, et personne ne le mesure : **le code écrit pour rien**. Une migration à refaire, un outil acheté puis abandonné, une fonctionnalité livrée que personne n'ouvre jamais. Ça coûte incomparablement plus — en machines, en électricité, en mois de travail — que ce que n'importe quelle optimisation de front économisera jamais.

Alors on s'est posé une question qu'on n'avait jamais formulée : comment *décide*-t-on de ne pas construire quelque chose ?

## Le défi : on mesure ce qu'on livre, jamais ce qu'on évite

Toute équipe sait fêter une mise en production. Aucune ne sait fêter la fonctionnalité qu'elle n'a pas écrite : pas de ticket, pas de démo, pas de ligne dans le changelog. La décision ne laisse aucune trace, donc elle n'est jamais prise explicitement : elle est repoussée, réunion après réunion, jusqu'à ce que quelqu'un construise la chose par lassitude.

On s'est donné trois signaux. Les voici, avec ce que chacun a réellement économisé sur une journée de travail ordinaire.

## Signal 1 — c'était cassé et personne n'a rien dit

Notre popup « Nouveautés » côté client lit ses entrées dans les messages de commit marqués `Client:`. En l'auditant, on a découvert que **42 des 65 entrées jamais écrites n'avaient jamais été affichées** : git ne lit un trailer que dans le dernier paragraphe du commit, et la ligne était presque toujours écrite au-dessus de la signature. Les deux tiers de la fonctionnalité étaient morts depuis des semaines.

Le réflexe est de se précipiter pour corriger. La question utile vient avant : *personne ne s'est plaint*. Pas un client, pas un membre de l'équipe n'a remarqué qu'il manquait les deux tiers de ses nouveautés. C'est une information sur la fonctionnalité, pas sur le bug.

On a corrigé, parce que ça tenait en vingt lignes et que le contenu existait déjà. Mais s'il avait fallu réécrire, la réponse honnête aurait été de supprimer le popup. **Une fonctionnalité cassée que personne ne signale est une candidate à la suppression, pas à la réparation.**

## Signal 2 — le travail serait invisible

Le même jour, une autre demande : traduire l'espace client en anglais et en espagnol. On a mesuré avant d'écrire : 23 templates, ~426 chaînes, 83 messages flash, 192 libellés de formulaire, 19 e-mails. Environ **700 chaînes, 1 400 traductions**.

Puis on a cherché le lecteur. Il n'existait pas. Aucune préférence de langue n'est stockée sur un compte, et le sélecteur de langue ne vit que dans l'en-tête public. Un visiteur qui navigue en espagnol puis se connecte atterrit sur une page en français, sans autre issue que d'éditer l'URL à la main. On aurait produit 1 400 traductions que personne ne pouvait atteindre.

On a donc construit le prérequis de deux heures — enregistrer la langue, ajouter le sélecteur dans l'espace client, la respecter après connexion — et **on s'est arrêtés là**. La traduction se fera le jour où un client la demandera, et elle sera alors visible. Le jour où personne ne la demande, elle ne sera jamais écrite.

## Signal 3 — la discipline coûte moins cher que l'outil

« Durcissons notre SRE » finit presque toujours en liste de courses : traçage d'erreurs, supervision, tableaux de bord. On avait tout parqué pour des raisons de budget, et ce parking nous a rendu service.

Parce que le vrai manque n'était pas un outil. Une sauvegarde chiffrée de la base tournait chaque nuit depuis des semaines — et **n'avait jamais été restaurée une seule fois**. On a fait l'exercice : dump, chiffrement, déchiffrement, restauration dans une base jetable, comparaison des comptages table par table, et vérification qu'une mauvaise clé échoue vraiment. C'est passé, et ça n'a rien coûté.

Ça a surtout révélé deux points uniques de défaillance qu'aucun tableau de bord n'aurait montrés : la production et les sauvegardes vivent dans le même compte fournisseur, et la clé qui déchiffre les secrets n'existe qu'en ligne. Les deux correctifs sont gratuits et prennent cinq minutes. **On a mesuré et répété au lieu d'acheter.**

## Ce que ces signaux ne disent pas

« Personne n'en a besoin » est aussi l'excuse parfaite pour ne rien faire, et une règle qui ne sait dire que non n'est plus une règle, c'est de l'inertie. Deux garde-fous la gardent honnête.

D'abord, la décision doit être *écrite*, avec sa raison. « On ne traduit pas l'espace client tant qu'aucun client ne le demande » est une décision ; « on verra plus tard » est un évitement qui revient à chaque réunion et coûte de l'attention à chaque fois.

Ensuite, une fonctionnalité inutilisée n'est pas automatiquement inutile : parfois ce qui manque, c'est la visibilité, pas le besoin. Avant de conclure, vérifier que les gens pouvaient la trouver. Notre popup était invisible parce qu'il était cassé, pas parce qu'il était superflu.

## Et l'écologie, honnêtement

On ne peut pas vous donner de chiffre. On ne sait pas ce qu'émet notre hébergement, ni ce que ces décisions ont évité, et inventer un nombre rassurant serait exactement le verdissement que ce REX dénonce.

Ce qu'on peut dire sans forcer : 1 400 traductions non écrites, une fonctionnalité non reconstruite, un outil non acheté. Rien de tout ça n'apparaîtra dans un bilan carbone. Tout ça, ce sont des travaux qui ne consommeront jamais une machine, un déploiement, une relecture, ni la maintenance qui suit pendant des années.

**La décision la plus écologique de cette journée a été de ne pas construire quelque chose.**

## Ce que ça a donné

- **1 400 traductions non écrites** : le prérequis de 2 h livré, les 23 pages repoussées jusqu'à ce que quelqu'un en ait besoin.
- **42 entrées perdues récupérées** en corrigeant une règle d'extraction, sans ajouter la moindre fonctionnalité.
- **0 € d'outillage ajouté** : un exercice de restauration et un runbook plutôt qu'un abonnement de supervision.
- **Deux points uniques de défaillance** identifiés en répétant, pas en instrumentant.
- **Chaque décision écrite**, avec sa raison et ce qui la rouvrirait.

## Bonnes pratiques

- Avant d'écrire, chercher le lecteur. Si l'atteindre demande un prérequis, construire le prérequis seul et s'arrêter là.
- Mesurer le travail avant de le commencer : « 700 chaînes » tranche un débat que « ça va prendre un moment » entretient.
- Répéter avant d'acheter : une restauration réellement exécutée apprend plus qu'un tableau de bord que personne ne regarde.
- Écrire la décision de ne pas construire, avec sa raison — sinon ce n'est pas une décision, c'est un report.

## Points de vigilance

- « Personne n'en a besoin » est aussi l'excuse parfaite pour l'inertie : une règle qui ne dit que non a cessé d'être une règle.
- Une fonctionnalité inutilisée peut être mal exposée plutôt qu'inutile : vérifier la découvrabilité avant de conclure.
- Décider de ne pas construire n'est pas la même chose que ne pas décider : seule la première cesse de coûter de l'attention.
- Ne pas habiller la frugalité de chiffres carbone qu'on ne sait pas calculer : l'argument tient tout seul.
