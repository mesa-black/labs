#!/bin/sh
#
# Bascule le site sur la version datée du jour.
#
# Le poste dépose une version complète du site par date de parution, sous
# releases/AAAA-MM-JJ/. Ce script choisit la plus récente dont la date est
# arrivée et fait pointer `current` dessus. Rien n'est construit ici : le
# serveur reste un hôte statique, il ne sait que déplacer un lien.
#
# Lancé chaque matin par labs-release.timer, et à chaque déploiement.
#
#   LABS_TODAY=2026-10-04 labs-release    # pour vérifier une bascule à venir
set -eu

ROOT=${SITE_ROOT:-/var/www/labs}
RELEASES="$ROOT/releases"
# The publication calendar is the author's, not the server's. The host runs in
# UTC, so an article dated today in Paris would have waited two more hours
# before existing — and the daily timer already fires on Paris time.
TODAY=${LABS_TODAY:-$(TZ=Europe/Paris date +%F)}
KEEP=${LABS_KEEP:-3}

[ -d "$RELEASES" ] || { echo "aucune version déposée dans $RELEASES"; exit 1; }

# Le glob est trié : la dernière version dont la date est arrivée gagne.
target=''
for dir in "$RELEASES"/*/; do
	name=$(basename "$dir")
	case "$name" in
	????-??-??) ;;
	*) continue ;;
	esac
	[ "$name" \> "$TODAY" ] && continue
	target=$name
done

[ -n "$target" ] || { echo "aucune version dont la date soit arrivée (nous sommes le $TODAY)"; exit 1; }

previous=$(readlink "$ROOT/current" 2>/dev/null || echo '')
if [ "$previous" = "$RELEASES/$target" ]; then
	echo "déjà sur la version $target"
else
	# Lien temporaire puis renommage : le remplacement est atomique, aucune
	# requête ne peut tomber sur une racine inexistante.
	ln -sfn "$RELEASES/$target" "$ROOT/.current.new"
	mv -Tf "$ROOT/.current.new" "$ROOT/current"
	echo "version $target en ligne${previous:+ (précédente : $(basename "$previous"))}"
fi

# Purge : on garde la version active et les précédentes, pour pouvoir revenir
# en arrière d'un seul lien. Les versions futures ne sont jamais touchées.
kept=0
for dir in $(ls -1r "$RELEASES"); do
	[ "$dir" \> "$target" ] && continue
	kept=$((kept + 1))
	[ "$kept" -le "$KEEP" ] && continue
	rm -rf "${RELEASES:?}/$dir"
	echo "  purge de la version $dir"
done
