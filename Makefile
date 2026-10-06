.DEFAULT_GOAL := help
.PHONY: help install build drafts preview serve clean drafts-list publish unpublish provision deploy

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

install: ## Install the dependencies
	@composer install

# Adresse publique du site. Sert aux URL canoniques, aux hreflang, au sitemap et
# aux métadonnées de partage — donc le build local et le build déployé ne peuvent
# pas partager la même valeur par défaut.
SITE_URL ?= https://mesa.black

# Le nom que Caddy sert, et pour lequel il demande un certificat. Avec une valeur
# par défaut, et pas seulement dans l'environnement : sans elle, un `make
# provision` lancé sans y penser regénère le bloc en `:80` et défait HTTPS sans
# rien dire. Le domaine est une décision prise une fois, elle appartient au
# dépôt.
SITE_DOMAIN ?= mesa.black
SITE_ROOT ?= /var/www/labs

build: ## Build the site into public/ (published posts only)
	@php bin/build.php

drafts: ## Build including drafts — never deploy this output
	@php bin/build.php --drafts

# `deploy` reconstruit public/ pour chaque date de parution et finit par celle du
# jour : il écrase donc toute prévisualisation d'un état futur, en silence, et
# avec les URL du site déployé. C'est arrivé deux fois, dont une fois sous les
# yeux de quelqu'un qui cherchait l'article. Une cible dédiée, qui dit ce qu'elle
# montre et sur quelle date, coûte quatre lignes.
PREVIEW_PORT ?= 8000

preview: ## Prévisualiser le site à une date : make preview [DATE=2026-10-08]
	@d="$(DATE)"; \
	 test -n "$$d" || d=$$(php bin/build.php --release-dates | tail -1); \
	 test -n "$$d" || d=$$(date +%F); \
	 SITE_URL="http://localhost:$(PREVIEW_PORT)" php bin/build.php --as-of="$$d" >/dev/null; \
	 printf '\n  état du site au %s · http://localhost:%s/\n' "$$d" "$(PREVIEW_PORT)"; \
	 printf '  %s\n\n' "$$(find public -name index.html | wc -l | tr -d ' ') pages, Ctrl-C pour arrêter"; \
	 php -S localhost:$(PREVIEW_PORT) -t public

serve: drafts ## Build with drafts and serve on http://localhost:8000
	@php -S localhost:8000 -t public

clean: ## Remove the generated site
	@rm -rf public

# --- publication -------------------------------------------------------------

drafts-list: ## Lister les brouillons et leur clé
	@php bin/publish.php

publish: ## Publier un article dans toutes ses langues, puis déployer : make publish KEY=slug
	@test -n "$(KEY)" || { php bin/publish.php; exit 1; }
	@php bin/publish.php "$(KEY)"
	@$(MAKE) --no-print-directory deploy

unpublish: ## Remettre un article en brouillon (ne déploie pas) : make unpublish KEY=slug
	@test -n "$(KEY)" || { php bin/publish.php; exit 1; }
	@php bin/publish.php "$(KEY)" --draft
	@echo "  → 'make deploy' pour le retirer réellement du site"

# --- serveur -----------------------------------------------------------------
# `provision` décrit la machine, `deploy` y dépose le site. Un outil, un rôle.

provision: ## Mettre le serveur dans l'état attendu (relançable)
	@rsync -az --delete deploy/ mesa.black:/tmp/labs-deploy/
	@ssh mesa.black "sudo SITE_DOMAIN='$(SITE_DOMAIN)' SITE_ROOT='$(SITE_ROOT)' bash /tmp/labs-deploy/provision.sh"

deploy: ## Publier : une version du site par date de parution, puis bascule
	@ssh mesa.black "mkdir -p $(SITE_ROOT)/releases"
	@for d in $$(php bin/build.php --release-dates) $$(date +%F); do \
		SITE_URL="$(SITE_URL)" php bin/build.php --as-of=$$d >/dev/null; \
		rsync -az --delete --checksum --exclude '.DS_Store' \
			public/ mesa.black:$(SITE_ROOT)/releases/$$d/; \
		printf '  version %s — %s pages\n' "$$d" \
			"$$(find public -name '*.html' | wc -l | tr -d ' ')"; \
	done
	@printf '%s\n' $$(php bin/build.php --release-dates) $$(date +%F) \
		| ssh mesa.black "cat > $(SITE_ROOT)/releases/.expected"
	@ssh mesa.black /usr/local/bin/labs-release
