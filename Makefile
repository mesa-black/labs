.DEFAULT_GOAL := help
.PHONY: help install build drafts serve clean drafts-list publish unpublish provision deploy

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

install: ## Install the dependencies
	@composer install

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
	@ssh mesa.black "sudo SITE_DOMAIN='$(SITE_DOMAIN)' bash -s" < deploy/provision.sh

deploy: build ## Construire (sans brouillons) et publier sur le serveur
	@rsync -az --delete --checksum \
		--exclude '.DS_Store' \
		public/ mesa.black:/var/www/labs/
	@echo "✓ publié — $$(find public -name '*.html' | wc -l | tr -d ' ') pages" 
