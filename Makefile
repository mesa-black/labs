.DEFAULT_GOAL := help
.PHONY: help install build drafts serve clean drafts-list publish unpublish provision deploy

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

install: ## Install the dependencies
	@composer install

# Adresse publique du site. Sert aux URL canoniques, aux hreflang, au sitemap et
# aux métadonnées de partage — donc le build local et le build déployé ne peuvent
# pas partager la même valeur par défaut. Tant qu'aucun domaine n'est choisi,
# c'est l'IP du serveur ; le jour où il l'est, une seule ligne à changer.
SITE_URL ?= http://164.132.255.21
SITE_ROOT ?= /var/www/labs

build: ## Build the site into public/ (published posts only)
	@php bin/build.php

drafts: ## Build including drafts — never deploy this output
	@php bin/build.php --drafts

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
