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
make drafts-list                              # which drafts, which keys
make publish KEY=le-code-qu-on-n-ecrit-pas    # removes draft: true everywhere, then deploys
make unpublish KEY=...                        # back to draft (does not deploy)
```

`publish` acts on **every language of one post** at once, through their shared `key`. That
is the point: a post left in draft in a single language shows greyed out in the selector,
and nobody notices for weeks. The script also warns when a language is missing.

It rewrites the `draft` line only: a publish/unpublish round trip leaves the file identical
byte for byte.

### Scheduling a publication

The front matter's `date` **is** the publication date. A post dated in the future is left
out of the build and comes out on its own, on the day:

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

**What is still missing: no sharing image.** Without `og:image`, LinkedIn shows an empty
thumbnail. It needs either one visual for the whole site or a card generated per post — the
second is worth it the day publication becomes regular.

## This site's own cryptographic inventory

The blog that writes about [Sablier](https://github.com/mesa-black/sablier) is read by it,
and publishes the result:

```bash
make audit       # scans this repository, signs the report, verifies it
```

Three artefacts land in `assets/audit/` and the build copies them to `/audit/`, linked from
the footer of every page. `deploy` depends on `audit`, because a site that displays its own
inventory has to serve a current one — an inventory published once goes wrong without
warning.

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

One Ubuntu machine, one Caddy, one folder of files. Nothing else.

```bash
make provision    # puts the server in the expected state, re-runnable
make deploy       # builds every dated version and publishes
```

`deploy/provision.sh` describes the state of the machine: packages, automatic security
updates, a firewall down to 22/80/443, fail2ban, and the Caddy repository **declared**
rather than added by hand — a distribution upgrade removes third-party sources without
saying so, and re-running the script puts them back. It is re-runnable as often as you like
and ends with a verification: it says what it obtained, it does not assume it.

The scope stops where publishing begins. `make deploy` does the rest, over `rsync`.

`SITE_DOMAIN` defaults to `mesa.black` in the Makefile rather than living only in the
environment: without a default, a `make provision` run without thinking regenerates the
site block on `:80` and undoes HTTPS without saying anything. The certificate is obtained
automatically, `www` and the bare IP redirect to the name, and HSTS is set for a year
without `preload` — that list does not let go in a day.

### How a scheduled publication goes live

The server builds nothing. It has no PHP, no composer, no repository: giving it a build
chain means accepting that a publication fails on a Saturday morning because of a broken
dependency.

Instead, `make deploy` builds **one complete version of the site per publication date** —
today's, and one per scheduled post — and uploads them all:

```
/var/www/labs/releases/2026-09-30/   today's version
/var/www/labs/releases/2026-10-04/   the one coming out on Saturday
/var/www/labs/current -> releases/2026-09-30
```

Caddy serves the `current` link. Every morning at 7, `labs-release.timer` runs a
fifteen-line script that points that link at the most recent version whose date has come,
then prunes the old ones, keeping three. The replacement goes through a rename: no request
can land on a root that does not exist.

Three consequences worth the detour:

- what comes out on Saturday is **already built and browsable** today, so it can be checked
  before leaving;
- rolling back means pointing a link again;
- the timer is `Persistent=true`: if the machine was off at 7, the switch happens at the
  next boot rather than being skipped.

A future publication can be rehearsed without waiting, and that is the only proof that
counts:

```bash
ssh mesa.black 'LABS_TODAY=2026-10-04 /usr/local/bin/labs-release'   # jump forward
ssh mesa.black '/usr/local/bin/labs-release'                         # back to the real day
```

**We tried Ansible first, and threw it away.** For a machine serving static files it
brought idempotence and a Python dependency, against thirty lines of shell doing the same
thing. It becomes relevant again the day there is real server configuration to own —
compose files, secrets, several machines. Not before.
