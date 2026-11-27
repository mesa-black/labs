---
title: "Ce que votre machine voit"
standfirst: "Quand vous ouvrez un site en https, il prouve qui il est avec une clé. Stellar dessine cette clé pour qu'on remarque le jour où elle change. Il restait un trou : notre site montrait la clé que notre serveur reçoit, pas celle que vous recevez. Voici comment nous l'avons comblé, expliqué pas à pas, avec ce que nous avons cassé en chemin."
key: ce-que-votre-machine-voit
date: 2026-11-26
slug: ce-que-votre-machine-voit
---

Cet article fait suite à [« Chaque clé a son ciel »](/chaque-cle-a-son-ciel/). Il se lit sans l'avoir lu : nous reprenons les notions au fur et à mesure.

## D'abord, de quelle clé parle-t-on ?

Quand votre navigateur affiche un cadenas, il s'est passé ceci : le site lui a présenté un **certificat**, une sorte de pièce d'identité numérique. Dans ce certificat se trouve une **clé publique**, un très grand nombre que le site est le seul à pouvoir utiliser dans l'autre sens, grâce à une clé privée qu'il garde pour lui. Tant que le site prouve qu'il détient la clé privée correspondante, votre navigateur sait qu'il parle bien à lui, et tout ce qui circule est chiffré pour lui seul.

Cette clé publique est trop longue pour être lue. On en calcule donc un résumé, l'**empreinte** : une suite d'une cinquantaine de caractères, toujours la même pour la même clé, et différente dès qu'un seul bit de la clé change. Deux empreintes identiques, c'est la même clé.

Personne ne compare cinquante caractères à l'œil. C'est le point de départ de [Stellar](https://stellar.mesa.black) : il transforme l'empreinte en une constellation qui porte un nom. Même clé, même ciel. Clé différente, ciel sans rapport. On ne lit pas un ciel, on le reconnaît.

## Le trou que nous avions laissé

Le danger qu'on cherche à voir s'appelle une **interception**. Quelqu'un se place entre vous et le site, sur un réseau wifi par exemple, et se fait passer pour le site. Il vous présente *sa* clé au lieu de celle du site, déchiffre ce que vous envoyez, puis le transmet au vrai site comme si de rien n'était.

Une interception, c'est donc deux clés pour un même site : la vraie, que le site sert au reste du monde, et la fausse, qu'on vous sert à vous.

Or notre site ne regardait que depuis un seul endroit. Quand vous lui demandez le ciel de `exemple.fr`, c'est *notre serveur* qui va chercher la clé de `exemple.fr`, depuis notre centre de données. Si quelqu'un vous intercepte, vous, dans votre café, notre serveur n'en voit rien : il reçoit la vraie clé et vous dessine un ciel rassurant. L'article précédent le disait dans sa liste de limites. C'était la plus gênante.

## Regarder depuis deux endroits

Pour voir une interception, il faut lire la clé **là où vous êtes**, puis la comparer à celle qu'on voit d'ailleurs.

Un site web ne peut pas faire la première moitié : une page n'a pas le droit de lire le certificat de la connexion qui l'a apportée. Une **extension** de navigateur, ce petit programme qu'on ajoute au navigateur, le peut. Mais dans un seul navigateur : Firefox donne le certificat de chaque page à ses extensions, Chrome et Safari non.

Nous avons donc écrit une extension pour Firefox. Elle fait trois choses.

**Elle dessine le ciel de la page**, à partir de la clé que votre propre machine a reçue. Le calcul se fait dans votre navigateur, sans rien demander à personne.

**Elle se souvient.** Elle retient le ciel que chaque site montrait à votre dernière visite, et vous prévient s'il a changé. Un changement n'est pas forcément une attaque : un site renouvelle son certificat tous les deux ou trois mois, souvent avec une nouvelle clé. Mais c'est une raison de regarder.

**Sur un clic, elle demande à notre serveur** quelle clé il reçoit, lui, du même site. Si les deux clés sont identiques, ce que vous voyez correspond à ce que voit le reste du monde. Si elles diffèrent, il y a quelque chose à comprendre.

Rien ne quitte votre machine avant ce clic. Quand vous cliquez, deux choses partent : le nom du site, et l'empreinte de sa clé. L'empreinte est publique par nature, n'importe qui peut la lire en visitant le site. Le nom du site, lui, dit à notre serveur où vous êtes ; l'extension le déclare à l'installation, et c'est pour cela qu'elle ne le fait jamais sans vous.

Un mot sur la cuisine. Pour que l'extension dessine exactement le même ciel que le site, il a fallu réécrire le calcul une troisième fois. Stellar est écrit en Go. Notre outil d'inventaire, [Sablier](https://github.com/mesa-black/sablier), est écrit en PHP et dessine le ciel de ses propres clés de signature sur ses rapports : c'était la deuxième écriture. L'extension, elle, vit dans un navigateur, donc en JavaScript. Trois programmes dans trois langages qui doivent tomber sur le même dessin, au trait près. Le dépôt contient trente-deux ciels de référence, et chaque écriture est refusée si elle en dessine un seul autrement.

## Comparer une clé, à la main

La question que pose l'extension, vous pouvez la poser sans elle. Imaginons qu'un collègue vous dicte au téléphone l'empreinte de la clé de son serveur, ou vous l'envoie sur une carte de visite. Vous voulez savoir si le site que vous avez sous les yeux présente bien cette clé-là.

Sous le ciel d'un site, Stellar accepte maintenant la clé qu'on vous a donnée, sous n'importe quelle forme courante, et répond par oui ou par non : c'est la clé que ce site sert, ou ce ne l'est pas.

À l'écran, six signes défilent comme une roulette et s'arrêtent l'un après l'autre, verts quand ils concordent, rouges sinon. C'est agréable à regarder, et il faut dire ce que c'est : une **image de la réponse**, pas la réponse. La réponse vient des deux empreintes, comparées en entier par le serveur.

La différence se mesure en **bits**, l'unité de ce qu'il faut deviner pour tricher. Les six signes en portent 36 : il existe environ 54 milliards de combinaisons, ce qui paraît énorme et reste à la portée de quelqu'un de décidé, avec du matériel loué. Une empreinte en porte 256 : un nombre de possibilités qu'aucune machine ne parcourra jamais. Deux clés différentes peuvent donc avoir les six mêmes signes. Dans ce cas la page affiche six signes verts, refuse quand même, et explique pourquoi.

Dernier garde-fou : si vous collez par erreur une clé **privée**, celle qui ne doit jamais quitter son serveur, la page la refuse avant de l'envoyer et vide le champ.

## Six signes et une carte

Ces six signes, nous les appelons la **porte**. Chaque clé en tire six, dans un ordre précis, d'un catalogue de soixante-quatre dessins commun à tous. C'est une seconde façon de désigner une clé : moins précise qu'une empreinte, mais six dessins se dictent et se retiennent mieux que cinquante caractères.

### Pourquoi si peu de bits ?

On pourrait s'étonner : 36 bits pour la porte, 33 pour le nom d'un ciel, quand l'empreinte en porte 256. Ce n'est pas une limite technique, c'est un choix, et il vaut la peine d'être expliqué.

**D'où vient le chiffre.** Le premier signe se choisit parmi 64, le deuxième parmi les 63 restants, et ainsi de suite jusqu'au sixième. Cela fait 64 × 63 × 62 × 61 × 60 × 59, environ 54 milliards de portes possibles. Il faut 36 bits pour compter jusque-là.

**Pourquoi ne pas en mettre plus.** Chaque bit ajouté se paie en confort. Douze signes au lieu de six donneraient 70 bits, mais plus personne ne dicte ni ne retient douze dessins. À l'autre bout, l'empreinte complète est imbattable, et c'est justement elle que personne ne lit. Entre les deux, il faut choisir ce qu'un humain peut réellement manipuler. Six signes, c'est ce qui nous a paru raisonnable à dicter et à comparer ; c'est un jugement, pas une mesure.

**Ce que cela impose.** Un outil qui ne porte que 36 bits ne doit jamais décider seul. La porte et le nom servent à *remarquer* un changement et à *désigner* une clé dans une conversation : « chez moi, le site s'appelle Jilajix Figensis, et chez toi ? ». Ils ne servent pas à *accepter* une clé. C'est pour cela que la comparaison décrite plus haut se fait sur les empreintes entières, et que les signes n'en sont que l'image.

On pourrait monter : huit signes tirés d'un catalogue de 256 donneraient 64 bits, hors de portée d'un attaquant ordinaire. Nous ne l'avons pas fait, parce qu'un catalogue de 256 dessins que personne ne distingue ne vaudrait pas mieux qu'une empreinte que personne ne lit. Et nous n'avons pas encore mesuré ce que des gens distinguent vraiment.

Nous en avons aussi tiré une carte en trois dimensions : les soixante-quatre signes posés sur une sphère, les six de la porte reliés deux par deux, et la clé placée au point le plus proche des trois lignes. On peut y poser deux sites et voir la distance qui les sépare. La carte est jolie et n'apporte aucune information de plus que les six signes. C'est écrit dessous.

## Ce que nous avons cassé

**Nous avons publié un jeu.** La première version invitait à « composer la porte » en cliquant les signes un par un, avec des indices quand on se trompait. C'était amusant et hors sujet : un site qui parle de sécurité n'a pas à proposer une devinette dont la solution est affichée juste au-dessus. Nous l'avons retiré le lendemain, au profit de la comparaison décrite plus haut, qui garde l'animation et répond à une vraie question.

**Nous avons fait tomber le site.** Stellar tourne volontairement dans très peu de mémoire, 64 Mo, une fraction de ce que consomme un seul onglet de navigateur. Le jour où nous avons ajouté le téléchargement du ciel en image, dessiner la première a demandé 70 Mo. Le système a arrêté le programme, deux fois de suite. Deux minutes d'indisponibilité, provoquées par notre propre essai. Depuis, la mémoire se mesure avant la mise en ligne, et un test automatique échoue si un dessin dépasse sa part.

**Nous avons verrouillé notre propre navigateur.** Un site peut dire au navigateur : « reviens toujours en https, jamais en clair ». C'est une bonne protection, et le navigateur s'en souvient pendant un an. Nous l'avons activée, y compris, par erreur, sur la copie de travail qui tourne en clair sur la machine du développeur. Le navigateur a obéi : il exigeait du https d'un programme qui n'en parlait pas, et n'affichait plus rien. Le site ne donne plus cette consigne qu'à ceux qui l'atteignent sous sa vraie adresse.

**Un test de charge a trouvé ce que personne n'avait vu.** Un test de charge consiste à envoyer beaucoup de demandes en même temps pour voir ce qui cède. Trois mille demandes, cinquante à la fois : toutes les réponses étaient justes, mais une sur cent mettait dix secondes. Quand plusieurs visiteurs demandaient la même image au même instant, chacun attendait son tour, puis la redessinait au lieu de prendre celle que le premier venait de produire. Après correction, la même réponse arrive en moins d'une demi-seconde.

**Une phrase affichait son propre accident.** Pendant quelques heures, le paragraphe qui explique la comparaison a montré à tous les visiteurs un morceau de code à la place du nom du site. Aucun contrôle ne lisait ce paragraphe. Un test ouvre désormais chaque sorte de page, dans les trois langues, et refuse la moindre trace de ce genre.

**Aucun test n'ouvrait le site dans un navigateur.** À chaque modification, des contrôles automatiques vérifient que rien n'est cassé. Ils lisaient le code du site, pas ce qu'un navigateur en fait : l'animation, la mémoire des visites, le refus des clés privées auraient pu casser sans que rien ne s'allume. Les contrôles ouvrent maintenant le site dans un vrai Firefox, sans fenêtre, et y agissent comme un visiteur : douze vérifications à chaque modification.

## Ce que ça attrape

Après une liste de casseroles, il faut dire à quoi tout cela sert. La comparaison entre ce que votre machine reçoit et ce que notre serveur reçoit attrape **toute interception proche de vous**. Ce sont, de loin, les plus courantes :

- **Un wifi public ou une box compromise.** Celui qui tient le réseau se place entre vous et le site. Votre machine reçoit sa clé ; notre serveur, qui ne passe pas par ce réseau, reçoit la vraie.
- **Un proxy d'entreprise.** Beaucoup d'organisations déchiffrent le https de leurs salariés pour l'inspecter, puis le rechiffrent avec leur propre clé. C'est légal et souvent annoncé, rarement compris. L'extension le montre sans ambiguïté : le ciel que vous voyez n'est pas celui du site.
- **Un antivirus ou un contrôle parental** qui fait la même chose sur votre propre machine.
- **Un logiciel malveillant** qui a installé sa propre autorité de certification, pour que le cadenas reste vert pendant qu'il lit tout.

Dans ces quatre cas, le navigateur affiche son cadenas habituel et rien ne semble anormal. C'est précisément là qu'un second point de vue est utile : deux ciels différents pour un même site, visibles en un clic.

À cela s'ajoute la mémoire de l'extension. Même sans rien demander à notre serveur, elle vous dit qu'un site ne présente plus la clé d'hier. C'est le principe qui protège les connexions SSH depuis trente ans : on fait confiance à la première rencontre, et on s'inquiète du changement.

## Ce que ça ne prouve pas

Ces limites sont réelles. Elles n'annulent pas ce qui précède, elles en dessinent le bord.

- **Une différence n'est pas toujours une interception.** C'est la limite la plus gênante en pratique. Un très grand site répartit ses visiteurs sur de nombreux serveurs, qui peuvent avoir chacun leur certificat et leur clé. Sur ces sites-là, deux ciels différents peuvent être parfaitement normaux. Sur un site de taille ordinaire, qui n'a qu'une clé, c'est beaucoup plus parlant. Dans les deux cas, une différence est une raison de regarder de près, pas un verdict. Pour lever ce doute, Stellar propose alors de chercher la clé que vous voyez dans les journaux publics où tout certificat émis par une autorité est inscrit. Si elle y figure pour ce nom, c'est l'une des clés du site. Si elle n'y figure pas, c'est sérieux : le certificat d'un intercepteur ou d'un proxy d'entreprise n'y est jamais inscrit. Cette recherche envoie le nom du site à un service tiers, donc elle ne se fait que sur demande.
- **Un intercepteur placé près du site échappe à la comparaison.** S'il se trouve sur le chemin de tout le monde, chez l'hébergeur par exemple, votre machine et notre serveur reçoivent la même fausse clé. C'est rare, cela demande d'autres moyens que de tenir un wifi, et c'est ce que traite la clé annoncée et signée par le propriétaire dans son DNS, le sujet de l'article précédent. Les deux mécanismes se complètent : l'un regarde près de vous, l'autre près du site.
- **Notre serveur apprend le nom du site** quand vous cliquez. C'est le prix de la comparaison, et la raison pour laquelle elle n'a jamais lieu sans vous.
- **Un seul navigateur.** Tant que les autres ne donnent pas le certificat à leurs extensions, il n'y a rien à adapter.
- **L'extension n'est pas encore dans le catalogue de Mozilla.** Elle s'installe depuis le dépôt.
- **Les signes ne remplacent pas l'empreinte**, pour les raisons données plus haut.

## Sources

- **Chez nous** : [Stellar](https://stellar.mesa.black), [son code et l'extension](https://github.com/mesa-black/stellar), [Sablier](https://github.com/mesa-black/sablier), et l'article précédent, [« Chaque clé a son ciel »](/chaque-cle-a-son-ciel/).
