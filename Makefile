.DEFAULT_GOAL := help
.PHONY: help install build drafts preview serve clean drafts-list publish unpublish audit deps provision deploy

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

# Who attests the date. The signature says which key signed and what it signed;
# `signed_at` is read off this laptop's clock, so it is worth nothing against
# somebody who does not trust us — and "we had inventoried before the deadline"
# is a claim about a date. The EU roadmap makes the inventory a First Step due
# 31.12.2026, which is the reason this line exists.
#
# Certum (Asseco Data Systems, Poland): inside the EU, free, and its root is in
# the ordinary certificate store — so a reader verifies the token with stock
# openssl and nothing of ours. Checked against the alternatives: Sectigo returns
# a token openssl cannot resolve to its signer, FreeTSA and the Belgian federal
# authority are self-signed and would need us to ship a root certificate for
# anybody to check a date. Override it if you would rather trust somebody else:
# that is the point of it being a variable.
#
# Three of them, in three jurisdictions, because one authority is one point of
# trust. An authority only ever sees the digest, so there is nothing to
# coordinate and none of them knows it is not alone — the cost is one HTTP
# request each. What it buys: each gives an independent upper bound, so the date
# we can defend without anyone having to trust a single operator is the latest of
# the three, and forging the earliest no longer gets anybody anything. Certum
# stays first: it holds the oldest attestation of these findings, and the first
# slot is the one every printed command points at.
TSA ?= http://time.certum.pl,http://timestamp.globalsign.com/tsa/r6advanced1,http://timestamp.digicert.com

# The published inventory names the version that produced it, in its masthead and
# in the Threema summary. That line was a lie for a while: the audit is generated
# from a working copy of sablier, not from a release, so the report said 0.9.0
# while carrying three features that release does not have. The tool's own guard
# only compares its constant against a tag when a tag is being cut, which is
# right for a working branch and leaves this hole at the one place it matters —
# publication. So the check lives here, where the artefact is produced.
# UNRELEASED=1 for a local run that is not meant to be published.
audit: ## Produce the site's signed cryptographic inventory, in three languages
	@test -x "$(SABLIER)" || { echo "✗ sablier not found: $(SABLIER) (SABLIER=<path> make audit)"; exit 1; }
	@test -f "$(SABLIER_KEY)" || { echo "✗ signing key not found: $(SABLIER_KEY)"; exit 1; }
	@src=$$(cd "$$(dirname "$(SABLIER)")/.." && pwd); \
	 v=$$(php -r "require '$$src/src/Version.php'; echo Sablier\\Version::NUMBER;"); \
	 tag=$$(git -C "$$src" describe --exact-match --tags HEAD 2>/dev/null || true); \
	 dirty=$$(git -C "$$src" status --porcelain 2>/dev/null); \
	 if [ -z "$(UNRELEASED)" ] && { [ "$$tag" != "v$$v" ] || [ -n "$$dirty" ]; }; then \
		echo "✗ sablier is not at a clean release: constant $$v, HEAD $${tag:-untagged}$${dirty:+, working tree dirty}"; \
		echo "  the report would print a version it was not built from. Tag the release, or UNRELEASED=1 for a local run."; \
		exit 1; \
	 fi; \
	 printf '  sablier %s (%s%s)\n' "$$v" "$${tag:-untagged}" "$${dirty:+, working tree dirty — published under UNRELEASED}"
	@# One rendering per language, because a reader who clicked a Spanish word
	@# and received a French document learnt nothing. The signature covers the
	@# findings and not the page, so the three carry the same digest — which the
	@# check below prints side by side rather than asserting.
	@# One request per language rather than one token copied three times. The
	@# digest is identical across the three, so a single token would be the same
	@# statement about all of them — but a report only prints the attested date
	@# when it was asked for one, and a document sitting beside a .tsr it never
	@# mentions is the kind of silent gap this whole site is about. Three requests
	@# to a free authority cost nothing.
	@for lang in fr en es; do \
		dir=assets/audit; [ "$$lang" = fr ] || dir=assets/audit/$$lang; \
		mkdir -p "$$dir"; \
		$(SABLIER) scan . --out="$$dir/report.html" --audit="$$dir/audit.html" \
			--lang=$$lang --sign="$(SABLIER_KEY)" --timestamp=$(TSA) --quiet; \
		test -s "$$dir/report.html.tsr" \
			|| { echo "✗ no token for $$lang: the audit would claim a date nobody attests"; exit 1; }; \
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

# The dependencies are three Composer packages, and the site's own inventory
# names their versions — which is a claim about them being sound, and nothing was
# checking it. `--locked` reads composer.lock, so the check describes what is
# actually deployed and runs without an install.
deps: ## Check the dependencies against the advisory database
	@composer audit --locked --no-interaction

deploy: deps audit ## Publish: one version of the site per publication date, then switch
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
