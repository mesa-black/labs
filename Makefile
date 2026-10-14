.DEFAULT_GOAL := help
.PHONY: help install build drafts preview serve clean drafts-list publish unpublish push audit audit-if-changed deps provision

# --- PHP ---------------------------------------------------------------------
# The workstation's PHP if it has one; otherwise the very PHP the image is built
# with, in a container (the Dockerfile's `php` stage). The second is the
# default here on purpose: a local build and the published one once disagreed
# on reading times because two PHPs counted words differently.
#
# Paths are mounted at the same place inside the container as outside, so that
# every path in this file means the same thing on both sides.
PHP_IMAGE ?= localhost/labs-php
SABLIER_DIR := $(abspath ../sablier)
TTY := $(shell [ -t 0 ] && echo -t)
# Sablier and its key are mounted only when they exist: `make build` must not
# need the audit's tooling.
MOUNTS := -v "$(CURDIR):$(CURDIR)" \
	$(if $(wildcard $(SABLIER_DIR)),-v "$(SABLIER_DIR):$(SABLIER_DIR):ro") \
	$(if $(wildcard $(HOME)/.sablier),-v "$(HOME)/.sablier:$(HOME)/.sablier:ro")
RUN_IN_PHP = podman run --rm -i $(TTY) -e SITE_URL -e HOME=/tmp $(MOUNTS) -w "$(CURDIR)" $(1) $(PHP_IMAGE)
ifeq ($(shell command -v php),)
PHP_DEPS := .php-image
PHP = $(call RUN_IN_PHP) php
COMPOSER = $(call RUN_IN_PHP) composer
SERVE = $(call RUN_IN_PHP,-p 127.0.0.1:$(1):$(1)) php -S 0.0.0.0:$(1)
else
PHP_DEPS :=
PHP = php
COMPOSER = composer
SERVE = php -S localhost:$(1)
endif

# Built once, rebuilt when the Dockerfile changes. Ignored by Git.
.php-image: Dockerfile
	@podman build -q --target php -t $(PHP_IMAGE) . >/dev/null
	@touch $@

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

install: $(PHP_DEPS) ## Install the dependencies
	@$(COMPOSER) install

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

build: $(PHP_DEPS) ## Build the site into public/ (published posts only)
	@$(PHP) bin/build.php

drafts: $(PHP_DEPS) ## Build including drafts — never deploy this output
	@$(PHP) bin/build.php --drafts

# A build rebuilds public/ for the date it is given, and nothing keeps it apart:
# it therefore overwrites any preview of a future state, silently, and with the
# deployed site's URLs. That happened twice, once while somebody was looking for
# the piece and could not find it. A dedicated target, which says what it shows
# and for which date, costs four lines.
PREVIEW_PORT ?= 8000

preview: $(PHP_DEPS) ## Preview the site as of a date: make preview [DATE=2026-10-08]
	@d="$(DATE)"; \
	 test -n "$$d" || d=$$($(PHP) bin/build.php --release-dates | tail -1); \
	 test -n "$$d" || d=$$(date +%F); \
	 SITE_URL="http://localhost:$(PREVIEW_PORT)" $(PHP) bin/build.php --as-of="$$d" >/dev/null; \
	 printf '\n  the site as of %s · http://localhost:%s/\n' "$$d" "$(PREVIEW_PORT)"; \
	 printf '  %s\n\n' "$$(find public -name index.html | wc -l | tr -d ' ') pages, Ctrl-C to stop"; \
	 $(call SERVE,$(PREVIEW_PORT)) -t public

serve: drafts ## Build with drafts and serve on http://localhost:8000
	@$(call SERVE,8000) -t public

clean: ## Remove the generated site
	@rm -rf public

# --- publication -------------------------------------------------------------
# Publishing is a push. The site is an image built by CI from what is in Git,
# and Argo CD deploys it (github.com/mesa-black/k3s-stack): nothing here talks
# to the server any more. A piece goes live on its `date` at 07:00 Paris — on
# the day of the push if that date has come, on its own later otherwise: every
# dated version is in the image, and a small process in the pod switches.
#
# NO_PUSH=1 commits without pushing (to look before it leaves).

drafts-list: $(PHP_DEPS) ## List the drafts and the scheduled pieces
	@$(PHP) bin/publish.php

publish: $(PHP_DEPS) ## Publish a piece in every language, audit, commit, push: make publish KEY=slug
	@test -n "$(KEY)" || { $(PHP) bin/publish.php; exit 1; }
	@$(PHP) bin/publish.php "$(KEY)"
	@$(MAKE) --no-print-directory audit-if-changed
	@d=$$(grep -lE '^key:[[:space:]]*"?$(KEY)"?[[:space:]]*$$' content/posts/*/*.md | xargs grep -hE '^date:' | head -1 | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}'); \
	 today=$$(TZ=Europe/Paris date +%F); \
	 if [ "$$d" \> "$$today" ]; then when="scheduled for $$d 07:00 Paris"; else when="live after the deployment (dated $$d)"; fi; \
	 git add content assets/audit && git commit -q -m "publish: $(KEY), $$when" && \
	 printf '  committed: publish %s — %s\n' "$(KEY)" "$$when"
	@$(MAKE) --no-print-directory _push

unpublish: $(PHP_DEPS) ## Put a piece back to draft, commit, push: make unpublish KEY=slug
	@test -n "$(KEY)" || { $(PHP) bin/publish.php; exit 1; }
	@$(PHP) bin/publish.php "$(KEY)" --draft
	@git add content && git commit -q -m "unpublish: $(KEY)" && printf '  committed: unpublish %s\n' "$(KEY)"
	@$(MAKE) --no-print-directory _push

# Drafts, edits, corrections: whatever changed under content/, committed and
# pushed. A draft is never built, so pushing one publishes nothing.
push: ## Commit and push what changed under content/: make push [M="message"]
	@git add content
	@git diff --cached --quiet && { echo "  nothing changed under content/"; exit 0; } || \
	 { git commit -q -m "$${M:-content: $$(git diff --cached --name-only | sed 's|content/posts/||' | paste -sd, -)}" && \
	   printf '  committed: %s\n' "$$(git log -1 --format=%s)" && $(MAKE) --no-print-directory _push; }

_push:
	@if [ -n "$(NO_PUSH)" ]; then echo "  NO_PUSH: not pushed"; else \
	   git push -q && printf '  pushed — CI: https://github.com/mesa-black/labs/actions\n'; fi

# --- inventaire cryptographique ----------------------------------------------
# The site publishes what Sablier says about it, signed by the key its
# declaration designates. Two reasons to do it here rather than by hand: an
# inventory published once goes wrong without warning, and `publish` therefore
# runs it (keeping it only when the findings change) so that what is served
# matches what is online.
SABLIER ?= $(SABLIER_DIR)/bin/sablier
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
audit: $(PHP_DEPS) ## Produce the site's signed cryptographic inventory, in three languages
	@test -x "$(SABLIER)" || { echo "✗ sablier not found: $(SABLIER) (SABLIER=<path> make audit)"; exit 1; }
	@test -f "$(SABLIER_KEY)" || { echo "✗ signing key not found: $(SABLIER_KEY)"; exit 1; }
	@src=$$(cd "$$(dirname "$(SABLIER)")/.." && pwd); \
	 v=$$($(PHP) -r "require '$$src/src/Version.php'; echo Sablier\\Version::NUMBER;"); \
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
		$(PHP) $(SABLIER) scan . --out="$$dir/report.html" --audit="$$dir/audit.html" \
			--lang=$$lang --sign="$(SABLIER_KEY)" --timestamp=$(TSA) --quiet; \
		test -s "$$dir/report.html.tsr" \
			|| { echo "✗ no token for $$lang: the audit would claim a date nobody attests"; exit 1; }; \
	done
	@printf '  digests, one per language:\n'
	@for lang in fr en es; do \
		dir=assets/audit; [ "$$lang" = fr ] || dir=assets/audit/$$lang; \
		printf '    %s  %s\n' "$$lang" "$$($(PHP) -r 'echo json_decode(file_get_contents($$argv[1]), true)["digest"];' "$$dir/report.html.sig")"; \
	done
	@$(PHP) $(SABLIER) verify assets/audit/report.html.sig --declare=sablier.json

# Run the audit, and keep it only if it says something new. Sablier keeps the
# signature and the timestamp tokens when the findings have not changed — the
# oldest attestation is the one worth having — so an unchanged run only
# re-renders the pages with a new date. That is noise in Git, not information:
# discarded. NO_AUDIT=1 skips it (offline, say); CI still compares the source
# with its reference and blocks the image if new cryptography appears.
audit-if-changed:
	@if [ -n "$(NO_AUDIT)" ]; then echo "  NO_AUDIT: inventory not refreshed"; exit 0; fi; \
	 $(MAKE) --no-print-directory $(addprefix -f ,$(MAKEFILE_LIST)) audit && \
	 if git diff --quiet -- $$(git ls-files 'assets/audit/*.sig' 'assets/audit/**/*.sig') && \
	    [ -z "$$(git ls-files --others --exclude-standard assets/audit)" ]; then \
		git restore assets/audit && echo "  findings unchanged: the re-rendered inventory is discarded"; \
	 else echo "  findings changed: the new signed inventory will be committed"; fi

# --- serveur -----------------------------------------------------------------
# `provision` describes the machine: host Caddy in front of the site, which runs
# in k3s. There is no `deploy` any more: deploying is pushing (see publication).

provision: ## Put the server in the expected state (re-runnable)
	@rsync -az --delete deploy/ mesa.black:/tmp/labs-deploy/
	@ssh mesa.black "sudo SITE_DOMAIN='$(SITE_DOMAIN)' bash /tmp/labs-deploy/provision.sh"

# The dependencies are three Composer packages, and the site's own inventory
# names their versions — which is a claim about them being sound, and nothing was
# checking it. `--locked` reads composer.lock, so the check describes what is
# actually deployed and runs without an install.
deps: $(PHP_DEPS) ## Check the dependencies against the advisory database
	@$(COMPOSER) audit --locked --no-interaction
