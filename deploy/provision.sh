#!/usr/bin/env bash
#
# État du serveur qui sert le blog. À lancer depuis le poste :
#
#   make provision                      # sans domaine : HTTP sur l'IP
#   SITE_DOMAIN=exemple.fr make provision
#
# Relançable autant de fois qu'on veut : chaque étape vérifie avant d'agir.
# C'est ce qui le garde vrai — un script de mise en place qu'on n'exécute jamais
# ne vaut pas mieux que la documentation qu'il remplace.
#
# Le périmètre s'arrête là où commence la publication : ce script décrit la
# machine, `make deploy` y dépose les fichiers.
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

SITE_ROOT=${SITE_ROOT:-/var/www/labs}
SITE_DOMAIN=${SITE_DOMAIN:-}
SITE_USER=${SITE_USER:-ubuntu}

say() { printf '\n▸ %s\n' "$1"; }

say "Paquets de base"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq ca-certificates curl debian-keyring debian-archive-keyring \
	apt-transport-https ufw fail2ban unattended-upgrades rsync

say "Correctifs de sécurité automatiques"
# Réponse directe à la dérive trouvée sur l'autre serveur : un service qui tourne
# sans jamais recevoir de correctif ne se signale pas.
cat > /etc/apt/apt.conf.d/20auto-upgrades <<'CONF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
CONF
systemctl enable --now fail2ban

say "Pare-feu : 22, 80, 443, le reste fermé"
ufw allow 22/tcp >/dev/null
ufw allow 80/tcp >/dev/null
ufw allow 443/tcp >/dev/null
ufw --force enable >/dev/null

say "Dépôt Caddy"
# Déclaré ici, pas ajouté à la main : une montée de version de distribution
# supprime les sources tierces sans le dire, et relancer ce script les rétablit.
# Format deb822, celui qu'Ubuntu 26.04 utilise pour ses propres sources.
install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://dl.cloudsmith.io/public/caddy/stable/gpg.key \
	-o /etc/apt/keyrings/caddy-stable.asc
chmod 0644 /etc/apt/keyrings/caddy-stable.asc
cat > /etc/apt/sources.list.d/caddy-stable.sources <<'CONF'
Types: deb
URIs: https://dl.cloudsmith.io/public/caddy/stable/deb/debian
Suites: any-version
Components: main
Signed-By: /etc/apt/keyrings/caddy-stable.asc
Enabled: yes
CONF
apt-get update -qq
apt-get install -y -qq caddy

say "Racine du site : $SITE_ROOT"
install -d -o "$SITE_USER" -g "$SITE_USER" -m 0755 "$SITE_ROOT"
install -d -o "$SITE_USER" -g "$SITE_USER" -m 0755 "$SITE_ROOT/releases"

say "Parution datée"
# Le poste dépose une version complète du site par date de parution. Caddy sert
# le lien `current`, qu'un minuteur fait avancer chaque matin. Conséquence
# voulue : aucune chaîne de construction ici, donc aucune parution qui échoue
# à cause d'une dépendance cassée sur le serveur.
if [ ! -L "$SITE_ROOT/current" ]; then
	seed="$SITE_ROOT/releases/$(date +%F)"
	install -d -o "$SITE_USER" -g "$SITE_USER" -m 0755 "$seed"
	if [ -f "$SITE_ROOT/index.html" ]; then
		# Reprise de l'existant : ce qui était servi jusqu'ici devient la
		# version du jour, sans interruption.
		find "$SITE_ROOT" -mindepth 1 -maxdepth 1 \
			! -name releases ! -name current -exec mv {} "$seed/" \;
	else
		cat > "$seed/index.html" <<'HTML'
<!DOCTYPE html>
<html lang="fr"><meta charset="utf-8"><title>BlackMesa Labs</title>
<body style="font:16px system-ui;margin:4rem auto;max-width:32rem;padding:0 1rem">
<p>Rien n’est encore publié ici.</p>
</body></html>
HTML
	fi
	chown -R "$SITE_USER:$SITE_USER" "$seed"
	ln -sfn "$seed" "$SITE_ROOT/current"
	chown -h "$SITE_USER:$SITE_USER" "$SITE_ROOT/current"
fi

install -m 0755 "$HERE/release.sh" /usr/local/bin/labs-release
install -m 0644 "$HERE/labs-release.service" /etc/systemd/system/labs-release.service
install -m 0644 "$HERE/labs-release.timer" /etc/systemd/system/labs-release.timer
systemctl daemon-reload
systemctl enable --now labs-release.timer >/dev/null

# Le seul en-tête qui rend HTTPS difficile à défaire : sans lui, un visiteur
# qui tape le nom sans schéma repart en clair une fois, et c'est la fois qui
# compte. Un an, les sous-domaines compris — www est le seul qui existe et il
# est servi par la même machine. Pas de `preload` : l'inscription sur la liste
# des navigateurs ne se retire pas en une journée, et ce site a un domaine dont
# le renouvellement n'est pas encore tranché.
HSTS=""
if [ -n "$SITE_DOMAIN" ]; then
	HSTS='Strict-Transport-Security "max-age=31536000; includeSubDomains"
		'
fi

say "Configuration de Caddy"
if [ -n "$SITE_DOMAIN" ]; then
	# Le certificat n'est demandé qu'une fois le DNS pointé sur cette machine :
	# sinon Let's Encrypt refuse et finit par limiter les tentatives.
	SITE_BLOCK="$SITE_DOMAIN {"
	# www d'un côté, et l'adresse IP de l'autre : le site a vécu des mois sur
	# son IP nue, des liens la portent encore, et un nom d'hôte dans le bloc
	# cesse de répondre à tout ce qui n'est pas lui. Rediriger coûte quatre
	# lignes ; laisser mourir ces liens se verrait pour toujours dans les
	# journaux de quelqu'un d'autre. Pas de TLS sur l'IP : aucune autorité
	# ordinaire ne signe pour une adresse, donc le bloc est explicitement en
	# http et ne sert qu'à envoyer vers le nom.
	REDIRECT="www.$SITE_DOMAIN {
	redir https://$SITE_DOMAIN{uri} 301
}

http://$(hostname -I | awk '{print $1}') {
	redir https://$SITE_DOMAIN{uri} 301
}
"
else
	SITE_BLOCK=":80 {"
	REDIRECT=""
fi

cat > /etc/caddy/Caddyfile <<CONF
# Généré par deploy/provision.sh — toute modification à la main sera écrasée.
$REDIRECT
$SITE_BLOCK
	root * $SITE_ROOT/current
	encode zstd gzip
	file_server

	# Un dossier par article : /article/ sert son index.html.
	try_files {path} {path}/ {path}/index.html

	handle_errors {
		rewrite * /404.html
		file_server
	}

	header {
		# Site entièrement statique : rien à exécuter, rien à injecter.
		Content-Security-Policy "default-src 'none'; style-src 'self' https://fonts.googleapis.com; font-src https://fonts.gstatic.com; img-src 'self' data:; base-uri 'none'; form-action 'none'; frame-ancestors 'none'"
		X-Content-Type-Options "nosniff"
		Referrer-Policy "strict-origin-when-cross-origin"
		$HSTS-Server
	}

	@assets path *.css *.woff2
	header @assets Cache-Control "public, max-age=3600"

	# Une signature de Sablier est du JSON, et elle est lisible exprès : qui
	# vérifie doit pouvoir voir ce qui a été signé sans rien lancer. Caddy
	# devinait « application/pgp-signature » d'après l'extension, ce qui est faux
	# et force un téléchargement au lieu d'un affichage.
	@signature path *.sig
	header @signature Content-Type "application/json; charset=utf-8"

	# Pas de journal fichier : sous systemd, Caddy écrit dans le journal, qui
	# tourne et se purge tout seul. Un fichier de log, c'est un dossier à créer,
	# des droits à accorder et une rotation à configurer — pour un site statique,
	# \`journalctl -u caddy\` suffit.
}
CONF

caddy validate --adapter caddyfile --config /etc/caddy/Caddyfile >/dev/null
systemctl enable caddy >/dev/null
systemctl reload-or-restart caddy

say "Vérification"
# Vérifier plutôt que supposer : le script dit ce qu'il a obtenu. Avec un nom
# d'hôte, `localhost` ne correspond plus à aucun bloc — la vérification d'avant
# aurait échoué pour une bonne raison et ressemblé à une panne, alors elle
# interroge maintenant ce qui est réellement servi : le nom en TLS, et la
# redirection depuis le clair.
if [ -n "$SITE_DOMAIN" ]; then
	# Le certificat n'existe pas à la seconde où Caddy recharge : il est demandé
	# à Let's Encrypt, ce qui prend quelques secondes et un aller-retour réseau.
	# Interroger une fois juste après le rechargement, c'est mesurer la course
	# plutôt que le résultat — la première version de cette vérification a
	# échoué sur un serveur qui fonctionnait. On attend, avec une limite.
	code=000
	for _ in $(seq 20); do
		code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 \
			--resolve "$SITE_DOMAIN:443:127.0.0.1" "https://$SITE_DOMAIN/" || echo 000)
		[ "$code" = "200" ] && break
		sleep 2
	done
	[ "$code" = "200" ] || { echo "✗ le site répond $code en HTTPS après 40 s d'attente du certificat"; exit 1; }
	code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 --resolve "$SITE_DOMAIN:80:127.0.0.1" "http://$SITE_DOMAIN/" || echo 000)
	[ "$code" = "308" ] || [ "$code" = "301" ] || { echo "✗ le clair répond $code au lieu de rediriger"; exit 1; }
else
	code=$(curl -s -o /dev/null -w '%{http_code}' http://localhost/)
	[ "$code" = "200" ] || { echo "✗ le site répond $code"; exit 1; }
fi

# `${X:+a}${X:-b}` n'est pas un ternaire : `:-` ne substitue que si la variable
# est vide, donc avec un domaine les deux moitiés s'affichaient — « TLS pour
# mesa.black » suivi de « mesa.black ». Le défaut dormait depuis l'écriture du
# script et n'est devenu visible que le jour où un domaine a existé.
if [ -n "$SITE_DOMAIN" ]; then
	SERVED="TLS pour $SITE_DOMAIN"
else
	SERVED="pas de domaine : HTTP seul, sur IP"
fi

printf '\n✓ Caddy sert %s (version %s) — %s\n' "$SITE_ROOT/current" \
	"$(basename "$(readlink -f "$SITE_ROOT/current")")" \
	"$SERVED"
printf '  Pare-feu actif, correctifs de sécurité automatiques, fail2ban en service\n'
printf '  Bascule quotidienne : %s\n' "$(systemctl show -p NextElapseUSecRealtime --value labs-release.timer || echo 'labs-release.timer')"
