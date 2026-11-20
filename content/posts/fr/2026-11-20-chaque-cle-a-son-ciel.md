---
title: "Chaque clé a son ciel"
standfirst: "L'idée de départ était d'inventer une cryptographie fondée sur les constellations. Elle ne tient pas, et nous expliquons pourquoi. Ce qui en est resté tient : Stellar dessine la clé publique d'un site comme une constellation qui porte un nom, pour qu'un humain remarque le jour où elle change. Puis nous avons fait annoncer ce ciel par le DNS de nos propres sites, signé, et suivi à chaque renouvellement de certificat. Voici ce que ça prouve, et surtout ce que ça ne prouve pas."
key: chaque-cle-a-son-ciel
date: 2026-11-20
slug: chaque-cle-a-son-ciel
---

Tout est parti d'une phrase : *et si on créait un nouveau modèle de cryptographie, comme RSA, mais fondé sur les constellations ? Il faudra des années-lumière avant qu'une constellation disparaisse à nos yeux.*

C'est une idée de rêveur, et nous y tenons. On se repère aux étoiles depuis toujours : les marins pour tenir un cap, les enfants pour retrouver la Grande Ourse. Qu'on veuille confier à ce ciel-là ce que nous avons de plus fragile, nos secrets, n'a rien d'absurde. C'est le genre d'idée qu'on a en levant les yeux, pas en lisant une norme, et les projets qui commencent ainsi ne sont pas les plus mauvais.

L'image est belle. Elle ne fait pas un système de chiffrement, et il vaut mieux dire pourquoi avant de raconter ce que nous avons construit à la place.

## Pourquoi les étoiles ne chiffrent rien

Un système à clé publique repose sur un problème que tout le monde peut poser et que personne ne sait résoudre à l'envers. Pour [RSA](https://observatoire.mesa.black/comprendre#g-rsa), c'est retrouver deux grands nombres premiers à partir de leur produit. La sécurité vient de là : d'un calcul facile dans un sens, hors de portée dans l'autre.

Le ciel est l'inverse d'un secret. La position des étoiles est la donnée la plus publique qui soit, mesurée et publiée depuis des siècles. On ne peut rien y cacher, et aucun problème difficile ne s'y trouve. Qu'une constellation dure des millions d'années ne change rien : la durée d'un objet n'a jamais protégé une clé.

Nous avons donc écarté l'idée d'une « cryptographie stellaire ». Inventer son propre chiffrement est par ailleurs la première chose que ce métier apprend à ne pas faire.

Mais l'intuition contenait autre chose, de juste : **un humain reconnaît un ciel. Il ne reconnaît pas une suite de caractères.**

## Le problème que personne ne regarde

Un site web prouve qui il est avec une clé publique. Cette clé se résume en une empreinte, par exemple :

```
SHA256:9f3ntWkWWH7QVXvTp7oFXjDeN34LcvBOGX22U4Qu2ps
```

Personne ne compare ça. Personne ne s'en souvient d'une visite à l'autre. Le jour où la clé d'un site change, parce qu'un certificat a été renouvelé ou parce que quelqu'un d'autre répond à sa place, rien ne le signale à un œil humain.

L'idée de dessiner une empreinte n'est pas neuve, et nous ne prétendons pas l'avoir eue. OpenSSH sait afficher un petit dessin de la clé d'un serveur depuis 2008 (l'option `VisualHostKey`, analysée dans [« The drunken bishop »](http://www.dirk-loss.de/sshvis/drunken_bishop.pdf), en anglais). Les avatars géométriques de certains sites partent du même principe. Ce qui manque à ces dessins, c'est ce qui permet d'en parler : un nom.

## Ce que fait Stellar

[Stellar](https://stellar.mesa.black) prend l'empreinte d'une clé publique et en tire, toujours de la même façon, une constellation :

- de sept à douze étoiles principales, chacune avec une position, un éclat et une couleur ;
- des traits qui les relient en une seule figure ;
- un fond d'étoiles plus faibles ;
- et un nom, par exemple *Zijizia Vudensis*.

La même clé donne toujours le même ciel. Une clé différente, même d'un seul bit, en donne un autre, sans ressemblance. Le calcul n'a rien de secret : l'empreinte passe par [SHAKE256](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.202.pdf), une fonction de hachage standard, et chaque étoile est tirée du résultat. L'algorithme est écrit dans le [dépôt](https://github.com/mesa-black/stellar), avec trente-deux exemples de référence pour qui voudrait le réécrire dans un autre langage. Nous l'avons d'ailleurs fait une fois, en PHP, pour [Sablier](https://github.com/mesa-black/sablier).

Stellar ne chiffre rien et ne remplace rien. C'est une façon de **regarder** une empreinte.

### Des noms inventés, et pourquoi

Les noms sont fictifs. Aucun n'est celui d'une vraie constellation, et les dessins ne correspondent à aucune non plus.

Les vrais noms ne conviendraient pas. Il existe quatre-vingt-huit constellations officielles : des clés sans rapport porteraient le même nom en permanence, et fabriquer une clé qui s'appelle *Orion* comme la vôtre demanderait quelques dizaines d'essais. Le schéma inventé donne environ 8,4 milliards de noms. Ils sont construits pour sonner comme le latin des astronomes, parce que le but est de pouvoir les dire à voix haute : « chez moi, ton site s'appelle Zijizia Vudensis. Et chez toi ? »

## Le même ciel partout où la clé apparaît

Nous n'avons inventé aucun format d'empreinte. Stellar dessine celles qui existent déjà :

- pour une clé SSH, l'empreinte que donne `ssh-keygen -l` ;
- pour un site web, le SHA-256 de la clé publique de son certificat.

La conséquence est pratique : le ciel qu'affiche le site, celui que dessine la ligne de commande et celui qu'un collègue obtient sur sa machine sont le même, parce qu'ils partent des mêmes trente-deux octets.

```
$ stellar -host stellar.mesa.black
Name:        Zijizia Vudensis
Fingerprint: SHA256:9f3ntWkWWH7QVXvTp7oFXjDeN34LcvBOGX22U4Qu2ps
Key:         stellar.mesa.black:443 (X.509 certificate)
Certificate: ECDSA P-256, until 2027-02-18, Let's Encrypt YE2
Connection:  TLS 1.3, X25519MLKEM768 (post-quantum hybrid)
```

Dans le terminal, la constellation est dessinée au-dessus de ces lignes. Les rapports signés de Sablier portent eux aussi le ciel de leur clé de signature, sous le sceau. Ce n'est pas le même que celui du site qui les publie, et c'est normal : ce sont deux clés différentes, l'une signe un rapport, l'autre un certificat. La question nous a été posée dès le premier jour, et le rapport imprime depuis l'empreinte complète à côté du dessin pour qu'on puisse vérifier laquelle on regarde.

## « Un ciel qui change tous les deux mois ne sert à rien »

C'est l'objection sérieuse, et elle nous a occupés plus longtemps que le dessin.

Le site retient, dans votre navigateur et nulle part ailleurs, le ciel que chaque nom montrait à votre dernière visite. Si le ciel a changé, il le dit. Mais nos certificats sont renouvelés tous les deux mois, avec une nouvelle clé à chaque fois : nous ne gardons aucune clé plus longtemps que ne vit un certificat. Le ciel de nos sites change donc six fois par an, légitimement. Un signal qui se déclenche six fois par an pour rien est un signal qu'on apprend à ignorer.

Il fallait donc autre chose que la mémoire du visiteur : **que le propriétaire du site dise lui-même quel ciel attendre.**

## Le ciel que le propriétaire annonce

Ce mécanisme existe depuis 2012 et nous n'avons rien eu à inventer. Un domaine peut publier dans son DNS un enregistrement `TLSA` ([DANE, RFC 6698](https://www.rfc-editor.org/rfc/rfc6698)) qui dit quelle clé son site doit présenter. La forme recommandée, `3 1 1`, contient le SHA-256 de la clé publique du certificat.

C'est exactement l'empreinte dont Stellar tire un ciel. « Le ciel annoncé par le propriétaire » n'est donc pas un format à nous : c'est un enregistrement standard, lu comme un ciel. Stellar compare ce que le site montre à ce que son DNS annonce, et dit si c'est la même clé, une autre, ou si le domaine n'annonce rien.

Encore fallait-il le faire chez nous. Trois pièces, posées le 20 novembre 2026 :

**La zone est signée.** Sans [DNSSEC](https://www.rfc-editor.org/rfc/rfc4033), un enregistrement `TLSA` ne vaut pas plus que le DNS qui le transporte, c'est-à-dire pas grand-chose. `mesa.black` est signé, et les résolveurs qui valident marquent ses réponses comme authentifiées.

**L'annonce suit la clé.** Un enregistrement écrit à la main serait faux dès le renouvellement suivant. Une tâche tourne donc toutes les cinq minutes dans notre cluster : elle lit la clé que chaque site sert, comme le ferait un visiteur, et corrige l'enregistrement s'il diffère. Elle ne lit jamais les clés privées. C'est la commande `stellar announce`, publiée avec le reste.

**Seul notre compte peut obtenir un certificat.** Deux enregistrements [`CAA`](https://www.rfc-editor.org/rfc/rfc8659) n'autorisent qu'une autorité, pour un seul compte et une seule méthode de validation ([RFC 8657](https://www.rfc-editor.org/rfc/rfc8657)), et interdisent les certificats génériques.

Nous n'avons pas attendu le prochain renouvellement pour savoir si l'ensemble tenait. Nous en avons provoqué un, sur le site de Stellar lui-même. Le certificat a été émis sous la nouvelle règle `CAA`, le ciel du site est passé de *Kamubum Haparis* à *Zijizia Vudensis*, et environ trois minutes plus tard le DNS annonçait la nouvelle clé.

## Ce que ça ne prouve pas

C'est la moitié du sujet, comme d'habitude.

- **Le nom seul ne prouve rien.** Il porte environ 33 bits. Quelqu'un qui cherche exprès une clé portant le même nom que la vôtre la trouve en quelques minutes de calcul. Le nom sert à parler d'un ciel, pas à l'accepter.
- **Le dessin non plus, face à quelqu'un de décidé.** Un œil compare moins de bits que n'en contient l'empreinte. Qui peut fabriquer beaucoup de clés peut en chercher une dont le ciel ressemble au vôtre. Le dessin sert à remarquer un changement ; quand ça compte, on compare l'empreinte complète.
- **Nous n'avons mené aucune étude.** Personne n'a mesuré à quel point des gens distinguent deux de ces constellations. Tant que ce n'est pas fait, toute affirmation sur leur lisibilité serait une opinion.
- **Le site voit la clé depuis notre serveur, pas depuis chez vous.** Quelqu'un qui intercepterait votre propre connexion n'est pas visible de là. Pour savoir ce que votre machine reçoit, il faut lancer la commande chez vous.
- **Stellar ne valide pas DNSSEC lui-même.** Il demande au résolveur de la machine s'il l'a fait, et le répète. « Signé » veut dire : ce résolveur a vérifié. Sur un réseau dont le résolveur ne valide pas, Stellar dit qu'il ne sait pas, et il a raison.
- **Aucun navigateur n'applique DANE.** L'annonce ne bloque personne : elle permet à qui veut vérifier de le faire. C'est aussi pour ça que notre fenêtre de retard est acceptable : après un renouvellement, le DNS annonce l'ancienne clé pendant dix minutes au plus.
- **Le DNS reste un tiers.** DNSSEC déplace la confiance vers le registre du domaine et la racine. C'est une seconde route, indépendante des autorités de certification, ce qui est tout son intérêt. Ce n'est pas l'absence de confiance.

## Le vérifier sans nous

Rien de ce qui précède n'a besoin de Stellar. L'empreinte de la clé qu'un site présente :

```
$ openssl s_client -connect stellar.mesa.black:443 -servername stellar.mesa.black </dev/null 2>/dev/null \
    | openssl x509 -pubkey -noout \
    | openssl pkey -pubin -outform der \
    | openssl dgst -sha256
f5fde7b56916587ed0557bd3a7ba055e30de377e0b72f04e197db653842eda9b
```

Et ce que son propriétaire annonce :

```
$ dig +short TLSA _443._tcp.stellar.mesa.black
3 1 1 F5FDE7B56916587ED0557BD3A7BA055E30DE377E0B72F04E197DB653 842EDA9B
```

Les deux valeurs sont les mêmes. Relevé le 20 novembre 2026 ; elles auront changé au prochain renouvellement, ensemble si tout fonctionne. Avec `dig +dnssec` auprès d'un résolveur qui valide, le drapeau `ad` dit en plus que la réponse est signée.

Stellar n'ajoute qu'une chose à ces deux commandes : un dessin et un nom, pour la personne qui ne les lancera jamais.

## L'essayer

- **Le site** : [stellar.mesa.black](https://stellar.mesa.black). On y tape un nom de domaine, une clé publique ou une empreinte.
- **La ligne de commande** : un binaire par plate-forme sur la [page des versions](https://github.com/mesa-black/stellar/releases), sans dépendance. `stellar -host example.com`, `stellar ~/.ssh/id_ed25519.pub`.
- **Chez vous** : le site est le même binaire (`stellar serve`), dans une image de conteneur qui ne contient rien d'autre.

Le code est sous licence MIT.

## Bonnes pratiques

- **Comparez l'empreinte quand ça compte.** Le ciel fait remarquer un changement, l'empreinte le prouve.
- **N'acceptez jamais une clé sur son nom.** Dites le nom, regardez le dessin, vérifiez l'empreinte.
- **Annoncez votre clé, et faites suivre l'annonce.** Un `TLSA` qui n'est pas mis à jour à chaque renouvellement devient faux, et un enregistrement faux est pire qu'aucun.
- **Signez la zone avant d'y écrire quoi que ce soit d'important.** Sans DNSSEC, l'annonce vaut ce que vaut le réseau entre vous et votre résolveur.
- **Surveillez de l'extérieur.** Notre tâche de suivi peut échouer en silence. Une seconde, chaque jour, vérifie ce qu'un inconnu verrait, et écrit quand c'est faux.

## Points de vigilance

- Un `CAA` trop strict ne se voit qu'à la prochaine émission. Après l'avoir écrit, renouvelez un certificat exprès.
- Changer de serveurs de noms sans retirer d'abord la signature du registre rend un domaine injoignable.
- Un jeton d'API qui modifie votre DNS est une clé de votre domaine. Le nôtre est limité à une zone et il expire.
- Chercher un nom dans les journaux publics de certificats envoie ce nom à un tiers. Le site ne le fait que si vous le demandez, et le dit.
- Un dessin rassure vite. C'est sa qualité et son danger : un ciel familier n'est pas une vérification.

## Références

- **DANE** : [RFC 6698](https://www.rfc-editor.org/rfc/rfc6698) et les recommandations d'usage de la [RFC 7671](https://www.rfc-editor.org/rfc/rfc7671) (en anglais).
- **DNSSEC** : [RFC 4033](https://www.rfc-editor.org/rfc/rfc4033) (en anglais).
- **CAA** : [RFC 8659](https://www.rfc-editor.org/rfc/rfc8659), et la [RFC 8657](https://www.rfc-editor.org/rfc/rfc8657) pour le compte et la méthode de validation (en anglais).
- **SHAKE256** : [FIPS 202](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.202.pdf) (en anglais).
- **Le dessin des clés dans OpenSSH** : [« The drunken bishop »](http://www.dirk-loss.de/sshvis/drunken_bishop.pdf), Loss, Limmer et von Gernler, 2009 (en anglais).
- **Notre Observatoire post-quantique** : [RSA](https://observatoire.mesa.black/comprendre#g-rsa), [la fonction de hachage](https://observatoire.mesa.black/comprendre#g-hachage).
- **Chez nous** : [Stellar](https://stellar.mesa.black) et [son code](https://github.com/mesa-black/stellar), [Sablier](https://github.com/mesa-black/sablier), et [l'inventaire de ce site](/audit/report.html).
