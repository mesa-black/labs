---
title: "Cryptographie : on a posé notre seule question à un vrai dirigeant. Il n'a rien compris."
standfirst: "Notre outil lit un projet, dit jusqu'à quand chaque protection tiendra, et ne demande qu'une chose à l'entreprise. Voici ce qu'il produit, et ce qui s'est passé quand nous avons posé cette question à quelqu'un qui n'est pas informaticien : trois séances, trois échecs, et 986 mots à lire pour répondre à deux questions."
key: la-seule-question-ne-passe-pas
date: 2026-10-08
slug: cryptographie-notre-seule-question
---

Presque tout ce qui protège aujourd'hui les données d'une entreprise repose sur des calculs faciles dans un sens et impraticables dans l'autre. Un calculateur quantique suffisamment puissant rendra le retour possible, et les États ont fixé des dates : les méthodes actuelles seront déconseillées vers 2030, interdites vers 2035.

Ce n'est pas un problème pour 2035, et c'est le point que presque tout le monde manque. Un adversaire n'a pas besoin d'attendre : il lui suffit de **copier aujourd'hui** une sauvegarde ou un flux, et de la garder jusqu'au jour où il pourra l'ouvrir. Autrement dit, une donnée chiffrée ce matin qui doit rester confidentielle au-delà de 2035 est déjà perdue — changer de méthode plus tard protégera ce qui viendra après, pas elle.

[Sablier](https://github.com/mesa-black/sablier) est notre outil pour mettre cette phrase en chiffres sur un projet réel. Ce texte raconte ce qu'il produit, puis l'échec de la seule chose qu'il demande à un humain.

## Ce que l'outil fait

Il lit un dépôt — sans rien exécuter, sans rien envoyer — et relève chaque endroit où le code chiffre, signe ou hache quelque chose : appels de bibliothèques, clés et certificats présents dans l'arborescence, configuration de serveur, scripts de déploiement, dépendances déclarées, et l'infrastructure quand elle est écrite en Terraform. Puis il croise cet inventaire avec la durée pendant laquelle chaque catégorie de données doit rester confidentielle, et rend un verdict par endroit.

Lancé sur un projet d'exemple, ça donne ceci :

```
  /projet — 3 fichiers lus, 7 constats, 0.0 s
  déclaration : /projet/sablier.json

    COMPROMIS                1
    CASSÉ AUJOURD'HUI        1
    SURVEILLER               2
    CONFORME                 2
    PROBABLEMENT HORS SUJET  1

  → /projet/r.html
```

Cinq catégories, et deux qui comptent. Voici le constat rouge, tel que le rapport l'écrit :

> **COMPROMIS** — `deploy/backup.sh:3`
> Chiffré aujourd'hui, à garder confidentiel jusqu'en 2036 — soit 1 an après la péremption de RSA. Une capture faite maintenant sera lisible.

Et celui qui n'a rien à voir avec le quantique, parce qu'un inventaire qui ne parle que de 2035 passe à côté de ce qui est cassé depuis vingt ans :

> **CASSÉ AUJOURD'HUI** — `src/Tokens.php:17`
> Cassé classiquement, indépendamment du quantique. L'échéance était hier.
> *références CVE-2005-4900*

Un inventaire qui ne conclut rien se range dans un dossier, donc le rapport tranche et met dans l'ordre. Le premier élément du plan n'est jamais « migrer » :

> **Décider du sort des données déjà émises.** C'est la décision que personne ne prend, et elle vient avant la migration. Les domaines concernés sont protégés par un algorithme qui ne tiendra pas jusqu'au bout de leur durée de confidentialité : ce qui a déjà été chiffré et transmis est hors de portée d'un correctif. Trois issues, et il faut en choisir une explicitement — re-chiffrer le stock existant, faire tourner les clés et réémettre ce qui peut l'être, ou acter par écrit qu'on accepte le risque. Migrer sans trancher cette question protège les données futures et laisse les anciennes exposées sans que personne ne l'ait décidé.

Il sait aussi lire une fuite à l'envers. Avec une date de compromission, il ne raisonne plus sur ce qu'un adversaire récoltera : il compte ce qui est déjà entre ses mains et pour combien de temps ça continue de nuire.

> **Après la fuite du 29/07/2026** — Ce qui est sorti est déjà entre les mains de quelqu'un. La seule protection qui reste est l'algorithme, et elle a une date de fin.
> *backups* — confidentialité demandée : 10 ans, soit jusqu'en 2036. L'algorithme qui protège ces données périme en 2035. 1 année de ce qui a été volé deviendra lisible, et aucune migration ne la rattrape.
> *session tokens* — protégé par de la cryptographie que le quantique n'atteint pas. Rien ne devient lisible de ce côté.

Le rapport existe en deux versions : une technique, lue à côté d'un éditeur, et un document d'audit numéroté, séparant les faits de l'avis, pour la pièce qu'on produit devant un tiers. Les deux impriment ce qu'ils n'ont pas regardé, parce qu'un inventaire qui tait ses angles morts fabrique de la fausse assurance. Tout tourne sur la machine de qui lance la commande : aucune donnée ne sort, le code est sous licence MIT, et [les rapports d'exemple](https://github.com/mesa-black/sablier/tree/main/examples) sont dans le dépôt.

## La seule chose qu'il ne peut pas deviner

Un verdict ci-dessus dit « à garder confidentiel jusqu'en 2036 ». Ce 2036 ne vient pas du code. Il vient d'une durée que quelqu'un a déclarée : dix ans pour ces sauvegardes.

C'est la charnière de tout l'outil, et aucun logiciel ne peut la deviner. Une session de connexion dure quelques heures, une facture dix ans, un contrat trente — et ce n'est pas une information technique. Alors l'outil la demande, en une question, à quelqu'un qui connaît le métier : *combien de temps ceci doit-il rester secret ?*

Un texte écrit pour ce blog début octobre se terminait sur une phrase inconfortable : tous les outils de ce domaine, le nôtre compris, supposent que cette durée est une information *obtenable*, et personne n'a l'air d'avoir vérifié qu'une entreprise sait l'énoncer. Il finissait en reconnaissant que cette conclusion-là non plus n'avait été validée auprès de personne.

Ce texte n'a jamais paru — il était programmé pour le 2 octobre et nous l'avons retiré la veille, avec un autre, pour des raisons qui ne tiennent pas ici. Sa dernière ligne, elle, a tenu.

Elle l'a été cette semaine. Trois fois, auprès du dirigeant d'une entreprise qui utilise nos outils tous les jours. Le résultat tient en une phrase, la sienne :

> « Je suis désolé mais c'est du charabia pour moi, je ne sais pas ce que ça veut dire, je ne comprends pas les phrases. Bref je suis perdu. »

Ce n'est pas un problème de pédagogie, et ce n'est pas un problème de lui. C'est une mesure sur l'instrument, et elle était chiffrable.

## La mesure

Pour poser la question à distance, l'outil produit un fichier HTML autonome : pas de serveur, pas de réseau, on l'ouvre, on répond, on renvoie un bloc de JSON. Conçu pour les salles où un entretien en direct ne peut pas entrer — réseau fermé, machine isolée.

À la troisième tentative, j'ai compté ce que ce fichier donnait à lire avant de pouvoir répondre. **986 mots.** Pour sept sujets et deux questions par sujet. Avec le mot « empreinte » cinq fois, et « algorithme », « échéance », « régime », « déclaration », « plomberie » sur le chemin.

Le détail qui compte : **la majeure partie de ces 986 mots avait été écrite le jour même**, en corrigeant les deux échecs précédents. À chaque passe, j'avais ajouté un paragraphe par honnêteté — ce que l'outil ne peut pas savoir, pourquoi cette question est posée, d'où vient cette date, ce que la réponse implique. Chacun défendable seul. Tous ensemble, un document que personne hors du métier ne traverse.

La prose arrive un paragraphe justifié à la fois. C'est pour ça qu'elle ne se voit pas.

## Ce que les réponses disaient vraiment

La deuxième séance avait produit un fichier de réponses. Il avait l'air complet : sept sujets, sept réponses, aucune case vide. Il est arrivé avec un commentaire — « j'ai rien compris » — et c'est en le regardant ligne par ligne qu'on voit le vrai problème.

Sept sujets, **sept fois la même durée** : cinq ans. Zéro conservation légale déclarée. Zéro justification écrite. Pas de nom pour dire qui s'engageait. 182 secondes en tout, et le temps par sujet qui s'effondre : 20,8 s, 36,1, 16,8, 15,9, 23,8, **8,9**, 10,6.

Les sept boutons proposés allaient de 0 à 30 ans. Cinq était celui du milieu.

Et ce cinq uniforme est démontrablement faux à deux endroits au moins. Le domaine qu'il a nommé « REX » est du **contenu publié** : sa durée de confidentialité est zéro par construction. Celui qu'il a nommé « Facturation » porte dix ans d'archivage comptable obligatoire — répondu cinq, avec « conservation légale : 0 » juste en face.

**Une partie avait pourtant marché.** Il a renommé les sept sujets dans ses mots : Login, Facturation, Information, REX, Profile, Sécurité, Paramètres. C'est exactement la tâche qu'on lui demandait, et il l'a faite. Le vocabulaire des *données* n'était pas le blocage. Celui des *durées* l'était.

Et les deux dernières questions du formulaire — « une question que vous auriez attendue », « un mot que vous n'avez pas compris » — sont revenues vides. 7,8 secondes dessus. Celui qui ne comprend pas ne remplit pas le champ où le dire.

## Pourquoi c'est pire qu'une absence de réponse

Ce fichier n'était pas vide. Il était **plausible**. Et l'outil, en l'important, affichait « 7 réponses reprises », écrivait une déclaration, et se taisait.

Une déclaration, dans cet outil, est ce qui engage une personne sur un chiffre : le rapport d'audit imprime à côté de chaque durée qui l'a déclarée et quand. Transformer sept clics sur le bouton du milieu en déclaration datée, c'est fabriquer exactement la fausse assurance que le projet passe son temps à dénoncer ailleurs. Mieux vaut aucune déclaration qu'une déclaration blanchie.

Le mode d'échec dangereux de ce genre d'outil n'est donc pas « la personne ne sait pas répondre ». C'est « la personne produit une réponse qui a l'air d'une réponse ».

## Les six corrections

**Les sujets sont nommés par leur endroit, plus par la cryptographie qu'ils contiennent.** Ils étaient regroupés par famille d'algorithmes, ce qui fait qu'un sujet ne pouvait être nommé que d'après une famille : on demandait combien de temps « Chiffrement à clé publique » et « Empreintes de contenu » devaient rester confidentiels. Ce sont des mécanismes, pas des données. Pire, le seul sujet qu'il aurait su traiter — cinq répertoires métier — avait été écrasé dans l'un des deux.

**Les durées sont devenues des conséquences.** Plus de boutons 0/1/3/5/10/20/30, mais quatre phrases : *c'est public, ou sans conséquence* / *ça nous gênerait, le temps que ça passe* / *un client pourrait nous le reprocher, ou rompre* / *on nous le reprocherait des années, ou ça finirait au tribunal*. L'arithmétique est à l'outil.

**Et ces phrases s'ancrent sur l'histoire du projet.** Là où le dépôt sait quand il a commencé — la plus ancienne date d'auteur de son journal git — les choix nomment des années vécues : *ce qu'on écrivait en 2023 serait encore gênant*, *même ce qu'on écrivait en 2019, au début*. Le choix le plus long vaut alors l'âge du projet, pas un chiffre rond. Personne n'estime bien sept ans vers l'avant ; tout le monde sait dire si les factures de la première année comptent encore.

**986 mots sont devenus 235, et un test échoue au-delà de 260.** Un budget, pas une relecture : rien d'autre n'attrape de la prose qui arrive un paragraphe à la fois. Un second test échoue si un mot de métier revient sur le chemin du lecteur. Tout ce qui a été retiré est toujours écrit — dans le rapport d'audit, lu par qui doit peser les chiffres, pas par qui en fournit un. Je confondais les deux lecteurs.

**Une question entière a disparu : le régime réglementaire.** Personne hors du domaine ne choisit entre NIST IR 8547, CNSA 2.0 et un avis de l'ANSSI. La question affichait cinq lignes d'acronymes — puis des échéances 2030 et 2035 juste sous l'année que la personne venait de donner comme fin de vie de l'application. C'est le choix de l'auditeur, dans un fichier versionné, et l'outil le lui rappelle quand il est resté au défaut.

**L'outil signale désormais une réponse uniforme.** Des durées toutes identiques, aucune justification, personne nommé : il le dit, nomme les chiffres, et rappelle qu'un contenu publié et dix ans de comptabilité ne partagent pas une durée. Il signale, il ne refuse pas — juger si ces réponses valent quelque chose appartient à qui a mené la séance.

## Ce qu'on a refusé de faire

**Pré-remplir la réponse.** C'était la correction la plus tentante : proposer une durée par catégorie, et demander une confirmation. Un oui/non sur une proposition concrète est cognitivement beaucoup plus facile qu'une durée à produire.

C'est aussi le moyen le plus sûr d'obtenir une déclaration que personne n'a lue. Un lecteur fatigué accepte ce qui est dans la case, et la case se retrouve signée. Le champ qui nomme la donnée n'est plus pré-rempli du tout, pour la même raison : il arrivait avec un nom de famille d'algorithme, et le remplir avec le nom du répertoire — « Entity » — n'aurait pas été mieux.

## Ce que ça a donné

- **Une hypothèse partagée par tout le domaine, testée** : une entreprise ne sait pas énoncer spontanément la durée de confidentialité de ses données. Pas « pas encore » : pas comme on la lui demandait.
- **Un mode d'échec nommé** : la réponse plausible. Un formulaire qui n'oblige pas à réfléchir produit du chiffre, pas de l'information.
- **Trois échecs sur la même personne**, ce qui est une donnée sur l'instrument et pas sur elle.
- **751 mots retirés** d'un document que j'avais écrit en croyant être honnête.

## Bonnes pratiques

- Mesurer le document avant de le réécrire. « Trop technique » est une impression ; 986 mots et « empreinte » cinq fois est un défaut qu'on peut corriger.
- Mettre un budget là où la dérive est lente. Un test qui compte les mots attrape ce qu'aucune relecture n'attrape, parce que chaque paragraphe ajouté est défendable au moment où on l'ajoute.
- Distinguer les lecteurs. Les réserves d'un outil honnête vont au rapport, lu par qui pèse les chiffres — pas au formulaire, rempli par qui en fournit un.
- Demander une conséquence quand on veut une durée. Les gens savent ce que ça leur coûterait ; ils ne savent pas convertir ça en années.
- Regarder les temps par question. La courbe décroissante du temps passé dit qu'on a perdu la personne, et elle le dit avant qu'elle le dise.

## Points de vigilance

- **Un échantillon de un.** Un dirigeant, une entreprise, un domaine. Les six corrections sont justifiées par une observation, pas par une étude.
- Les intitulés de sujets restent des mots de code — « Billing », « Entity ». Les traduire en vocabulaire métier demanderait d'inventer ce que l'outil ne sait pas ; il montre l'endroit et demande le nom.
- **Le fichier autonome n'était pas conçu pour ça.** Il existe pour les réseaux fermés, pas pour quelqu'un seul devant sa boîte mail. Trois échecs d'affilée disent surtout qu'on a utilisé l'instrument prévu pour une salle isolée là où un entretien de vingt minutes, côte à côte, aurait reformulé de vive voix ce qu'aucune phrase écrite ne rattrape.
- Rien ne garantit que la quatrième tentative passera. Ce qui est garanti, c'est qu'on saura la mesurer.
