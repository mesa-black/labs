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

## Déploiement

Pas encore branché. La cible est le Caddy qui sert déjà `mesa.black` : `make build` en CI,
puis dépôt du contenu de `public/`. Rien à installer sur le serveur, aucun service à
patcher.
