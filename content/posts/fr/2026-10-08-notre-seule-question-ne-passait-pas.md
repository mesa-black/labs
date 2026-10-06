---
title: "On a posé notre seule question à un vrai dirigeant. Il n'a rien compris."
standfirst: "Trois séances, trois échecs, et une mesure : 986 mots à lire pour répondre à deux questions. Ce que les réponses revenues disent vraiment, pourquoi une réponse plausible est pire qu'une absence de réponse, et les six corrections que ça a imposées."
key: la-seule-question-ne-passe-pas
date: 2026-10-08
slug: notre-seule-question-ne-passait-pas
---

Le 2 octobre, un texte publié ici se terminait sur une phrase inconfortable : tous les outils de ce domaine, le nôtre compris, supposent que la durée de confidentialité des données est une information *obtenable*, et personne n'a l'air d'avoir vérifié qu'une vraie entreprise sait l'énoncer. Il finissait en reconnaissant que cette conclusion-là non plus n'avait été validée auprès de personne.

Elle l'a été cette semaine. Trois fois, auprès du dirigeant d'une entreprise qui utilise nos outils tous les jours. Le résultat tient en une phrase, la sienne :

> « Je suis désolé mais c'est du charabia pour moi, je ne sais pas ce que ça veut dire, je ne comprends pas les phrases. Bref je suis perdu. »

Ce n'est pas un problème de pédagogie, et ce n'est pas un problème de lui. C'est une mesure sur l'instrument, et elle était chiffrable.

## La mesure

[Sablier](https://github.com/mesa-black/sablier) lit un projet, recense ce qui y est chiffré ou signé, et pose une seule question par domaine de données : *combien de temps ceci doit-il rester secret ?* La question est volontairement non technique, parce que la réponse est métier.

Pour la poser à distance, l'outil produit un fichier HTML autonome : pas de serveur, pas de réseau, on l'ouvre, on répond, on renvoie un bloc de JSON. Conçu pour les salles où un entretien en direct ne peut pas entrer — réseau fermé, machine isolée.

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

**Les sujets sont nommés par leur endroit, plus par la cryptographie qu'ils contiennent.** Les sujets étaient regroupés par famille d'algorithmes, ce qui fait qu'un sujet ne pouvait être nommé que d'après une famille : on demandait combien de temps « Chiffrement à clé publique » et « Empreintes de contenu » devaient rester confidentiels. Ce sont des mécanismes, pas des données. Pire, le seul sujet qu'il aurait su traiter — cinq répertoires métier — avait été écrasé dans l'un des deux.

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
