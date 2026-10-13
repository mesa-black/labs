# BlackMesa Labs

BlackMesa's engineering blog. **Markdown in, static HTML out, no runtime in production.**

## Why not a CMS

The published site is a folder of files. No database, no admin interface, no
authentication, no backup to watch: the blog cannot fall over for an application reason,
and it has no attack surface of its own. The price is that you write in a text editor
rather than in a browser — which is what we were doing anyway.

**The threshold for changing our minds is written down, and it has already moved once.** It
said: pagination, tags, multilingual and search → switch to Hugo. Multilingual arrived and
cost ~80 lines, which is less than the migration it would have triggered. So we did it
here, and the threshold tightened: **pagination, tags or search → we stop and switch.**
Written down so that next time the question is settled in a minute instead of being
reopened.

## Getting started

```bash
make install     # Composer dependencies
make serve       # build with drafts + http://localhost:8000
```

| Command | Effect |
|---|---|
| `make build` | Builds `public/` — **published posts only** |
| `make drafts` | Same, including drafts. Never deploy this |
| `make serve` | `drafts` + local server on port 8000 |
| `make preview` | The site as of a given date, served locally: `make preview DATE=2026-10-08` |
| `make clean` | Removes `public/` |

No PHP on the workstation is needed: without one, the Makefile runs the PHP the image is
built with (the Dockerfile's `php` stage), in a Podman container built on first use. A local
build and the published one then cannot disagree — they once did, on reading times,
because two PHPs counted words differently.

`make build` fails when no post is published: deliberately, so that an empty site cannot be
deployed unnoticed.

`make preview` exists because `deploy` rebuilds `public/` once per release date and
finishes with today's — it silently replaces any preview of a future state, and with the
deployed site's URLs. With no argument it shows the furthest scheduled date, so a preview
carries everything queued, and it prints which date it is showing.

## Writing a post

A file in `content/posts/<language>/`, named `YYYY-MM-DD-slug.md`:

```markdown
---
title: "The title, as it will be displayed"
standfirst: "One opening sentence. Optional but recommended."
key: my-post               # ties the translations together
date: 2026-09-27
slug: my-post              # optional: otherwise taken from the filename
draft: true                # remove to publish
---

The body in markdown. `##` become the subheadings.
```

### Two kinds of post

A **full post** lives here and is authoritative here.

A **pointer** introduces, in a few paragraphs, a case study published on
[Show me the REX](https://showmetherex.com) and links to it without copying the text:

```markdown
---
title: "…"
date: 2026-09-25
pointer: true
rex: https://showmetherex.com/feedback/the-slug
---
```

The **first** mention of "Show me the REX" in a post's body automatically becomes a link to
the platform, in the reader's language. The first only: ten identical links on one page
reads badly, and search engines see stuffing. The HTML is walked with tags and text kept
apart, so a link is never written inside a link or inside a code block.

This is deliberate and it is not cosmetic: **the same text published on two domains, and
search engines ignore one of them**. A pointer therefore emits a `canonical` tag towards
SMTR, which stays the source. New engineering subjects are canonical here and do not go to
SMTR — which is the entire reason this blog exists.

`title`, `date` and `key` are required — the build stops, naming the offending file, rather
than publishing an incomplete post.

### Three languages

French at the root, English under `/en/`, Spanish under `/es/` — **the same URL scheme as
showmetherex.com**, so that a reader moving between the two sites is not lost.

Translations of one post recognise each other by their shared `key`, and each has its own
`slug`: an English title deserves an English URL. The language selector then jumps to the
translation of the same post rather than to the home page. A language the post does not
exist in stays visible but inert — more honest than hiding it.

`hreflang` tags are generated from the translations actually present.

### Publishing

```bash
make drafts-list                              # which drafts, which scheduled pieces, which keys
make publish KEY=le-code-qu-on-n-ecrit-pas    # draft: true removed everywhere, audit, commit, push
make unpublish KEY=...                        # back to draft, commit, push
make push [M="message"]                       # whatever changed under content/: commit, push
```

**Publishing is a push.** The site is a container image that CI builds from what is in Git,
and [k3s-stack](https://github.com/mesa-black/k3s-stack) deploys it to mesa.black through
Argo CD: nothing on the workstation talks to the server any more. About five minutes after
the push, the new version is online — without an interruption.

`make push` is for everything else: drafts saved, a typo fixed, a dated correction. A draft
is never built, so pushing one publishes nothing. `NO_PUSH=1` commits without pushing, to
look before it leaves.

`publish` acts on **every language of one post** at once, through their shared `key`. That
is the point: a post left in draft in a single language shows greyed out in the selector,
and nobody notices for weeks. The script also warns when a language is missing.

It rewrites the `draft` line only: a publish/unpublish round trip leaves the file identical
byte for byte.

### Scheduling a publication

The front matter's `date` **is** the publication date. A post dated in the future comes out
on its own, **on that day at 07:00 Paris time** — in the morning, when people read. Publish
it whenever it is ready, as long as it is pushed before its date:

```bash
make drafts-list      # the drafts, and separately, the scheduled posts
```

A draft and a scheduled post are two distinct states, and confusing them leads to
rewriting a text that was already reviewed. A draft is not finished; a scheduled post is,
and it is waiting its turn.

Publishing everything on the same day is the best way to lose a reader: they read one, see
six left, and close the tab. Spreading publications out gives a reason to come back.

Reading time is computed on the rendered text rather than on the markdown: syntax the
reader never sees does not count.

## Structure

```
bin/build.php     the generator, in full
content/posts/    the posts, in markdown, one folder per language
templates/        the Twig templates (base, list, post, Atom feed)
assets/style.css  one stylesheet, with no build step
assets/audit/     this site's own cryptographic inventory, signed — see below
public/           the output — generated, never versioned
```

`public/` is emptied on every build: a page whose slug changed cannot survive the next
generation.

## The design

**One family played on its weights** rather than a display face and a text face: the
hierarchy comes from weight and tracking. **Archivo** serves headings and body alike. **IBM
Plex Mono** is strictly reserved for what comes from a machine — commands, versions, code
excerpts — so that the reader learns that monospaced text was not written for them.

**Cream** ground, almost-black ink. **Teal is the accent** (links, subheadings, highlighting
of important passages), **amber marks what is wrong** or unfinished: a draft, a warning. No
colour is decorative.

Post bodies are **justified with automatic hyphenation** — justification alone, in a narrow
column, digs white rivers. Hyphenation relies on the page's `lang`, hence its presence on
`<html>`. Headings are never justified: they are distributed with `text-wrap: balance`.
Below 34rem justification is switched off: even hyphenated, a phone column fills with
holes.

Light and dark themes through CSS tokens, including when the visitor lets their system
decide. The dark one is warm too, to stay consistent with the cream.

## SEO and answer engines

Generated on every build, with nothing to maintain:

- **`sitemap.xml`** covering the three languages, each URL carrying its alternates;
- **`robots.txt`** declaring the sitemap and **explicitly allowing the answer engines'
  crawlers** (GPTBot, ClaudeBot, PerplexityBot). That is a choice: being cited is the
  reason to write here. Turning those lines into `Disallow` is all it takes to change our
  minds;
- **`canonical`** on every page — towards the case study for a pointer, self-referencing
  otherwise;
- reciprocal **`hreflang`** plus `x-default` towards French;
- **Open Graph** and Twitter Card, so a link pasted on LinkedIn does not come out bare;
- **JSON-LD** `BlogPosting` on posts (title, standfirst, date, language, author, word
  count) and `Blog` on the home pages. That is what lets an answer engine cite correctly:
  who wrote it, when, for which organisation;
- a **404 page** in the site's style.

What helps as much without being a tag: a standfirst that sums the post up at the top of
the page, explicit subheadings, short paragraphs. Extractable text is cited better than
flowing text.

**Sharing cards are generated, one per piece and per language.** `bin/cards.php` draws a
1200×630 PNG at build time with gd and the two vendored faces: a kicker, the piece's
title, and the date with the reading time. `og:image` points at it. Nothing to design per
article, nothing to forget: a piece that exists has a card, and a piece that is withdrawn
takes its card with it.

The three home pages have one too, carrying the tagline rather than a title — they had
none for days, so the link people actually paste, the site itself, was the one that
unfurled as an empty rectangle while every article had an image.

## This site's own cryptographic inventory

The blog that writes about [Sablier](https://github.com/mesa-black/sablier) is read by it,
and publishes the result:

```bash
make audit       # scans this repository, signs the report, verifies it
```

Three artefacts land in `assets/audit/` and the build copies them to `/audit/`, linked from
the footer of every page. `make publish` runs `audit`, because a site that displays its own
inventory has to serve a current one — an inventory published once goes wrong without
warning. It keeps the result **only when the findings changed**: when they did not, Sablier
keeps the original signature and timestamp tokens — the oldest attestation is the one worth
having — and a re-run only re-renders the pages with a new date, which is noise in Git, not
information. `NO_AUDIT=1` skips it; CI still compares the source with its reference and
refuses to build the image if new cryptography appears.

Scanned with no declaration it returns nothing at all: a static generator encrypts nothing,
signs nothing, hashes nothing. All of this site's cryptography is in its transport and in
the ssh key that deploys it, and neither is a file here. So `sablier.json` declares what
this repository is — almost everything in it is written to be served in the clear, and the
confidentiality owed is zero, by construction rather than by neglect — and it declares the
probe host, because the real cryptography is negotiated rather than written.

The report is signed by the key whose public halves are in `sablier.json`; the private
halves live outside the repository. Changing the expected key is therefore a commit
somebody reads, which is what makes the signature worth anything. Anybody can check it
without us:

```bash
curl -O https://mesa.black/audit/report.html
curl -O https://mesa.black/audit/report.html.sig
curl -O https://raw.githubusercontent.com/mesa-black/labs/main/sablier.json
sablier verify report.html.sig --declare=sablier.json
```

What that establishes is printed in the report itself, and so is what it does not: the
signature covers the digest of the findings, not the bytes of the page. A report displays
its own signature, so it cannot contain it. Tying the two together means replaying the scan
on the same state of this repository and comparing the digest — which this repository being
public is what makes possible.

## The server

The site runs on mesa.black as a container in **k3s**, deployed by **Argo CD** from
[k3s-stack](https://github.com/mesa-black/k3s-stack) (`spoke/apps/labs`), which documents the
whole chain. In short:

```
push here ──► CI: build · dependencies · cryptography ──► image ghcr.io/mesa-black/labs:<sha>
          └─► CI commits the new tag to k3s-stack ──► Argo CD ──► rolling update on mesa.black
```

- `Dockerfile`: PHP builds **one complete version of the site per publication date still
  ahead**, plus today's; Caddy serves them on :8080 as a non-root user, with the site's
  headers (`container/Caddyfile`).
- `container/labs-switch`, a sidecar in the pod: every minute it points the served
  directory at the newest version whose date has come — at 07:00 Paris, from the local
  hour, so that the two nights a year the clocks change do not move it. What comes out on
  Saturday is already built and in the image today; the workstation can be off.
- Rolling back is a `git revert` of the `labs: deploy` commit in k3s-stack.

Host Caddy is still in front for now (`make provision`, `deploy/provision.sh`): it
terminates TLS, redirects `www` and the bare IP, and proxies to the pod's Service. It goes
once the other service on the machine has moved to k3s too.

The old path — dated releases uploaded by rsync under `/var/www/labs`, switched by
`labs-release.timer` — is still installed on the server and will be removed once a scheduled
post has gone out on its own from the pod. Nothing uses it any more.
