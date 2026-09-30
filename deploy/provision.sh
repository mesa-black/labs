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
if [ ! -e "$SITE_ROOT/index.html" ]; then
	cat > "$SITE_ROOT/index.html" <<'HTML'
<!DOCTYPE html>
<html lang="fr"><meta charset="utf-8"><title>BlackMesa Labs</title>
<body style="font:16px system-ui;margin:4rem auto;max-width:32rem;padding:0 1rem">
<p>Rien n’est encore publié ici.</p>
</body></html>
HTML
	chown "$SITE_USER:$SITE_USER" "$SITE_ROOT/index.html"
fi

say "Configuration de Caddy"
if [ -n "$SITE_DOMAIN" ]; then
	# Le certificat n'est demandé qu'une fois le DNS pointé sur cette machine :
	# sinon Let's Encrypt refuse et finit par limiter les tentatives.
	SITE_BLOCK="$SITE_DOMAIN {"
	REDIRECT="www.$SITE_DOMAIN {
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
	root * $SITE_ROOT
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
		-Server
	}

	@assets path *.css *.woff2
	header @assets Cache-Control "public, max-age=3600"

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
# Vérifier plutôt que supposer : le script dit ce qu'il a obtenu.
code=$(curl -s -o /dev/null -w '%{http_code}' http://localhost/)
[ "$code" = "200" ] || { echo "✗ le site répond $code"; exit 1; }

printf '\n✓ Caddy sert %s — %s\n' "$SITE_ROOT" \
	"${SITE_DOMAIN:+TLS pour $SITE_DOMAIN}${SITE_DOMAIN:-pas de domaine : HTTP seul, sur IP}"
printf '  Pare-feu actif, correctifs de sécurité automatiques, fail2ban en service\n'
