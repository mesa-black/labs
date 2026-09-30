.DEFAULT_GOAL := help
.PHONY: help install build drafts serve clean provision deploy

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

# --- serveur -----------------------------------------------------------------
# `provision` décrit la machine, `deploy` y dépose le site. Un outil, un rôle.

provision: ## Mettre le serveur dans l'état attendu (relançable)
	@ssh mesa.black "sudo SITE_DOMAIN='$(SITE_DOMAIN)' bash -s" < deploy/provision.sh

deploy: build ## Construire (sans brouillons) et publier sur le serveur
	@rsync -az --delete --checksum \
		--exclude '.DS_Store' \
		public/ mesa.black:/var/www/labs/
	@echo "✓ publié — $$(find public -name '*.html' | wc -l | tr -d ' ') pages" 
