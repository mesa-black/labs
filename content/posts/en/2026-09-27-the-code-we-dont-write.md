---
title: "The cheapest feature is the one you don't build"
standfirst: "Three signals that say 'do not write this code' — and what they saved us in a single day."
date: 2026-09-27
key: le-code-qu-on-n-ecrit-pas
slug: the-code-we-dont-write
draft: true
---

Digital sobriety is usually discussed as an optimisation problem: lighter images, better caching, a greener region. All true, all marginal. On our own platform, hosting emits little — a single server in France, on one of the least carbon-intensive grids in Europe.

The real waste sits somewhere else, and nobody measures it: **the code written for nothing**. A migration redone, a tool bought then abandoned, a feature shipped and never opened. Those cost incomparably more — in machines, in electricity, in human months — than any front-end optimisation will ever save.

So we asked a question we had never formulated: how do you *decide* not to build something?

## The challenge: we measure what we ship, never what we avoid

Every team knows how to celebrate a release. None knows how to celebrate the feature it did not write — there is no ticket, no demo, no line in the changelog. The decision leaves no trace, so it is never made explicitly: it is postponed, meeting after meeting, until someone builds the thing out of fatigue.

We gave ourselves three signals. Here they are, with what each one actually saved on one ordinary working day.

## Signal 1 — the thing broke and nobody said anything

Our client "What's new" popup reads its entries from commit messages tagged `Client:`. Auditing it, we found that **42 of the 65 entries ever written had never been displayed**: Git only reads a trailer in the commit's last paragraph, and the line was almost always written above the signature. Two thirds of the feature had been dead for weeks.

The instinct is to rush and fix it. The useful question comes first: *nobody complained*. Not a single client, not a single team member noticed that two thirds of their release notes were missing. That is data about the feature, not about the bug.

We fixed it, because the fix was twenty lines and the content already existed. But had it required a rewrite, the honest answer would have been to delete the popup. **A broken feature nobody reports is a candidate for removal, not for repair.**

## Signal 2 — the work would be invisible

Same day, another request: translate the client area into English and Spanish. We measured before writing: 23 templates, ~426 strings, 83 flash messages, 192 form labels, 19 e-mails. Around **700 strings, 1,400 translations**.

Then we looked for the reader. There was none. No language preference is stored on an account, and the language switcher only exists in the public header. A visitor browsing in Spanish who signs in lands on a French page, with no way back short of editing the URL by hand. We would have produced 1,400 translations that nobody could reach.

So we built the two-hour prerequisite — record the language, add the switcher to the client area, honour it after sign-in — and **we stopped there**. The translation will be done the day a client asks for it, and it will then be visible. The day nobody asks, it will never be written.

## Signal 3 — the discipline is cheaper than the tool

"Let's harden our SRE" almost always turns into a shopping list: error tracking, uptime monitoring, dashboards. We had parked all of it for budget reasons, and the parking turned out to be a favour.

Because the actual gap was not a tool. An encrypted database backup had been running nightly for weeks — and **had never once been restored**. We ran the drill: dump, encrypt, decrypt, restore into a throwaway database, compare the row counts table by table, check that a wrong key really fails. It passed, and it cost nothing.

It also surfaced two single points of failure no dashboard would have shown: production and backups live in the same provider account, and the key that decrypts the secrets exists only online. Both fixes are free and take five minutes. **We measured and rehearsed instead of buying.**

## What these signals do not say

"Nobody needs it" is also the perfect excuse for doing nothing, and a rule that only ever says no is not a rule, it is inertia. Two guardrails keep it honest.

First, the decision must be *written down*, with its reason. "Not translating the client area until a client asks" is a decision; "we'll see later" is an avoidance that comes back to every meeting and costs attention each time.

Second, an unused feature is not automatically useless: sometimes what is missing is discoverability, not the need. Before concluding, check that people could actually find it. Our popup was invisible because it was broken, not because it was pointless.

## And the environmental part, honestly

We cannot hand you a figure. We do not know what our hosting emits, nor what these decisions avoided, and inventing a reassuring number would be exactly the kind of greenwashing this REX argues against.

What we can say without stretching: 1,400 translations not written, a feature not rebuilt, a tool not bought. None of it will show up in a carbon report. All of it is work that will never consume a machine, a deploy, a review, or the maintenance that follows for years.

**The greenest decision we made that day was not to build something.**

## What it gave us

- **1,400 translations not written**: the 2-hour prerequisite shipped, the 23 pages postponed until someone needs them.
- **42 lost entries recovered** by fixing an extraction rule, without adding any feature.
- **€0 of new tooling**: a restore drill and a runbook instead of a monitoring subscription.
- **Two single points of failure** identified by rehearsing, not by instrumenting.
- **Every decision written down**, with its reason and what would reopen it.

## Good practices

- Before writing, look for the reader. If reaching them needs a prerequisite, build the prerequisite alone and stop there.
- Measure the work before starting it: "700 strings" ends a debate that "it'll take a while" keeps alive.
- Rehearse before you buy: a restore that actually ran teaches more than a dashboard nobody reads.
- Write the decision not to build, with its reason — otherwise it is not a decision, it is a postponement.

## Watch-outs

- "Nobody needs it" is also the perfect excuse for inertia: a rule that only ever says no has stopped being a rule.
- An unused feature may be badly surfaced rather than useless — check discoverability before concluding.
- Deciding not to build is not the same as not deciding: only the first one stops costing attention.
- Do not dress frugality up in carbon figures you cannot compute: the argument stands on its own.
