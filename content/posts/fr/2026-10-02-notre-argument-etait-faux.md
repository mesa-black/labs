---
title: "On a vérifié notre principal argument. Il était faux depuis 2015."
standfirst: "Ce que la vérification a coûté, ce qu'il en reste, et la seule question que personne dans ce domaine n'a l'air d'avoir testée."
key: notre-argument-etait-faux
date: 2026-10-02
slug: notre-argument-etait-faux
---

Dans l'étude de cadrage de [Sablier](https://github.com/mesa-black/sablier), publiée il y a quelques jours, une phrase portait tout le reste. Elle disait que la place libre n'était pas d'inventorier la cryptographie d'un projet — d'autres le font — mais de **relier cet inventaire à la durée de vie des données**, et que personne ne le faisait.

Cette phrase est fausse. Nous l'avons découvert en la vérifiant, une semaine trop tard, et ce texte raconte ce que la vérification a donné parce que c'est plus utile que de la corriger en silence.

## Ce que la vérification a donné

**La formule porte un nom depuis 2015.** C'est l'inégalité de Mosca : `X + Y > Z`, où X est la durée pendant laquelle la donnée doit rester confidentielle, Y le temps que prendra la migration, et Z les années avant qu'un calculateur quantique pertinent existe. Si la somme dépasse, il y a une fenêtre pendant laquelle des données encore sensibles ne sont plus protégées. C'est la référence standard des directions de la sécurité et des agences.

Ce que nous présentions comme notre angle, c'est cette inégalité avec Y supprimé et Z remplacé par l'échéance réglementaire. Une simplification d'un cadre connu, pas une trouvaille.

**Et l'angle est occupé.** Plusieurs projets l'implémentent déjà contre une base de code, avec inventaire, durée par actif et calcul de l'exposition. L'un d'eux, un prototype en Python du même âge et de la même maturité que le nôtre, produit même un rapport HTML autonome imprimable en PDF. La ressemblance ne s'arrête pas là.

## L'inventaire de ce qui est tombé

Nous avions listé quatre choses qui restaient nôtres. Trois n'ont pas tenu plus d'une heure de vérification.

**« Une signature ne se récolte pas. »** C'était notre meilleur argument technique : appliquer une inégalité qui parle de confidentialité à une signature, c'est la noter comme si le trafic pouvait être capturé et ouvert plus tard, ce qui est faux. Sauf que le même projet fait exactement cette distinction, et la formule mieux que nous : *un calculateur quantique ne peut pas dé-signer une version de 2026*. Il recalibre X selon l'usage — durée de vie de la donnée pour le chiffrement, durée de validité de la clé pour la signature — et propose des remplacements différents pour le même algorithme selon ce qu'il protège.

**La sonde active.** Notre différence fonctionnelle la plus démontrable : lire ce qu'un serveur négocie vraiment plutôt que ce qu'un fichier déclare. Ils la font aussi, avec une précaution que nous n'avions pas écrite — la sonde est le seul composant qui sort de la machine, et leur documentation la dessine en pointillés pour cette raison.

**Le refus de prédire.** Nous utilisons l'échéance réglementaire en disant que nous ne prévoyons pas l'arrivée d'un calculateur quantique. Eux modélisent Z comme une distribution de probabilité et rendent une médiane avec son incertitude. C'est plus sophistiqué que notre refus, et probablement plus juste.

Il reste ce qui n'est pas une idée : **l'écosystème PHP**, que ces outils ne couvrent pas ; **aucun service, aucune base, une commande** là où ils exposent une console web locale avec un historique ; et **zéro dépendance**, qui sur un outil qui lit des clés reste un argument, même modeste.

C'est beaucoup plus petit que ce que nous avions écrit. C'est ce qui est vrai.

## La question que personne n'a testée

Mais la vérification a rapporté davantage qu'elle n'a coûté, et c'est le cœur de ce texte.

Tous ces outils, le nôtre compris, reposent sur la même variable. Mosca l'appelle X. Nous l'appelons durée de confidentialité. Un autre l'appelle *security shelf life*. Et **tous la supposent disponible.** Les articles donnent des ordres de grandeur par secteur — dix ans pour du paiement, cinquante pour du médical — mais un ordre de grandeur sectoriel n'est pas une réponse d'entreprise.

Or nous n'avons trouvé, nulle part, la trace de quelqu'un ayant vérifié **qu'une entreprise réelle sait répondre à cette question.** Pas « quelle est la bonne réponse », mais « la personne qui devrait savoir sait-elle ? » Combien de temps faut-il pour la lui faire formuler ? Sur combien de catégories bute-t-elle ?

Si la réponse est « elle sait, en une heure », alors le domaine est sain et se départagera à l'exécution. Si la réponse est « elle ne sait pas », alors **tous ces outils sont bâtis sur du sable**, le nôtre le premier, et aucun détecteur supplémentaire n'y changera rien. Il faudra reposer la question autrement — probablement en partant de la conservation légale, que les gens connaissent, au lieu de la durée de confidentialité, qu'ils n'ont jamais eu à mettre en mots.

C'est devenu la seule chose qui compte dans ce projet. Pas un détecteur de plus : une réponse empirique à la question de savoir si l'entrée existe.

## Ce que ça change à la méthode

Une chose nous a frappés après coup. Nous avons écrit neuf détecteurs, six protocoles de sonde, trois langues de rapport et un mécanisme de signature — **avant** de vérifier la seule phrase sur laquelle tout reposait. L'ordre était inversé, et il l'était pour une raison confortable : construire est agréable, vérifier ne l'est pas, et une phrase qu'on a écrite soi-même semble vraie.

Le correctif ne coûte rien. La phrase qui vend se vérifie avant le code qui livre. Une recherche, vingt minutes, avant la première ligne.

Et puisque ce projet passe son temps à dire qu'un inventaire qui tait ce qu'il n'a pas regardé fabrique de la fausse assurance, il ne pouvait pas garder une revendication d'exclusivité non vérifiée dans sa propre documentation. Le cadrage a été corrigé sur place, avec le tableau de l'état de l'art à jour et la liste, plus courte, de ce qui reste.

## Ce que ça a donné

- **Une revendication d'exclusivité retirée** de la documentation publique, et remplacée par un état de l'art vérifié et daté.
- **Trois différenciateurs sur quatre écartés** en une heure de recherche, dont le meilleur.
- **Une question ouverte identifiée** que le domaine entier suppose résolue, et qui ne l'est pas.
- **Zéro ligne de code changée** : la vérification n'a rien invalidé du produit, seulement de son récit.

## Bonnes pratiques

- Vérifier la phrase qui vend avant d'écrire le code qui livre. Elle est plus courte à vérifier et plus coûteuse à se tromper.
- Traiter une antériorité découverte comme une information, pas comme une défaite : plusieurs personnes arrivant indépendamment à la même idée en quelques mois est le meilleur signal disponible sur la réalité du besoin.
- Chercher ce que tout le monde suppose. Dans un domaine jeune, l'hypothèse partagée est l'endroit le plus rentable où creuser.
- Corriger sur place, en expliquant. Une correction silencieuse protège l'auteur ; une correction écrite protège le lecteur.

## Points de vigilance

- **Découvrir une antériorité ne dit rien de la qualité d'exécution**, dans un sens ni dans l'autre. Un prototype à une étoile n'occupe pas un marché, et notre prototype non plus.
- La tentation, après ce genre de vérification, est de chercher un différenciateur de remplacement jusqu'à en trouver un. C'est la même erreur, refaite dans l'autre sens.
- **Un ordre de grandeur sectoriel n'est pas une réponse d'entreprise.** « Dix ans pour du paiement » ne dit pas combien de temps *vos* données doivent rester secrètes, et c'est précisément ce qui reste à démontrer.
- Rien de tout ceci n'a été validé auprès d'une équipe extérieure. Y compris cette conclusion-là.
