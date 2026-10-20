---
title: "Nous avons nommé la branche. Git a poussé sur main."
standfirst: "Dans un dépôt GitOps, main est la production. Un soir d'octobre, des manifests pas encore validés y sont arrivés, avec un tag d'image qui n'existait pas, sans que personne ait tapé « main ». Deux réglages de Git, chacun raisonnable, et une commande correcte partout ailleurs."
key: push-sur-main
date: 2026-10-21
slug: nous-avons-nomme-la-branche
draft: true
---

Dans un dépôt GitOps, il n'y a pas de bouton « déployer ». Argo CD lit la branche `main` de k3s-stack, notre dépôt d'infrastructure (privé), et fait converger le cluster vers ce qu'elle contient. Pousser sur `main`, c'est mettre en production. C'est tout l'intérêt du modèle, et c'est pour ça que tout passe par une branche, relue, puis fusionnée.

Le 19 octobre à 01:00, un commit est arrivé directement sur `main` : les manifests du petit service qui montre au lecteur l'échange de clés que son navigateur vient de négocier. Ils n'avaient pas été validés. Et leur image portait un tag provisoire, écrit en attendant que la CI construise la vraie :

```yaml
images:
  - name: ghcr.io/mesa-black/handshake
    newTag: TO-BE-SET-AFTER-THE-FIRST-BUILD
```

Argo CD a fait exactement ce qu'on lui demande : il a déployé. Le pod est resté en `ImagePullBackOff` neuf minutes, jusqu'à ce que la CI écrive le vrai tag à 23:09 UTC. Rien de grave cette fois : un service neuf, que personne n'appelait encore. Mais personne n'avait tapé `git push origin main`.

## La commande qui a été tapée

La branche a été créée dans un worktree, depuis la branche distante, puis poussée en la nommant explicitement. En substance :

```bash
git worktree add -b feat/handshake ../k3s-handshake origin/HEAD
# … commit …
git push -u origin feat/handshake
```

Elle a été tapée par l'agent de code avec qui nous travaillons, et c'est la commande juste dans la quasi-totalité des configurations. Elle ne l'était pas dans la nôtre, à cause de deux réglages qui se rencontrent.

**Le premier est un défaut de Git.** Une branche créée à partir d'une branche distante (`origin/main`, ou `origin/HEAD` qui pointe dessus) la suit automatiquement : c'est `branch.autoSetupMerge`, activé par défaut. Notre `feat/handshake` avait donc `main` comme amont, sans que personne l'ait demandé.

**Le second est un choix, dans notre `~/.gitconfig` :**

```ini
[push]
    default = upstream
```

Avec `upstream`, `git push` envoie la branche courante vers son amont. C'est un réglage légitime, pensé pour les flux où une branche locale porte un autre nom que la branche qu'elle alimente. Avec une branche qui suit `main`, il pousse donc sur `main`.

Jusque-là, rien de surprenant : c'est ce que dit la documentation pour `git push` sans argument. La surprise est ailleurs.

## Même en nommant la branche

On s'attendait à ce que nommer la branche, `git push -u origin feat/handshake`, contourne le réglage. Ce n'est pas le cas. Nous l'avons rejoué dans un dépôt jetable, avec Git 2.54, en créant chaque fois une branche depuis `origin/main` :

| `push.default` | `git push` | `git push -u origin ma-branche` |
|---|---|---|
| `simple`, le défaut de Git | refuse, et explique pourquoi | crée `ma-branche` |
| `current` | crée la branche | crée `ma-branche` |
| `upstream` | **pousse sur main** | **pousse sur main** |

Avec `upstream`, une destination absente de la commande est remplacée par l'amont, même quand on a écrit le nom de la branche source. Le nom tapé désigne ce qu'on envoie, pas où ça arrive. Seule une destination écrite en toutes lettres change le résultat :

```bash
git push -u origin HEAD:refs/heads/feat/handshake   # crée bien la branche
```

Le script, pour le vérifier sans nous :

```sh
#!/bin/sh
# Une branche créée depuis origin/main, poussée en la nommant.
set -e
d=$(mktemp -d) && cd "$d"
git init -q --bare -b main remote.git
git clone -q remote.git clone 2>/dev/null && cd clone
git commit -q --allow-empty -m init && git push -q origin main
git switch -q -c ma-branche origin/main
git commit -q --allow-empty -m "ma-branche"
git -c push.default=upstream push -q -u origin ma-branche
git --git-dir=../remote.git for-each-ref --format='%(refname:short)' refs/heads
# affiche « main » seul : la branche n'existe pas, le commit est sur main
```

## Pourquoi c'est pire dans un dépôt GitOps

Dans un dépôt d'application, ce push aurait mis un commit non relu sur `main`. Gênant, réparable, et la CI aurait sans doute protesté avant toute mise en production.

Dans un dépôt GitOps, il n'y a pas d'étape entre les deux. Le commit est le déploiement. Pas de revue, pas de fusion, et dans notre cas pas même d'image : le contrôleur a appliqué un manifest qui référençait un tag qui n'existait pas encore. L'erreur ne se voit pas dans Git, où tout a l'air normal. Elle se voit dans le cluster.

Et elle ne se voit pas dans le terminal non plus. Le push réussit, sans avertissement. La sortie mentionne bien `-> main`, sur une ligne que personne ne lit après un push qui a fonctionné.

## Ce qu'on a changé

Trois règles, désormais écrites dans les consignes de l'agent comme dans les nôtres :

1. **Créer les branches depuis `main` local, pas depuis `origin/main`.** Une branche créée depuis une branche locale ne suit rien : `git worktree add -b feat/x ../x main`, ou `--no-track` si l'on part quand même du distant.
2. **Pousser avec une destination explicite :** `git push -u origin HEAD:refs/heads/feat/x`. C'est plus long, et c'est le seul format qui donne le même résultat quel que soit `push.default`.
3. **Vérifier `origin/main` après chaque push de branche :** `git log origin/main -1`. Si le dernier commit est le nôtre, il est déjà en production.

Nous n'avons pas changé `push.default`. Ce réglage sert ailleurs, et le changer n'aurait réparé que notre poste. La consigne, elle, protège aussi l'agent, qui partage la même configuration.

## Ce qui manque encore

La vraie barrière n'est pas sur le poste. Elle est côté serveur : une règle GitHub qui refuse les push directs sur `main` et impose une pull request, avec une exception pour la clé de déploiement de la CI, qui écrit les tags d'image.

Aujourd'hui, `main` de k3s-stack n'est pas protégée : aucune règle sur la branche. Tout ce qui précède repose donc sur la discipline de ceux qui poussent, humains ou agent. C'est la prochaine chose à corriger, et nous l'écrivons ici pour qu'elle ne reste pas une intention.

## Ce que ça a donné

- **Un push** sur `main`, à 01:00, qu'aucune commande n'avait demandé en ces termes.
- **Neuf minutes** de pod en `ImagePullBackOff` en production, sur un service que personne n'appelait encore.
- **Deux réglages** en cause : `branch.autoSetupMerge`, par défaut, et `push.default = upstream`, par choix.
- **Une découverte** : avec `upstream`, nommer la branche ne change pas la destination.
- **Trois règles** de travail, et une protection de branche qui reste à poser.

## Bonnes pratiques

- Dans un dépôt où `main` est la production, protéger `main` côté serveur avant tout le reste. Une consigne protège ceux qui la connaissent, une règle protège tout le monde.
- Écrire la destination d'un push en entier (`HEAD:refs/heads/…`) dans les scripts et les consignes d'un agent : c'est le seul format indépendant de la configuration locale.
- Créer les branches de travail depuis la branche locale, pour qu'elles ne suivent rien par accident.
- Après un push, lire la ligne qui dit où il est arrivé, ou vérifier la branche distante.

## Points de vigilance

- **Une commande juste n'est juste que dans une configuration.** `git push -u origin ma-branche` est correcte presque partout. Un agent qui l'apprend ailleurs la tapera chez vous, avec votre `~/.gitconfig`.
- **Un réglage hérité n'apparaît dans aucune revue.** `push.default = upstream` vit dans la configuration globale, pas dans le dépôt. Rien ne le signale tant qu'il n'a pas produit son effet.
- **Le succès d'un push ne dit pas où il est arrivé.** Git ne prévient pas quand la destination diffère du nom tapé. La seule trace est la ligne `-> main`.
- **Celui qui répond, c'est celui qui a la configuration.** L'agent a tapé la commande, mais c'est notre poste qui l'a envoyée sur `main`. Nous l'écrivions il y a quelques jours : [un agent peut tout faire, il ne peut pas répondre de ce qu'il a fait](/qui-repond/).
