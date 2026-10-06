#!/bin/sh
#
# Switches the site to the dated version for today.
#
# The workstation uploads one complete version of the site per publication
# date, under releases/YYYY-MM-DD/. This script picks the most recent one whose
# date has come and points `current` at it. Nothing is built here: the server
# stays a static host, and all it knows how to do is move a link.
#
# Run every morning by labs-release.timer, and on every deployment.
#
#   LABS_TODAY=2026-10-04 labs-release    # rehearse a switch still ahead
set -eu

ROOT=${SITE_ROOT:-/var/www/labs}
RELEASES="$ROOT/releases"
# The publication calendar is the author's, not the server's. The host runs in
# UTC, so an article dated today in Paris would have waited two more hours
# before existing — and the daily timer already fires on Paris time.
TODAY=${LABS_TODAY:-$(TZ=Europe/Paris date +%F)}
KEEP=${LABS_KEEP:-3}

[ -d "$RELEASES" ] || { echo "no version uploaded in $RELEASES"; exit 1; }

# The glob is sorted: the last version whose date has come wins.
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

[ -n "$target" ] || { echo "no version whose date has come (today is $TODAY)"; exit 1; }

previous=$(readlink "$ROOT/current" 2>/dev/null || echo '')
if [ "$previous" = "$RELEASES/$target" ]; then
	echo "already on version $target"
else
	# A temporary link then a rename: the replacement is atomic, so no request
	# can land on a root that does not exist.
	ln -sfn "$RELEASES/$target" "$ROOT/.current.new"
	mv -Tf "$ROOT/.current.new" "$ROOT/current"
	echo "version $target is live${previous:+ (previous: $(basename "$previous"))}"
fi

# Future versions that have become stale. A piece scheduled and then withdrawn
# leaves a dated version behind which, on the day, would be served with the
# withdrawn text inside it. The workstation uploads the list of what it still
# expects; anything ahead and absent from that list has no reason to exist.
if [ -f "$RELEASES/.expected" ]; then
	for dir in "$RELEASES"/*/; do
		name=$(basename "$dir")
		case "$name" in
		????-??-??) ;;
		*) continue ;;
		esac
		[ "$name" \> "$TODAY" ] || continue
		grep -qx "$name" "$RELEASES/.expected" && continue
		rm -rf "${RELEASES:?}/$name"
		echo "  upcoming version $name dropped: no piece claims it any more"
	done
fi

# Pruning: the live version and the ones before it are kept, so that rolling
# back is one link away. Future versions still expected are kept too.
kept=0
for dir in $(ls -1r "$RELEASES"); do
	[ "$dir" \> "$target" ] && continue
	kept=$((kept + 1))
	[ "$kept" -le "$KEEP" ] && continue
	rm -rf "${RELEASES:?}/$dir"
	echo "  purge de la version $dir"
done
