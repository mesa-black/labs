---
title: "Une date que personne n'a besoin de croire"
standfirst: "En octobre, nous avons sorti la date de nos rapports de notre propre horloge pour la confier à trois autorités d'horodatage. Le rapport avoue lui-même la limite : leurs jetons ne valent rien au-delà du RSA qui les signe. Voici la suite : une preuve de date faite uniquement de SHA-256, qui aboutit dans un bloc Bitcoin, que n'importe qui vérifie sans faire confiance à personne. Et ce qu'elle ne prouve pas, parce que c'est la moitié du sujet."
key: une-date-que-personne-n-a-besoin-de-croire
date: 2026-11-24
slug: une-date-que-personne-n-a-besoin-de-croire
draft: true
---

[[À COMPLÉTER avant publication : la date du billet, le numéro et l'heure du bloc qui ancre l'inventaire de ce site, et les sorties des commandes rejouées dans un conteneur vide. Rien ci-dessous n'est à publier tant que ces trois points ne sont pas faits.]]

Notre article [« Une signature prouve qui et quoi. Jamais quand. »](/quand/) se terminait sur une phrase que le rapport imprime à côté de chaque date attestée :

> Ce que le jeton ne prouve pas : rien au-delà de RSA-4096, le schéma qui le signe.

C'est honnête, et c'est gênant. Un outil qui passe quarante pages à expliquer que [RSA](https://observatoire.mesa.black/comprendre#g-rsa) périme ne peut pas se contenter de dater ses propres conclusions avec du RSA. Pour mémoire : RSA est l'algorithme à clé publique le plus répandu, et un ordinateur quantique assez grand le casserait. Le jour où ça arrivera a un nom, le [Q-Day](https://observatoire.mesa.black/comprendre#g-q-day), que notre [Observatoire post-quantique](https://observatoire.mesa.black/comprendre) explique pas à pas. Nous avions divisé la confiance entre trois autorités, dans trois juridictions. Mais diviser la confiance, ce n'est pas s'en passer.

Puis la question est venue sous une forme plus directe : *pourquoi ma signature vaudrait-elle plus qu'une référence publique ? On ne peut pas dater par rapport à quelque chose que tout le monde peut vérifier ?*

On peut. Mais la question en contient deux, et il faut les séparer avant de répondre.

## Qui, et quand : deux questions, deux outils

Une signature répond à **qui**. La nôtre est d'ailleurs doublée d'une signature post-quantique, [ML-DSA](https://observatoire.mesa.black/comprendre#g-ml-dsa). Notre déclaration dit « ces données n'ont pas besoin de rester confidentielles », et tout le verdict du rapport en dépend. Ce qui compte, c'est qu'une personne identifiable s'y engage. Une référence publique n'y peut rien : n'importe qui peut ancrer n'importe quel fichier, ce qui prouve qu'il existait, pas que quelqu'un l'assume.

Une date répond à **quand**. Et là, la question est juste : rien n'oblige à la faire porter par quelqu'un qu'il faut croire. Une autorité d'horodatage *signe* une date ; on peut aussi *inscrire* une empreinte dans un registre public, où personne ne peut plus la déplacer.

Nous gardons donc la signature pour le **qui**, et nous changeons d'outil pour le **quand**.

## OpenTimestamps, en une phrase

[OpenTimestamps](https://opentimestamps.org), un protocole ouvert [publié par Peter Todd en 2016](https://petertodd.org/2016/opentimestamps-announcement), relie une empreinte à un bloc de la chaîne [Bitcoin](https://fr.wikipedia.org/wiki/Bitcoin) par une suite d'opérations de hachage, que n'importe qui peut refaire.

Le mécanisme, sans le jargon :

1. On envoie **l'empreinte** des constats, trente-deux octets, à des serveurs publics qu'on appelle des **calendriers**. Comme pour une autorité d'horodatage, le document ne sort jamais. Le client y mêle même seize octets aléatoires avant l'envoi, pour qu'un calendrier ne puisse pas relier un rapport publié à celui qui l'a soumis.
2. Chaque calendrier range les empreintes qu'il reçoit dans un **[arbre de Merkle](https://fr.wikipedia.org/wiki/Arbre_de_Merkle)** : on hache les empreintes deux par deux, puis les résultats deux par deux, jusqu'à une seule valeur, la racine.
3. Toutes les quelques heures, le calendrier inscrit cette racine dans **une** transaction Bitcoin. Une transaction pour des milliers d'empreintes : c'est pour ça que le service est gratuit.
4. Une fois cette transaction dans un bloc, la preuve devient complète. C'est la liste des hachages qui mènent de **votre** empreinte à la racine de Merkle de **ce** bloc.

Vérifier, c'est refaire ces hachages et comparer le résultat à l'en-tête du bloc. Il n'y a ni signature, ni certificat, ni autorité dans la boucle. Ce qu'on obtient est de la même forme qu'en octobre : *cette empreinte existait **au plus tard** quand ce bloc a été miné.*

## Pourquoi c'est plus solide que trois autorités

**Il n'y a plus de signature à croire.** Un jeton [RFC 3161](https://www.rfc-editor.org/rfc/rfc3161) dit « l'autorité affirme ». Une preuve OpenTimestamps dit « refais le calcul ». La différence ne tient pas à la confiance qu'on accorde à l'opérateur : il n'y a plus d'opérateur dont l'affirmation compte. Un calendrier qui tomberait demain, ou qui voudrait mentir, ne pourrait rien retirer à une preuve déjà complète.

**Falsifier coûte un bloc.** Pour antidater un document, il faudrait faire apparaître son empreinte dans un bloc ancien. Ce bloc est recopié par des dizaines de milliers de nœuds, et la chaîne de travail qui le suit représente des années d'électricité. Pour présenter un faux en-tête à un vérificateur qui contrôle la [preuve de travail](https://fr.wikipedia.org/wiki/Preuve_de_travail), il faudrait miner un bloc à la difficulté réelle. Au cours actuel, c'est **[[À COMPLÉTER : ordre de grandeur, en euros, du coût d'un bloc à la difficulté du jour]]**, pour mentir à une seule personne.

**Et surtout, il n'y a que du hachage.** C'est le point qui nous intéresse, puisque c'est le sujet de tout ce site. Un jeton signé en RSA-4096 tombe le jour où un ordinateur quantique fait tourner [l'algorithme de Shor](https://fr.wikipedia.org/wiki/Algorithme_de_Shor) à cette taille : on pourra alors fabriquer des jetons à n'importe quelle date. Une preuve OpenTimestamps n'est faite que de [SHA-256](https://fr.wikipedia.org/wiki/SHA-2) (et parfois de RIPEMD-160). Contre une fonction de hachage, un ordinateur quantique dispose de [l'algorithme de Grover](https://fr.wikipedia.org/wiki/Algorithme_de_Grover), qui **divise par deux** la marge de sécurité au lieu de l'annuler. Pour trouver un autre document qui suive le même chemin de hachages, il faudrait de l'ordre de 2¹²⁸ opérations, même avec Grover. La preuve que nous produisons aujourd'hui a toutes les raisons d'être encore lisible en 2040.

Une précision, pour ne pas en dire plus que ce qui est vrai : la sécurité *de Bitcoin* comme monnaie repose aussi sur ECDSA, qui est vulnérable au quantique. Mais une preuve de date n'en dépend pas. Elle a besoin que l'en-tête du bloc existe et qu'il ait coûté du travail, pas que quiconque puisse encore dépenser ses bitcoins.

## « Vous avez juste remplacé une autorité par une blockchain »

C'est l'objection sérieuse, et il faut lui répondre précisément. **Il reste un endroit où l'on fait confiance à quelqu'un : celui qui vous donne l'en-tête du bloc.**

Pour vérifier, il faut connaître la racine de Merkle du bloc numéro N. Si vous avez votre propre nœud Bitcoin, vous l'avez, et vous ne croyez personne. Sinon, vous la demandez à quelqu'un, en général un explorateur public, et c'est là que la confiance revient.

Voici ce que nous en avons fait dans [Sablier](https://github.com/mesa-black/sablier), dans cet ordre :

1. **Votre propre nœud**, s'il est configuré. Aucune confiance nécessaire.
2. Sinon, **deux explorateurs indépendants** ([blockstream.info](https://blockstream.info) et [mempool.space](https://mempool.space)), **qui doivent donner le même en-tête**. S'ils divergent, la vérification échoue bruyamment.
3. Et dans tous les cas, **on vérifie l'en-tête lui-même** : son double SHA-256 doit être inférieur à la cible de difficulté qu'il annonce, et cette difficulté doit dépasser un plancher. Un explorateur qui voudrait mentir ne peut donc pas inventer un en-tête : il devrait en **miner** un.

C'est la différence avec une autorité : on ne croit pas l'explorateur, on vérifie ce qu'il donne. Il peut refuser de répondre, il ne peut pas mentir à bas prix.

Hors ligne, en mode `--airgap`, on peut fournir l'en-tête à la main. Il passe alors les mêmes contrôles.

## Ce que ça ne prouve pas

C'est la moitié du sujet, et nous l'écrivons dans le rapport plutôt qu'en note.

- **Qui.** Une preuve OpenTimestamps ne dit rien de l'auteur. C'est le travail de la signature, et ça le reste.
- **Une heure précise.** L'horodatage d'un bloc Bitcoin est fixé par le mineur, dans une marge : il doit dépasser la médiane des onze blocs précédents et ne pas avoir plus de deux heures d'avance ([les règles exactes](https://en.bitcoin.it/wiki/Block_timestamp), en anglais). La date est donc juste **à quelques heures près**, pas à la seconde. Pour dire « inventorié avant le 31 décembre 2026 », c'est largement suffisant ; pour départager deux dépôts à dix minutes d'écart, non.
- **Tout de suite.** La preuve n'est complète qu'après l'inscription dans un bloc, en général **[[À COMPLÉTER : délai mesuré entre la soumission et la preuve complète]]**. Dans l'intervalle, on a une promesse des calendriers, pas une preuve.
- **Que le document n'existait pas avant.** Comme un jeton RFC 3161, c'est une borne supérieure. Prouver le contraire (« ce rapport n'a pas été fabriqué à l'avance ») demanderait d'y inclure une valeur publique imprévisible du jour, comme un tirage de la balise [drand](https://drand.love). C'est un autre outil, et nous ne l'avons pas construit.
- **Une valeur juridique.** Un horodatage *qualifié* au sens d'eIDAS bénéficie d'une présomption d'exactitude de la date ([règlement (UE) n° 910/2014](https://eur-lex.europa.eu/legal-content/FR/TXT/?uri=CELEX:32014R0910), article 41). Une preuve OpenTimestamps n'en a aucune : un juge peut l'admettre, rien ne l'y oblige.

## Les deux ensemble, et pourquoi

D'où notre choix : **nous gardons les jetons RFC 3161, et nous ajoutons l'ancrage.** Ils ne répondent pas au même horizon.

| | jeton RFC 3161 | preuve OpenTimestamps |
|---|---|---|
| ce qu'il faut croire | l'autorité, et le RSA qui la signe | rien, si vous avez un nœud ; sinon, un en-tête dont on vérifie le travail |
| précision | la seconde | quelques heures |
| disponible | immédiatement | après un bloc, en quelques heures |
| reconnaissance juridique | présomption, si l'horodatage est qualifié eIDAS | aucune |
| tenue face au quantique | tombe avec RSA | ne repose que sur le hachage |

Le jeton sert pour un litige dans les trois prochaines années. La preuve sert pour la question qu'on nous posera en 2040, quand plus personne ne pourra vérifier une signature RSA de 2026 sans se demander qui l'a fabriquée hier.

## Le faire chez vous, aujourd'hui, sans nous

Comme en octobre, rien de cela n'a besoin de notre outil. Le [client officiel](https://github.com/opentimestamps/opentimestamps-client) suffit.

[[À COMPLÉTER : rejouer ce bloc dans un conteneur vide, coller les sorties réelles, et vérifier en particulier ce que fait `ots verify` sans nœud Bitcoin local.]]

```
pip install opentimestamps-client

# 1. ancrer : l'empreinte part vers les calendriers, un fichier .ots revient
ots stamp artefact.json

# 2. quelques heures plus tard : récupérer la preuve complète
ots upgrade artefact.json.ots

# 3. vérifier : refaire les hachages jusqu'au bloc
ots verify artefact.json.ots
```

Rangez le `.ots` à côté de l'artefact, comme le `.tsr`. Votre lecteur n'a besoin ni de vous ni d'un format maison.

## Dans Sablier

Tout cela tient dans un drapeau, à côté de `--timestamp` :

```
sablier scan . --sign=sablier.key \
  --timestamp=http://time.certum.pl \
  --anchor=opentimestamps
```

Contrairement à `--timestamp`, il existe ici un choix par défaut : `opentimestamps` désigne les calendriers publics du projet. Pour les autorités, nous avions refusé tout défaut, parce que choisir qui atteste vos dates est une décision de confiance. Un calendrier, lui, ne peut pas mentir : au pire, il n'ancre pas, et la preuve se vérifie sans lui.

Les règles sont les mêmes qu'en octobre :

- une preuve qui ancre déjà ces constats est **conservée**, parce que la plus ancienne est la seule qui vaut ;
- un calendrier injoignable est signalé bruyamment, sans faire échouer l'analyse ;
- le mode `--airgap` refuse l'ancrage, puisqu'il passe par le réseau.

`sablier verify` va chercher la preuve complète quand elle est en attente, puis la vérifie.

L'inventaire de ce site est ancré depuis **[[À COMPLÉTER : date]]**, au bloc **[[À COMPLÉTER : numéro]]**. La preuve est en ligne à côté du rapport, avec ses trois jetons :

```
curl -sO https://mesa.black/audit/report.html.ots
ots verify -d 8ecb829ccc278ef7ab3138f56e07ee13319cbb72ce1dabbfc58ee7b4d6b670b5 report.html.ots
```

[[À COMPLÉTER : sortie réelle de cette commande.]]

## Bonnes pratiques

- **Séparez qui et quand.** Une signature engage une personne. Une date n'a pas besoin d'engager qui que ce soit, elle a besoin d'être vérifiable.
- **Ancrez une empreinte, pas un fichier.** Trente-deux octets sortent, rien d'autre.
- **Gardez les deux preuves.** Le jeton pour les prochaines années et la reconnaissance juridique, l'ancrage pour l'horizon où le RSA ne vaudra plus rien.
- **Complétez la preuve, puis gardez-la.** Une preuve en attente dépend encore des calendriers. Une preuve complète ne dépend plus de personne, mais elle ne se complète pas toute seule.
- **Vérifiez l'en-tête, ne le croyez pas.** Si vous n'avez pas de nœud, comparez au moins deux sources et contrôlez la preuve de travail.

## Points de vigilance

- Une preuve OpenTimestamps borne une date par le haut, à quelques heures près. La présenter comme une heure exacte est le genre d'approximation qui se retourne devant quelqu'un d'attentif.
- Un explorateur public reste un tiers. Sans nœud et sans contrôle de la preuve de travail, vous avez simplement déplacé la confiance une fois de plus.
- Une preuve en attente n'est pas une preuve. Un rapport qui afficherait « ancré » avant l'inscription dans un bloc dirait plus qu'il ne sait.
- Aucune valeur juridique n'est attachée à l'ancrage. Si vous avez besoin d'une présomption devant un juge, il vous faut un horodatage qualifié eIDAS, en plus.
- Ancrer ne dit rien de l'auteur. Une empreinte ancrée sans signature prouve qu'un fichier existait, pas que quelqu'un en répond.

## Références

- **OpenTimestamps** : [le site du projet](https://opentimestamps.org), [le client officiel](https://github.com/opentimestamps/opentimestamps-client), [l'annonce de Peter Todd en 2016](https://petertodd.org/2016/opentimestamps-announcement) (en anglais).
- **Horodatage par autorité** : [RFC 3161](https://www.rfc-editor.org/rfc/rfc3161) ; [règlement eIDAS (UE) n° 910/2014](https://eur-lex.europa.eu/legal-content/FR/TXT/?uri=CELEX:32014R0910), article 41.
- **Bitcoin** : [les règles d'horodatage des blocs](https://en.bitcoin.it/wiki/Block_timestamp) (en anglais), [la preuve de travail](https://fr.wikipedia.org/wiki/Preuve_de_travail).
- **Cryptographie** : [RSA](https://fr.wikipedia.org/wiki/Chiffrement_RSA), [l'algorithme de Shor](https://fr.wikipedia.org/wiki/Algorithme_de_Shor), [l'algorithme de Grover](https://fr.wikipedia.org/wiki/Algorithme_de_Grover), [SHA-2](https://fr.wikipedia.org/wiki/SHA-2), [les arbres de Merkle](https://fr.wikipedia.org/wiki/Arbre_de_Merkle).
- **Aléa public** : [drand](https://drand.love) (en anglais).
- **Notre Observatoire post-quantique** : [le Q-Day](https://observatoire.mesa.black/comprendre#g-q-day), [la cryptographie post-quantique](https://observatoire.mesa.black/comprendre#g-post-quantique), [« récolter maintenant, déchiffrer plus tard »](https://observatoire.mesa.black/comprendre#g-harvest), [ML-DSA](https://observatoire.mesa.black/comprendre#g-ml-dsa), [RSA](https://observatoire.mesa.black/comprendre#g-rsa), [la fonction de hachage](https://observatoire.mesa.black/comprendre#g-hachage), [l'horodatage](https://observatoire.mesa.black/comprendre#g-horodatage).
- **Chez nous** : [« Une signature prouve qui et quoi. Jamais quand. »](/quand/), [Sablier](https://github.com/mesa-black/sablier), et [l'inventaire de ce site](/audit/report.html).
