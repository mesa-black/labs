---
title: "On ne peut pas sécuriser Luhn. C'est pour ça que votre carte a un CVV."
standfirst: "La formule de Luhn a été expliquée mille fois. Ce qu'on explique moins, c'est qu'elle ne protège de rien, que la rendre « plus sûre » est une erreur de catégorie, et que l'industrie du paiement l'a compris dès les années 1990. Nous avons aussi vérifié ce que notre propre outil voit quand un code s'en sert comme d'une serrure : rien. C'est corrigé, en partie, et voici ce qui reste."
key: on-ne-peut-pas-securiser-luhn
date: 2026-11-01
slug: on-ne-peut-pas-securiser-luhn
---

Le dernier chiffre d'un numéro de carte bancaire n'est pas un chiffre du compte. C'est une clé de contrôle, calculée sur les quinze autres par une [formule](https://fr.wikipedia.org/wiki/Formule_de_Luhn) qu'Hans Peter Luhn, ingénieur chez IBM, a brevetée en 1960. On la retrouve dans les numéros de carte, dans les IMEI des téléphones, et dans chaque SIREN et SIRET français.

Elle tient en trois lignes. En partant de la droite, on double un chiffre sur deux ; quand le double dépasse 9, on lui retire 9 ; on additionne tout. Le numéro est valide si la somme est un multiple de 10. `79927398713` passe, `79927398712` ne passe pas.

Ce texte part d'une idée qu'on entend régulièrement, et que nous avons eue nous aussi : puisque tout le monde connaît la formule, pourquoi ne pas la durcir ? Changer son « mode crypto », y mettre une clé, en faire quelque chose de sûr. La réponse courte est qu'on ne peut pas, et la raison est plus utile que la formule elle-même.

## Ce que Luhn fait vraiment

Luhn ne protège pas un numéro. Il protège contre une erreur de saisie : un humain qui recopie seize chiffres depuis une carte, au téléphone ou sur un clavier. Pour ce travail-là il est très bon, et nous l'avons vérifié plutôt que de le recopier :

- il détecte **toute erreur sur un seul chiffre** ;
- il détecte **toutes les inversions de deux chiffres voisins, sauf `09` ↔ `90`** ;
- il rate quelques « erreurs jumelles », quand deux chiffres identiques sont remplacés par deux autres identiques : `22` ↔ `55`, `33` ↔ `66`, `44` ↔ `77`.

C'est tout ce qu'on lui demande. La formule ne contient aucun secret : n'importe qui la calcule, et c'est voulu, puisque c'est le formulaire de paiement qui doit pouvoir dire « vous avez dû vous tromper » avant d'envoyer quoi que ce soit.

Pour un adversaire, la conséquence est immédiate. Un numéro tiré au hasard passe le contrôle **une fois sur dix** (sur cent mille tirages, nous en avons compté 10,2 %). Et quinze chiffres choisis donnent toujours un seizième qui les rend valides : il suffit de faire le calcul. Une protection qu'on calcule soi-même ne protège de rien.

## Pourquoi on ne peut pas la durcir

Supposons qu'on remplace l'arithmétique de Luhn par une fonction qui prend une clé secrète. Le chiffre de contrôle devient impossible à calculer sans la clé : le vœu est exaucé. Mais ce qu'on a construit a un nom, c'est un **[code d'authentification de message](https://fr.wikipedia.org/wiki/Code_d%27authentification_de_message)**, un MAC. Et un MAC se juge à sa longueur.

Un chiffre décimal, c'est 3,3 bits. Un adversaire qui ne connaît pas la clé devine le bon chiffre une fois sur dix, exactement comme avant. On a ajouté une clé à gérer, à faire tourner, à protéger, et la probabilité de falsification n'a pas bougé d'un iota.

Pour atteindre la sécurité qu'on attend d'un MAC moderne, 128 bits, il faudrait **39 chiffres de contrôle**. Un numéro de carte n'en a pas un de libre : le format est fixé par la norme ISO/IEC 7812, les terminaux et les formulaires du monde entier l'attendent tel quel. Le budget de sécurité d'un identifiant se compte en chiffres, et celui-ci est à zéro.

Le problème n'est donc pas que Luhn soit « faible ». Il fait parfaitement autre chose. Protéger contre un accident et protéger contre un adversaire sont deux métiers, et le premier n'est pas une version au rabais du second.

## Ce que l'industrie a fait à la place

Le secteur du paiement s'est posé la même question, et il a répondu en laissant Luhn tranquille et en mettant la sécurité à côté.

**Le [CVV](https://fr.wikipedia.org/wiki/Cryptogramme_visuel) est exactement le « Luhn avec une clé » qu'on cherchait.** Les trois chiffres au dos de la carte sont calculés par la banque émettrice, avec une paire de clés secrètes (en [3DES](https://fr.wikipedia.org/wiki/Triple_DES), dans un module matériel), sur le numéro, la date d'expiration et un code de service. Sans la clé, impossible de les calculer. C'est un MAC.

Et il a le défaut qu'on vient de décrire : trois chiffres, soit à peine 10 bits. Un sur mille. Ce qui le rend utilisable n'est pas la cryptographie, c'est tout ce qui l'entoure. La banque bloque la carte après quelques essais faux, et les règles [PCI DSS](https://fr.wikipedia.org/wiki/Norme_de_s%C3%A9curit%C3%A9_de_l%27industrie_des_cartes_de_paiement) interdisent de stocker le CVV après l'autorisation. Quand ces conditions sautent, les trois chiffres ne tiennent pas : en 2016, des chercheurs de l'université de Newcastle ont montré qu'en répartissant les essais sur des centaines de sites marchands, qui ne se parlent pas, on retrouvait le CVV d'une carte en quelques secondes.

La leçon est la même que pour Luhn, un cran plus loin : **un MAC trop court n'est sûr que tant qu'on compte les essais**.

L'industrie l'a si bien compris qu'elle a fini par jouer sur l'autre variable. Depuis le milieu des années 2010, certaines banques proposent des cartes à **cryptogramme dynamique** : un petit écran au dos affiche un CVV qui change à intervalle régulier, et les applications bancaires font de même pour les cartes virtuelles. Le code a toujours trois chiffres. Personne n'a essayé de le rallonger, puisque le format ne le permet pas. On a raccourci sa durée de vie. Un CVV deviné sur cent sites marchands ne sert plus à rien quand il a changé avant la fin de l'attaque, et un CVV volé avec le reste de la carte périme tout seul. C'est le principe des [codes à usage unique](https://fr.wikipedia.org/wiki/Mot_de_passe_%C3%A0_usage_unique) de nos applications d'authentification : quand on ne peut pas allonger un secret, on le fait mourir vite.

**La [tokenisation](https://fr.wikipedia.org/wiki/Tokenisation_%28s%C3%A9curit%C3%A9_informatique%29) est l'autre réponse.** Quand Apple Pay ou Google Pay enregistrent une carte, le téléphone ne reçoit pas le vrai numéro. Il reçoit un jeton émis par le réseau, qui a la forme d'un numéro de carte, Luhn compris, pour que les terminaux et les formulaires l'acceptent sans rien changer. Le jeton ne vaut rien en dehors de l'appareil et du contexte pour lesquels il a été émis. Le chiffrement à format préservé (FF1, normalisé par le NIST dans le SP 800-38G) fait un travail voisin : il chiffre un numéro de seize chiffres en un autre numéro de seize chiffres.

Dans les deux cas, Luhn reste ce qu'il est : un contrôle de saisie posé sur un numéro, que ce numéro soit vrai, jeton ou chiffré. La sécurité vit ailleurs, dans une clé, un module matériel et un compteur d'essais.

Une précision sur le quantique, puisque c'est notre sujet habituel : rien de tout ça n'en dépend. Un MAC repose sur une clé partagée, que le quantique n'affaiblit que marginalement. Le CVV n'a pas besoin d'un calculateur quantique pour être deviné, il a besoin d'un site marchand qui ne compte pas les essais.

## Ce que notre outil voit

[Sablier](https://github.com/mesa-black/sablier) lit un dépôt et relève toute la cryptographie qu'il y trouve. La question naturelle était donc : que dit-il d'un code qui utilise un contrôle de saisie comme une serrure ? Nous avons écrit un projet de quatre fichiers pour le savoir, et lancé dessus la version publiée, la 0.11.1, sans rien changer.

Les quatre fichiers :

- un bon d'achat accepté sur la seule foi de sa clé de Luhn, puis crédité de 50 € ;
- un lien de réinitialisation de mot de passe « signé » avec `crc32()`, et un jeton d'authentification vérifié par `hash('crc32b', …)` ;
- le même lien, signé correctement avec `hash_hmac('sha256', …)` et une clé secrète, comme témoin ;
- des numéros de carte stockés avec `openssl_encrypt(…, 'des-ede3-cbc', …)`.

Le rapport :

```
  . — 4 fichiers lus, 3 constats, 0.0 s
  déclaration : aucune (durées par défaut)

    CASSÉ AUJOURD'HUI        1
    CONFORME                 1
    PROBABLEMENT HORS SUJET  1
```

Le 3DES est trouvé et classé cassé, le [HMAC](https://fr.wikipedia.org/wiki/HMAC) est trouvé et classé conforme. Le bon d'achat, le lien signé au CRC et le jeton vérifié au CRC **n'apparaissent nulle part**. Ce sont pourtant les trois seuls endroits du projet où un inconnu peut obtenir quelque chose qui ne lui appartient pas.

Les raisons étaient précises, et elles étaient toutes dans le code :

- **Luhn écrit à la main n'a pas de signature.** C'est une boucle, une multiplication par deux et un modulo 10. Il n'y a aucun appel de bibliothèque à reconnaître, et nous n'avons jamais essayé.
- **`crc32()` n'était cherché par aucune règle.** C'est une fonction de PHP, facile à repérer, et personne n'y avait pensé.
- **`hash('crc32b', …)` était vu, puis jeté.** La règle qui lit `hash()` trouvait l'appel, cherchait `crc32b` dans son catalogue, ne le trouvait pas, et appliquait une règle écrite exprès pour les faux positifs : *un algorithme que nous ne connaissons pas n'est pas à nous de juger.* La ligne contient pourtant `$authToken`, un des mots qui, ailleurs dans le même fichier, font repasser un constat au rouge.
- **Le mot « checksum » faisait taire l'outil.** Il figure toujours dans la liste des indices qui signalent un identifiant plutôt qu'un contrôle de sécurité. Un `md5()` sur un jeton de réinitialisation, dans une fonction appelée `checksum`, ressort donc en « probablement hors sujet ». Sur ce cas précis la conclusion se défend, puisque les collisions de MD5 ne servent à rien contre l'empreinte d'un jeton aléatoire. Mais le motif est faux : l'outil l'a rangé parmi les clés de cache parce qu'il a lu le nom de la fonction, pas parce qu'il a compris ce qu'elle protège.

Il y a pire que le silence. Chaque rapport de Sablier se termine par une section « Ce que ce rapport n'a pas regardé », parce qu'un inventaire qui tait ses angles morts fabrique de la fausse assurance. Cette section parlait des services gérés, des HSM, des images, du YAML. **Elle ne parlait pas des checksums.** Le lecteur de ce rapport avait toutes les raisons de croire que ses liens de réinitialisation avaient été regardés.

Ce n'est pas un accident de parcours, c'est la conséquence d'un choix que nous défendons encore. Les listes qui font taire l'outil ont été construites sur une mesure : vingt dépôts publics, quatre-vingt-neuf constats classés « cassés », quatre-vingt-deux qui étaient des clés de cache, des noms de fichier ou des identifiants. Sans elles, les sept vrais constats se noyaient. Avec elles, sur trente et un dépôts, il ne reste que trois rouges faux sur vingt et un. Mais une liste qui fait taire l'outil sur un mot a besoin de la règle inverse, celle qui repère quand ce mot désigne justement ce qu'on protège, et pour « checksum » cette règle n'existait pas.

## Ce que l'outil dit maintenant

Le constat qui manquait n'était pas « CRC32 est cassé ». [CRC32](https://fr.wikipedia.org/wiki/Contr%C3%B4le_de_redondance_cyclique) n'est pas cassé, il fait très bien ce pour quoi il existe, vérifier qu'un fichier n'a pas été abîmé en route. Ce constat-là serait faux, et ce genre d'erreur apprend au lecteur à ne plus croire les rouges. Le constat juste porte sur l'**usage**, et c'est celui que Sablier imprime depuis la 0.12.0 :

> **CASSÉ AUJOURD'HUI** — `src/ResetLink.php:8`
> Une somme de contrôle protège contre un accident, pas contre quelqu'un : elle n'a pas de clé, n'importe qui la recalcule. L'échéance était hier.
> *Remplacement : HMAC-SHA-256 avec une clé secrète, comparé avec `hash_equals()`*

Sur le même projet de quatre fichiers, le rapport passe de trois constats à six :

```
  . — 4 fichiers lus, 6 constats, 0.0 s
  déclaration : aucune (durées par défaut)

    CASSÉ AUJOURD'HUI        4
    CONFORME                 1
    PROBABLEMENT HORS SUJET  1
```

Les trois sommes de contrôle du lien de réinitialisation et du jeton sont rouges, le 3DES aussi. Le lien signé avec une clé reste conforme.

La règle est volontairement étroite. Un `crc32()` n'est signalé que s'il est à côté de quelque chose qu'un inconnu voudrait falsifier, un jeton, un lien de réinitialisation, un mot de passe, un secret, une signature, un bon d'achat, lu sur la ligne, dans le nom de la fonction et dans le nom du fichier. Partout ailleurs, il reste muet : vérifier un téléchargement, répartir des sessions entre serveurs, calculer un ETag, c'est exactement ce à quoi sert une somme de contrôle. Le test qui accompagne la correction contient ces trois usages, et il échoue si l'un d'eux devient rouge. Sans lui, nous aurions remplacé un silence par du bruit.

Ce qui n'est pas corrigé, c'est Luhn lui-même. Le bon d'achat accepté sur sa clé de contrôle n'apparaît toujours pas : une boucle, un doublement et un modulo ne se distinguent pas d'un calcul ordinaire, et le reconnaître à sa forme est un chantier à part. En attendant, le rapport le dit, dans la section des angles morts, en toutes lettres :

> Les sommes de contrôle (CRC32, Adler-32) ne sont signalées qu'à côté d'un jeton, d'un lien ou d'un secret. Une clé de Luhn ou un modulo écrits à la main ne le sont jamais : rien ne les distingue d'un calcul ordinaire, et un code qui accepte un numéro sur la foi de son chiffre de contrôle n'apparaît pas ici.

Luhn n'a pas besoin d'être sécurisé. Il a besoin qu'on arrête de lui demander de l'être, et qu'un outil qui prétend faire l'inventaire le dise quand il ne sait pas voir quelqu'un le faire.
