# BlackMesa Labs

Le blog d'ingénierie de BlackMesa. **Markdown en entrée, HTML statique en sortie, aucun
runtime en production.**

## Pourquoi pas un CMS

Le site publié est un dossier de fichiers. Pas de base de données, pas d'interface
d'administration, pas d'authentification, pas de sauvegarde à surveiller : le blog ne peut
pas tomber pour une raison applicative, et il n'a pas de surface d'attaque propre. Le prix
à payer est qu'on écrit dans un éditeur de texte plutôt que dans un navigateur — ce qu'on
faisait déjà.

**Le seuil de bascule est écrit, et il a déjà bougé une fois.** Il disait : pagination,
tags, multilingue et recherche → on passe à Hugo. Le multilingue est arrivé et a coûté
~80 lignes, soit moins que la migration qu'il aurait déclenchée. On l'a donc fait ici, et
le seuil se resserre : **pagination, tags ou recherche → on arrête et on bascule.** Écrit
pour que la prochaine fois la question se tranche en une minute au lieu d'être rediscutée.

## Démarrer

```bash
make install     # dépendances Composer
make serve       # build avec les brouillons + http://localhost:8000
```

| Commande | Effet |
|---|---|
| `make build` | Construit `public/` — **articles publiés uniquement** |
| `make drafts` | Idem en incluant les brouillons. À ne jamais déployer |
| `make serve` | `drafts` + serveur local sur le port 8000 |
| `make clean` | Supprime `public/` |

`make build` échoue s'il n'y a aucun article publié : c'est volontaire, ça évite de
déployer un site vide sans s'en apercevoir.

## Écrire un article

Un fichier dans `content/posts/<langue>/`, nommé `AAAA-MM-JJ-slug.md` :

```markdown
---
title: "Le titre, tel qu'il s'affichera"
standfirst: "Une phrase de chapeau. Optionnelle mais recommandée."
key: mon-article           # lie les traductions entre elles
date: 2026-09-27
slug: mon-article          # optionnel : sinon déduit du nom de fichier
draft: true                # retirer pour publier
---

Le corps en markdown. Les `##` deviennent les intertitres.
```

### Deux natures d'article

Un **article complet** vit ici et fait autorité ici.

Un **pointeur** présente en quelques paragraphes un REX publié sur
[Show me the REX](https://showmetherex.com) et y renvoie, sans recopier le texte :

```markdown
---
title: "…"
date: 2026-09-25
pointer: true
rex: https://showmetherex.com/feedback/le-slug
---
```

La **première** mention de « Show me the REX » dans le corps d'un article devient
automatiquement un lien vers la plateforme, dans la langue du lecteur. La première
seulement : dix fois le même lien dans une page se lit mal, et les moteurs y voient du
bourrage. Le HTML est parcouru en séparant balises et texte, pour ne jamais écrire un lien
dans un lien ni à l'intérieur d'un bloc de code.

C'est volontaire et ce n'est pas cosmétique : **le même texte publié sur deux domaines, les
moteurs en ignorent un**. Un pointeur émet donc une balise `canonical` vers SMTR, qui reste
la source. Les nouveaux sujets d'ingénierie, eux, sont canoniques ici et ne partent pas sur
SMTR — c'est toute la raison d'être de ce blog.

`title`, `date` et `key` sont obligatoires — la construction s'arrête avec le nom du
fichier fautif plutôt que de publier un article incomplet.

### Trois langues

Français à la racine, anglais sous `/en/`, espagnol sous `/es/` — **le même schéma d'URL
que showmetherex.com**, pour qu'un lecteur qui passe d'un site à l'autre ne soit pas perdu.

Les traductions d'un même article se reconnaissent par leur `key` commune, et chacune a son
propre `slug` : un titre anglais mérite une URL anglaise. Le sélecteur de langue saute
alors vers la traduction du même article, pas vers l'accueil. Une langue dans laquelle
l'article n'existe pas reste affichée mais inerte — plus honnête que de la masquer.

Les balises `hreflang` sont générées à partir des traductions réellement présentes.

### Publier

```bash
make drafts-list                              # quels brouillons, quelles clés
make publish KEY=le-code-qu-on-n-ecrit-pas    # retire draft: true partout, puis déploie
make unpublish KEY=...                        # remet en brouillon (ne déploie pas)
```

`publish` agit sur **toutes les langues d'un même article** en une fois, via leur `key`
commune. C'est le but : un article oublié en brouillon dans une seule langue s'affiche en
grisé dans le sélecteur, et on ne s'en aperçoit que des semaines plus tard. Le script
prévient d'ailleurs si une langue manque.

Il ne réécrit que la ligne `draft` : un aller-retour publier/dépublier rend le fichier
octet pour octet identique.

### Programmer une parution

Le champ `date` du front matter **est** la date de parution. Un article daté du futur est
écarté du build et sort tout seul le jour dit :

```bash
make drafts-list      # les brouillons, et à part, les articles programmés
```

Brouillon et article programmé sont deux états distincts, et les confondre mène à
réécrire un texte déjà relu. Un brouillon n'est pas fini ; un article programmé l'est, il
attend son tour.

Tout publier le même jour est le meilleur moyen de faire fuir un lecteur : il en lit un,
voit qu'il en reste six, et referme l'onglet. Étaler les parutions donne une raison de
revenir.

Le temps de lecture est calculé sur le texte rendu, pas sur le markdown : la syntaxe que
le lecteur ne voit jamais ne compte pas.

## Structure

```
bin/build.php     le générateur, en entier
content/posts/    les articles, en markdown, un dossier par langue
templates/        les gabarits Twig (base, liste, article, flux Atom)
assets/style.css  une feuille de style, sans étape de compilation
public/           la sortie — généré, jamais versionné
```

`public/` est vidé à chaque construction : une page dont le slug a changé ne peut pas
survivre à la génération suivante.

## Le design

**Une seule famille jouée sur les graisses** plutôt qu'une police de titre et une police de
texte : la hiérarchie vient du poids et du serrage. **Archivo** sert aux titres comme au
corps. **IBM Plex Mono** est strictement réservé à ce qui vient d'une machine — commandes,
versions, extraits de code — pour que le lecteur apprenne qu'un texte en chasse fixe n'a
pas été écrit pour lui.

Fond **crème**, encre presque noire. **Le sarcelle est l'accent** (liens, intertitres,
surlignage des passages importants), **l'ambre signale ce qui ne va pas** ou n'est pas
fini : un brouillon, un avertissement. Aucune couleur n'est décorative.

Le corps des articles est **justifié avec césure automatique** — la justification seule,
sur une colonne étroite, creuse des rivières blanches. La césure s'appuie sur le `lang` de
la page, d'où sa présence sur `<html>`. Les titres ne sont jamais justifiés : ils se
répartissent avec `text-wrap: balance`. Sous 34rem la justification est désactivée : même
avec la césure, une colonne de téléphone se remplit de trous.

Thème clair et sombre gérés par jetons CSS, y compris quand le visiteur laisse son système
décider. Le sombre est chaud lui aussi, pour rester cohérent avec le crème.

## SEO et moteurs de réponse

Généré à chaque construction, sans rien à maintenir :

- **`sitemap.xml`** couvrant les trois langues, chaque URL portant ses alternates ;
- **`robots.txt`** qui déclare le sitemap et **autorise explicitement les crawlers des
  moteurs de réponse** (GPTBot, ClaudeBot, PerplexityBot). C'est un choix : être cité est
  la raison d'écrire ici. Passer les lignes en `Disallow` suffit à changer d'avis ;
- **`canonical`** sur chaque page — vers le REX pour un pointeur, auto-référencée sinon ;
- **`hreflang`** réciproques plus `x-default` vers le français ;
- **Open Graph** et Twitter Card, pour qu'un lien collé sur LinkedIn ne sorte pas nu ;
- **JSON-LD** `BlogPosting` sur les articles (titre, chapeau, date, langue, auteur, nombre
  de mots) et `Blog` sur les accueils. C'est ce qui permet à un moteur de réponse de citer
  correctement : qui a écrit, quand, pour quelle organisation ;
- une **page 404** dans le style du site.

Ce qui aide autant sans être une balise : un chapeau qui résume l'article dès le haut de
page, des sous-titres explicites, des paragraphes courts. Un texte extractible se cite
mieux qu'un texte fluide.

**Le manque restant : aucune image de partage.** Sans `og:image`, LinkedIn affichera une
vignette vide. Il faut soit un visuel unique pour tout le site, soit une carte générée par
article — la seconde option vaut le coup le jour où la publication devient régulière.

## Le serveur

Une machine Ubuntu, un Caddy, un dossier de fichiers. Rien d'autre.

```bash
make provision                        # met le serveur dans l'état attendu
SITE_DOMAIN=exemple.fr make provision # idem, avec certificat automatique
make deploy                           # construit chaque version datée et publie
```

`deploy/provision.sh` décrit l'état de la machine : paquets, correctifs de sécurité
automatiques, pare-feu réduit à 22/80/443, fail2ban, dépôt Caddy **déclaré** et non ajouté
à la main — une montée de version de distribution supprime les sources tierces sans le
dire, et relancer le script les rétablit. Il est relançable autant qu'on veut et se termine
par une vérification : il dit ce qu'il a obtenu, il ne le suppose pas.

Le périmètre s'arrête là où commence la publication. `make deploy` fait le reste, par
`rsync`.

### Comment une parution programmée arrive en ligne

Le serveur ne construit rien. Il n'a ni PHP, ni composer, ni dépôt : lui donner une chaîne
de construction, c'est accepter qu'une parution échoue un samedi matin à cause d'une
dépendance cassée.

À la place, `make deploy` construit **une version complète du site par date de parution**
— aujourd'hui, et une par article programmé — et les dépose toutes :

```
/var/www/labs/releases/2026-09-30/   la version du jour
/var/www/labs/releases/2026-10-04/   celle qui sortira samedi
/var/www/labs/current -> releases/2026-09-30
```

Caddy sert le lien `current`. Chaque matin à 7 h, `labs-release.timer` déclenche un script
de quinze lignes qui fait pointer ce lien sur la version la plus récente dont la date est
arrivée, puis purge les anciennes en en gardant trois. Le remplacement passe par un
renommage : aucune requête ne peut tomber sur une racine inexistante.

Trois conséquences qui valent le détour :

- ce qui sortira samedi est **déjà construit et consultable** aujourd'hui, donc vérifiable
  avant de partir ;
- revenir en arrière, c'est refaire pointer un lien ;
- le minuteur est `Persistent=true` : si la machine était éteinte à 7 h, la bascule se fait
  au démarrage suivant plutôt que d'être sautée.

On peut répéter une parution future sans attendre, et c'est la seule preuve qui compte :

```bash
ssh mesa.black 'LABS_TODAY=2026-10-04 /usr/local/bin/labs-release'   # avance
ssh mesa.black '/usr/local/bin/labs-release'                         # revient au jour réel
```

**On a essayé Ansible d'abord, et on l'a jeté.** Pour une machine qui sert des fichiers
statiques, il apportait l'idempotence et une dépendance Python, contre trente lignes de
shell qui font la même chose. Il redeviendra pertinent le jour où il y aura une vraie
configuration serveur à posséder — fichiers compose, secrets, plusieurs machines. Pas
avant.

**Le certificat n'est demandé qu'une fois le DNS pointé sur la machine.** Sans domaine, le
site est servi en HTTP sur l'IP : appeler Let's Encrypt pour un domaine mal pointé ne donne
rien et finit par limiter les tentatives.
