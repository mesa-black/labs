---
title: "Nous étions notre propre meilleur client. C'était un bug."
standfirst: "Notre entreprise publie sur notre plateforme — et se comptait dans notre chiffre d'affaires, notre funnel et nos listes de relance. Comment on l'a sortie des statistiques sans la sortir du site."
key: notre-propre-meilleur-client
date: 2026-09-30
slug: notre-propre-meilleur-client
---

On recommande à tout le monde d'utiliser son propre produit. Personne ne prévient de l'effet secondaire : à partir du moment où votre entreprise a un compte, elle entre dans vos chiffres. Pas dans une note de bas de page — dans le chiffre d'affaires, dans le taux de conversion, dans les listes de clients à relancer.

Notre cas : BlackMesa publie de vrais retours d'expérience sur Show me the REX. Le compte est réel, le plan est réel, les articles sont lus. Ce qui n'est pas réel, c'est le revenu : on ne se facture pas. Résultat, un client à zéro euro figurait dans le MRR, gonflait la répartition par plan, et remplissait une case du funnel de conversion sans avoir jamais rien converti.

La correction évidente — « on exclut notre entreprise » — est fausse. Elle suppose que le problème est l'entreprise. Le problème est ailleurs.

## Ce n'est pas « qui exclure », c'est « qu'est-ce que ce chiffre répond »

Le réflexe est de chercher une liste d'entités à écarter. La bonne question se pose métrique par métrique : à quelle question ce chiffre sert-il de réponse ?

Un compteur de vues répond à « combien de personnes ont lu ce texte ». La réponse est la même que le lecteur vienne de chez nous ou d'ailleurs : la page a été servie, elle a été lue, le contenu existe. Exclure nos vues rendrait ce chiffre faux.

Un chiffre d'affaires mensuel répond à « combien nous paient nos clients ». Notre propre entreprise n'est pas un client. Sa présence rend ce chiffre faux.

Les deux métriques regardent la même base de données, parfois la même ligne, et ont besoin de règles opposées. Ce n'est pas une exception à gérer, c'est la règle : **l'unité d'exclusion n'est pas la donnée, c'est la question posée.**

## Le cas qui tranche : une vue qui compte et ne compte pas

Le meilleur exemple est aussi le plus inconfortable, parce qu'il interdit tout raccourci d'implémentation.

Sur la plateforme, une vue de REX alimente deux choses distinctes. D'un côté l'audience : le compteur affiché sur l'article, le cumul du tableau de bord, la courbe de fréquentation. De l'autre un signal commercial : « quelles entreprises ont consulté vos REX », qui sert à identifier des contacts à relancer.

Même événement, même enregistrement. Dans le premier groupe, une lecture faite depuis chez nous compte — quelqu'un a vraiment lu. Dans le second, elle ne doit surtout pas compter : nous ne sommes pas un prospect à rappeler, et un lecteur interne dans une liste de leads, c'est une action commerciale déclenchée pour rien.

Il n'existe donc pas de filtre global qu'on poserait une fois à l'entrée. Chaque requête doit savoir à quelle famille elle appartient.

## Un drapeau en base, pas une constante dans le code

Première version, la plus rapide : une liste de noms d'entreprises en dur. Elle a tenu une heure. Une constante oblige à un déploiement pour reclasser une entreprise, et surtout elle ment sur la nature de l'information : « cette entreprise n'est pas un client » est une donnée métier, qui change, qui se décide, et qui doit être visible par la personne qui administre les comptes.

C'est donc devenu une case à cocher sur la fiche entreprise — avec son texte d'aide écrit noir sur blanc, parce qu'une option dont personne ne comprend la portée finit cochée au hasard :

> Nos propres entreprises publient et restent visibles en front, mais ne comptent dans aucune donnée commerciale ou marketing : MRR, plans, funnel, upsell/churn, leads, récaps. Les vues et visites, elles, restent comptées.

La liste de noms n'a pas disparu pour autant : elle sert d'amorçage, pour qu'un environnement fraîchement installé ne démarre jamais avec des chiffres pollués. Mais elle ne décide plus rien.

Le prédicat lui-même vit dans une seule petite classe, en deux versions — une pour les requêtes de l'ORM, une pour le SQL brut. Ça paraît anecdotique ; c'est ce qui rend la règle auditable. Chercher les endroits qui l'appliquent est devenu une recherche de texte, et la comparaison avec la liste des chiffres commerciaux se fait à l'œil en une minute.

## Vérifier plutôt que relire

Relire son propre code d'exclusion ne prouve rien : on relit ce qu'on croit avoir écrit. La seule vérification qui vaille consiste à basculer la case et à comparer les tableaux de bord avant et après, chiffre par chiffre.

Une trentaine de valeurs se sont déplacées. Sept sont restées rigoureusement identiques — et c'était le résultat attendu : ce sont les compteurs d'audience et les volumes de contenu publié. Un chiffre qui bouge alors qu'il ne devait pas est un bug ; un chiffre qui ne bouge pas alors qu'il aurait dû est un oubli. Sans ce passage, on n'aurait distingué ni l'un ni l'autre.

Au final : un drapeau, une classe de politique, trente-quatre prédicats répartis sur huit fichiers — MRR, plans, funnel, upsell, risque de départ, relances, intelligence commerciale, récapitulatifs mensuels, expiration des codes promo, nurturing.

Ce dernier mérite une mention. Sans l'exclusion, notre propre entreprise entrait dans la séquence de relance automatique. On se serait envoyé nos propres e-mails de réengagement.

## Ce que ça a donné

- **Un MRR qui ne contient plus de client à zéro euro**, et un taux de conversion qui ne compte plus notre propre inscription dans son dénominateur.
- **Une trentaine de valeurs corrigées** sur les tableaux de bord commerciaux, sept volontairement inchangées.
- **Zéro changement en front** : les REX restent publiés, visibles, filtrables, et leurs vues comptent toujours.
- **Une règle écrite à un seul endroit**, avec la raison, plutôt qu'un `AND` recopié de requête en requête.
- **Une case à cocher** qui permet de reclasser une entreprise sans déployer.

## Bonnes pratiques

- Classer chaque métrique avant de coder le filtre : mesure d'audience, ou signal commercial. La réponse détermine la règle, et elle n'est pas la même pour deux chiffres issus de la même table.
- Mettre l'appartenance en base, pas dans une constante : c'est une donnée métier, elle change et elle se décide.
- Concentrer le prédicat dans une classe unique, même s'il tient en une ligne : ce qui compte n'est pas la réutilisation, c'est de pouvoir retrouver tous les appels.
- Vérifier en basculant : comparer les chiffres avant et après est le seul moyen de distinguer un oubli d'une décision.
- Écrire le périmètre dans l'interface d'administration, à l'endroit où la case se coche.

## Points de vigilance

- **Rien n'empêche la prochaine requête d'oublier le prédicat.** La règle est tenue par la relecture, pas par un test, et c'est aujourd'hui la faiblesse principale du dispositif.
- Une exclusion trop large est aussi fausse qu'une exclusion absente : retirer nos vues du compteur d'audience aurait produit un chiffre mensonger dans l'autre sens.
- Le jour où une entreprise interne devient un vrai client payant, la case doit se décocher — et personne ne le rappellera. La décision est humaine, elle a besoin d'un moment où on la reprend.
- Dire publiquement que vos statistiques excluent vos propres données ne coûte rien, et vaut mieux que de le découvrir à la place de quelqu'un d'autre.
