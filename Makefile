.DEFAULT_GOAL := help
.PHONY: help install build drafts serve clean

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
