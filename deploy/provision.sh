#!/usr/bin/env bash
#
# The state of the server that serves the blog. Run from the workstation:
#
#   make provision                       # SITE_DOMAIN defaults in the Makefile
#   SITE_DOMAIN= make provision          # no domain: HTTP on the address
#
# Re-runnable as often as you like: every step checks before acting. That is
# what keeps it true — a setup script nobody ever runs is worth no more than the
# documentation it replaces.
#
# The scope stops where publishing begins: this script describes the machine,
# `make deploy` puts the files on it.
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

SITE_ROOT=${SITE_ROOT:-/var/www/labs}
SITE_DOMAIN=${SITE_DOMAIN:-}
SITE_USER=${SITE_USER:-ubuntu}
# Where the site is served from: the ClusterIP of the `labs` Service in k3s.
SITE_UPSTREAM=${SITE_UPSTREAM:-10.43.200.10:80}

say() { printf '\n▸ %s\n' "$1"; }

say "Paquets de base"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq ca-certificates curl debian-keyring debian-archive-keyring \
	apt-transport-https ufw fail2ban unattended-upgrades rsync

say "Automatic security updates"
# A direct answer to the drift found on the other server: a service running
# without ever receiving a patch never announces itself.
cat > /etc/apt/apt.conf.d/20auto-upgrades <<'CONF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
CONF
systemctl enable --now fail2ban

say "Firewall: 22, 80, 443, everything else closed"
ufw allow 22/tcp >/dev/null
ufw allow 80/tcp >/dev/null
ufw allow 443/tcp >/dev/null
ufw --force enable >/dev/null

say "Caddy repository"
# Declared here rather than added by hand: a distribution upgrade removes
# third-party sources without saying so, and re-running this script puts them
# back. deb822 format, the one Ubuntu 26.04 uses for its own sources.
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

say "Dated releases"
# The workstation uploads one complete version of the site per publication
# date. Caddy serves the `current` link, which a timer moves forward every
# morning. The intended consequence: no build chain here, so no publication can
# fail because of a broken dependency on the server.
if [ ! -L "$SITE_ROOT/current" ]; then
	seed="$SITE_ROOT/releases/$(date +%F)"
	install -d -o "$SITE_USER" -g "$SITE_USER" -m 0755 "$seed"
	if [ -f "$SITE_ROOT/index.html" ]; then
		# Taking over what is there: whatever was being served becomes
		# today's version, with no interruption.
		find "$SITE_ROOT" -mindepth 1 -maxdepth 1 \
			! -name releases ! -name current -exec mv {} "$seed/" \;
	else
		cat > "$seed/index.html" <<'HTML'
<!DOCTYPE html>
<html lang="fr"><meta charset="utf-8"><title>BlackMesa Labs</title>
<body style="font:16px system-ui;margin:4rem auto;max-width:32rem;padding:0 1rem">
<p>Nothing is published here yet.</p>
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

# The one header that makes HTTPS hard to undo: without it, a visitor typing the
# name with no scheme leaves in the clear once, and that once is the one that
# counts. A year, subdomains included — www and vault are the only ones that
# exist, and both are served over TLS by this same machine. No `preload`: getting
# onto the browsers' list is not undone in a day, and this site has a domain
# whose renewal is not settled.
HSTS=""
if [ -n "$SITE_DOMAIN" ]; then
	HSTS='Strict-Transport-Security "max-age=31536000; includeSubDomains"
		'
fi

say "Configuration de Caddy"
if [ -n "$SITE_DOMAIN" ]; then
	# The certificate is only requested once DNS points at this machine:
	# otherwise Let's Encrypt refuses and eventually rate-limits the attempts.
	SITE_BLOCK="$SITE_DOMAIN {"
	# www on one side, the bare address on the other: the site lived on its
	# plain IP for months, links still carry it, and a hostname in the block
	# stops answering to anything that is not it. Redirecting costs four lines;
	# letting those links die would show up forever in somebody else's logs. No
	# TLS on the address: no ordinary authority signs for one, so that block is
	# explicitly http and does nothing but send traffic to the name.
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
# Generated by deploy/provision.sh — any edit made by hand will be overwritten.
{
	# Caddy's administration endpoint listens on 127.0.0.1:2019 by default: a
	# full reconfiguration API, open permanently, on a machine whose only job is
	# to serve files. It is not reachable from outside, but any local process —
	# or anybody who obtains a shell — can rewrite the server's configuration
	# through it without touching this file. Nothing here needs it: the
	# configuration is generated by this script and applied by restarting the
	# service, which on a static site is imperceptible.
	admin off
}
$REDIRECT
$SITE_BLOCK
	# The site itself runs in k3s on this machine (github.com/mesa-black/k3s-stack,
	# spoke/apps/labs): files, headers and the daily switch of dated versions all
	# live in its image. This block only terminates TLS and passes requests on, to
	# a Service whose ClusterIP is fixed in that repository — nothing listens on a
	# host port, nothing goes around ufw.
	reverse_proxy $SITE_UPSTREAM {
		# A pod being replaced closes its kept-alive connections: retry for a
		# few seconds rather than answer 502.
		lb_try_duration 5s
	}

	# Caddy announces itself twice on a proxied response: Server, and the Via
	# that reverse_proxy adds. Removed here rather than with reverse_proxy's own
	# header_down, which runs before Via is added and so left it in place
	# (tried). Deletions in `header` are deferred to the moment the response is
	# written, after everything else.
	header {
		-Server
		-Via
	}

	# No log file: under systemd, Caddy writes to the journal, which rotates and
	# prunes itself.
}

# Other services on this machine bring their own vhost (the vault, from its own
# repository): this file is regenerated on every run and would erase them, so
# they live beside it and are pulled in here. A glob that matches nothing is not
# an error.
import /etc/caddy/sites/*.caddy
CONF
install -d -m 0755 /etc/caddy/sites

caddy validate --adapter caddyfile --config /etc/caddy/Caddyfile >/dev/null
systemctl enable caddy >/dev/null
# Restart rather than reload: `caddy reload` goes through the administration
# endpoint, which the block above switches off.
systemctl restart caddy

say "Verification"
# Check rather than assume: the script says what it obtained. With a hostname,
# `localhost` no longer matches any block — the previous check would have failed
# for a good reason and looked like an outage, so it now asks for what is
# actually served: the name over TLS, and the redirect from the clear.
if [ -n "$SITE_DOMAIN" ]; then
	# The certificate does not exist the second Caddy reloads: it is requested
	# from Let's Encrypt, which takes a few seconds and a network round trip.
	# Asking once right after the reload measures the race rather than the
	# result — the first version of this check failed on a server that worked.
	# So it waits, with a limit.
	code=000
	for _ in $(seq 20); do
		code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 \
			--resolve "$SITE_DOMAIN:443:127.0.0.1" "https://$SITE_DOMAIN/" || echo 000)
		[ "$code" = "200" ] && break
		sleep 2
	done
	[ "$code" = "200" ] || { echo "✗ the site answers $code over HTTPS after waiting 40 s for the certificate"; exit 1; }
	code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 --resolve "$SITE_DOMAIN:80:127.0.0.1" "http://$SITE_DOMAIN/" || echo 000)
	[ "$code" = "308" ] || [ "$code" = "301" ] || { echo "✗ cleartext answers $code instead of redirecting"; exit 1; }
else
	code=$(curl -s -o /dev/null -w '%{http_code}' http://localhost/)
	[ "$code" = "200" ] || { echo "✗ the site answers $code"; exit 1; }
fi

# `${X:+a}${X:-b}` is not a ternary: `:-` only substitutes when the variable is
# empty, so with a domain both halves showed — "TLS pour mesa.black" followed by
# "mesa.black". The defect had been dormant since the script was written and
# could only appear the day a domain existed.
if [ -n "$SITE_DOMAIN" ]; then
	SERVED="TLS pour $SITE_DOMAIN"
else
	SERVED="pas de domaine : HTTP seul, sur IP"
fi

printf '\n✓ Caddy proxies %s to %s (the labs pod in k3s) — %s\n' "${SITE_DOMAIN:-:80}" "$SITE_UPSTREAM" \
	"$SERVED"
printf '  Firewall up, automatic security updates, fail2ban running\n'
printf '  Bascule quotidienne : %s\n' "$(systemctl show -p NextElapseUSecRealtime --value labs-release.timer || echo 'labs-release.timer')"
