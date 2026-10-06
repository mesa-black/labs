.DEFAULT_GOAL := help
.PHONY: help install build drafts preview serve clean drafts-list publish unpublish audit provision deploy

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

install: ## Install the dependencies
	@composer install

# The site's public address. It feeds the canonical URLs, the hreflang tags, the
# sitemap and the sharing metadata — so a local build and a deployed build cannot
# share one default.
SITE_URL ?= https://mesa.black

# The name Caddy serves, and the one it asks a certificate for. With a default,
# and not only in the environment: without one, a `make provision` run without
# thinking regenerates the block on `:80` and undoes HTTPS without saying
# anything. A domain is decided once, and that decision belongs to the
# repository.
SITE_DOMAIN ?= mesa.black
SITE_ROOT ?= /var/www/labs

build: ## Build the site into public/ (published posts only)
	@php bin/build.php

drafts: ## Build including drafts — never deploy this output
	@php bin/build.php --drafts

# `deploy` rebuilds public/ once per publication date and finishes with today's:
# it therefore overwrites any preview of a future state, silently, and with the
# deployed site's URLs. That happened twice, once while somebody was looking for
# the piece and could not find it. A dedicated target, which says what it shows
# and for which date, costs four lines.
PREVIEW_PORT ?= 8000

preview: ## Preview the site as of a date: make preview [DATE=2026-10-08]
	@d="$(DATE)"; \
	 test -n "$$d" || d=$$(php bin/build.php --release-dates | tail -1); \
	 test -n "$$d" || d=$$(date +%F); \
	 SITE_URL="http://localhost:$(PREVIEW_PORT)" php bin/build.php --as-of="$$d" >/dev/null; \
	 printf '\n  the site as of %s · http://localhost:%s/\n' "$$d" "$(PREVIEW_PORT)"; \
	 printf '  %s\n\n' "$$(find public -name index.html | wc -l | tr -d ' ') pages, Ctrl-C to stop"; \
	 php -S localhost:$(PREVIEW_PORT) -t public

serve: drafts ## Build with drafts and serve on http://localhost:8000
	@php -S localhost:8000 -t public

clean: ## Remove the generated site
	@rm -rf public

# --- publication -------------------------------------------------------------

drafts-list: ## List the drafts and their key
	@php bin/publish.php

publish: ## Publish a piece in every language, then deploy: make publish KEY=slug
	@test -n "$(KEY)" || { php bin/publish.php; exit 1; }
	@php bin/publish.php "$(KEY)"
	@$(MAKE) --no-print-directory deploy

unpublish: ## Put a piece back to draft (does not deploy): make unpublish KEY=slug
	@test -n "$(KEY)" || { php bin/publish.php; exit 1; }
	@php bin/publish.php "$(KEY)" --draft
	@echo "  → 'make deploy' to actually take it off the site"

# --- inventaire cryptographique ----------------------------------------------
# The site publishes what Sablier says about it, signed by the key its
# declaration designates. Two reasons to do it here rather than by hand: an
# inventory published once goes wrong without warning, and `deploy` therefore
# depends on it so that what is served always matches what is online.
SABLIER ?= ../sablier/bin/sablier
SABLIER_KEY ?= $(HOME)/.sablier/blackmesa-labs.key

audit: ## Produce the site's signed cryptographic inventory, in three languages
	@test -x "$(SABLIER)" || { echo "✗ sablier not found: $(SABLIER) (SABLIER=<path> make audit)"; exit 1; }
	@test -f "$(SABLIER_KEY)" || { echo "✗ signing key not found: $(SABLIER_KEY)"; exit 1; }
	@# One rendering per language, because a reader who clicked a Spanish word
	@# and received a French document learnt nothing. The signature covers the
	@# findings and not the page, so the three carry the same digest — which the
	@# check below prints side by side rather than asserting.
	@for lang in fr en es; do \
		dir=assets/audit; [ "$$lang" = fr ] || dir=assets/audit/$$lang; \
		mkdir -p "$$dir"; \
		$(SABLIER) scan . --out="$$dir/report.html" --audit="$$dir/audit.html" \
			--lang=$$lang --sign="$(SABLIER_KEY)" --quiet; \
	done
	@printf '  digests, one per language:\n'
	@for lang in fr en es; do \
		dir=assets/audit; [ "$$lang" = fr ] || dir=assets/audit/$$lang; \
		printf '    %s  %s\n' "$$lang" "$$(php -r 'echo json_decode(file_get_contents($$argv[1]), true)["digest"];' "$$dir/report.html.sig")"; \
	done
	@$(SABLIER) verify assets/audit/report.html.sig --declare=sablier.json

# --- serveur -----------------------------------------------------------------
# `provision` describes the machine, `deploy` puts the site on it. One tool, one
# role.

provision: ## Put the server in the expected state (re-runnable)
	@rsync -az --delete deploy/ mesa.black:/tmp/labs-deploy/
	@ssh mesa.black "sudo SITE_DOMAIN='$(SITE_DOMAIN)' SITE_ROOT='$(SITE_ROOT)' bash /tmp/labs-deploy/provision.sh"

deploy: audit ## Publier : une version du site par date de parution, puis bascule
	@ssh mesa.black "mkdir -p $(SITE_ROOT)/releases"
	@# Filtered to date-shaped tokens: a single stray line on stdout — a PHP
	@# warning, once — turned every word of it into a release directory on the
	@# server, each holding a full copy of the site. The loop now ignores
	@# anything that is not YYYY-MM-DD.
	@for d in $$(php bin/build.php --release-dates | grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}$$') $$(date +%F); do \
		SITE_URL="$(SITE_URL)" php bin/build.php --as-of=$$d >/dev/null; \
		rsync -az --delete --checksum --exclude '.DS_Store' \
			public/ mesa.black:$(SITE_ROOT)/releases/$$d/; \
		printf '  version %s — %s pages\n' "$$d" \
			"$$(find public -name '*.html' | wc -l | tr -d ' ')"; \
	done
	@printf '%s\n' $$(php bin/build.php --release-dates | grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}$$') $$(date +%F) \
		| ssh mesa.black "cat > $(SITE_ROOT)/releases/.expected"
	@ssh mesa.black /usr/local/bin/labs-release
