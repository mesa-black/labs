---
title: "\"We say what we do\": three times in two days, this blog said something false."
standfirst: "A signature that did not cover the page it sealed. Three digests where the document promised one. A piece cited as published that never ran. Each found by doing what the sentence described, and this is how — because transparency is not an intention, it is an apparatus."
key: on-dit-ce-qu-on-fait
date: 2026-10-06
slug: we-say-what-we-do
---

"We say what we do and we do what we say" is a sentence found on a great many websites, and it costs nothing to write. It only becomes interesting where the two halves drift apart — and they always do, because a claim is written once while the code keeps moving.

So the useful question is not "are we transparent". It is: **by what apparatus does a false sentence get caught, and how fast?**

Here are the last three, all from 5 and 6 October, all printed by our own tools.

## 1. A signature that did not cover the page it sealed

This site now publishes its own cryptographic inventory, produced by [Sablier](https://github.com/mesa-black/sablier) and signed. The link is in the header of every page, the `.sig` file sits beside it, and four commands are enough to check it without us.

While adding that report we wrote a sentence into it: *"the report has not changed since it was signed"*.

An hour later, the end-to-end check — download the report from the site, its signature from the site, the declaration from GitHub, and verify — returned this:

```
signature valide, Ed25519 et post-quantique
  + ML-DSA-65 : vérifiée
```

Then we **altered one word in the report** and ran the same command again. Same answer: valid.

The sentence was false, and it was the worst kind of false: it invited a reader to trust bytes the signature never touched. The cause is structural and no mechanism repairs it — **a report displays its own signature, so it cannot contain it.** The HTML is written after the block exists, and signing the rendered bytes would be circular.

What is signed is the digest of the *findings*, which is the right thing to sign: two renderings of one inventory, in two languages, must give the same value. The only way to tie a page to that digest is to replay the analysis on the same source and compare — and **a public repository is precisely what makes that recomputation possible**. That became the printed instruction, before the sentence saying what the signature establishes.

## 2. Three digests where the document promised one

The previous correction added the missing sentence to the report: *"two renderings of the same inventory, in two languages, give the same value"*.

The next day, a simple question — *if I am reading in Spanish, shouldn't the link point at the Spanish audit?* — had us generate the report in all three languages. The digests came out like this:

```
fr  1839cd93…      en  abb8b217…      es  0e5b2727…
```

Three values, under a paragraph promising one. Two causes, one of them serious.

The small one: the label of an *undeclared* domain is translated — "non déclaré", "undeclared", "no declarado" — and it went into the computation.

The large one: the network probe built its findings out of translated sentences, and a finding's identifier is hashed from that text. So the same server produced a different identifier per language.

Why that is worse than a digest mismatch: this identifier is what accepts a finding — what writes, in a versioned file, "we saw that one, here is why we are leaving it". An identifier that changes with the language means **a decision recorded in French silently stops applying to an analysis run in English**. Nothing would have reported it: the finding simply reappears, with no decision attached.

Everywhere else in that tool, the evidence for a finding is a line of source code — untranslatable by nature. From the probe it is now the fact the handshake returned, and the sentence that explains it lives in a separate field, as it does for every other detector.

## 3. A piece cited as published, and never run

The piece scheduled for 8 October — not out yet as these lines are written — opened on: *"On 2 October, a piece published here ended on an uncomfortable sentence…"*

That piece never ran. It was written, scheduled for 2 October, and withdrawn the day before along with another. Checked: absent from the sitemap, absent from the four versions uploaded to the server, and its URL answers 404.

A reader following the reference would have found nothing — the worst possible error in a piece whose subject is checking what you assert. The sentence now says what happened: written, scheduled, withdrawn the day before, and its last line held. **The withdrawal is part of the story rather than something in its way.**

## What the three have in common

None was found by proofreading. All three were found **by doing what the sentence described**: altering a published report to see whether the signature noticed, generating the document in three languages, following one's own reference.

It is the only method that works, and it has a less noble name than "transparency": **check rather than assume**. The same mistake happened twice in the tooling over those two days, in an even sillier form — a check that asked for a status code instead of a content. PHP's development server answers `200` with the home page for a path that does not exist, so our check reported "online" for an article that had been rebuilt out of existence. **A status code is not a verification.**

## The apparatus, now

A false sentence is not corrected by promising to be more careful. It is corrected by making its refutation automatic.

- **A word budget.** The interview questionnaire had reached 986 words of text to read in order to answer two questions per subject. It is 235 now, and a test fails over 260. A second fails if a trade word returns to the reader's path. Because prose arrives one justified paragraph at a time, and nothing else catches it.
- **Tests on the claim**, not on the code: three languages give one digest; three languages give one identifier; no file path appears in front of the person being asked; an unsigned report claims nothing a signature would prove.
- **Replayable artefacts.** This site's report, its signature and the declaration naming the key are public. The command to verify is printed inside the document, and what it establishes — along with what it does not — right underneath.
- **Withdrawals owned.** Two pieces written, scheduled, then withdrawn the day before. The publication mechanism was fixed in the same pass: a dated version no article claims any more is dropped from the server, since otherwise it would be served on the day with the withdrawn text inside it.

## What we decided not to measure

Transparency is also for saying what you do not do, and why.

This site **does not count its visits**. There is no access log at all: checked, zero request lines recorded. An honest counter is possible — Caddy's log, the IP address dropped at source, no personal data kept — but it would count *requests*, not people, and robots would inflate the figure. A counter announcing "visitors" while counting requests is exactly the false assurance the rest of this work refuses. So no.

It has **no comments** either. That would need an executable on the server, a database, moderation, spam defence and the storage of other people's names — five things this site is defined by not having. Instead, an address at the end of every piece. It costs one line and filters on its own: whoever takes the trouble to write has something to say.

## What it produced

- **Three false claims corrected in two days**, each with the test that fails if it comes back.
- **One serious defect found in passing**: audit decisions silently detaching from their finding depending on the language of the run.
- **Two checks rewritten** because they measured a status code rather than a content.
- **Zero lines of communication added.** There is no "our commitments" page on this site, and there will not be one.

## Good practice

- Do what the sentence describes, for real, once. Alter the signed file, generate in three languages, follow your own link: that is where claims fall over, not in proofreading.
- Write first what a guarantee does **not** cover. That is the half everybody forgets, and it is the one that manufactures misplaced trust.
- Turn every kept promise into a test that fails when it stops being kept. A claim with no automatic refutation is a claim that will be false one day without anybody knowing.
- Verify a content, never a status code.
- Say what you withdrew. An explained withdrawal costs a paragraph; a hole in a public history costs the trust you were trying to build.

## Things to watch

- **An apparatus is not a virtue.** None of the above guarantees the next sentence. It only guarantees that a claim already tested will not quietly decay.
- The three errors in this piece were found in two days because somebody was **using** these tools that day. A tool nobody uses keeps its false claims indefinitely, and no test writes itself in our place.
- Publishing your mistakes has a cost worth naming: to a fast reader it looks like amateurism. We do it anyway, because the alternative — correcting in silence — protects the author and leaves the reader with the false version.
