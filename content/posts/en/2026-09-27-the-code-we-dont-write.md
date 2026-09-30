---
title: "The cheapest feature is the one you don't build"
standfirst: "Three signals that say 'do not write this code' — and what they saved us in a single day."
date: 2026-09-27
key: le-code-qu-on-n-ecrit-pas
slug: the-code-we-dont-write
pointer: true
rex: https://showmetherex.com/en/feedback/le-code-qu-on-n-ecrit-pas
---

Digital sobriety is almost always framed as an optimisation problem: lighter images, better
caching, a cleaner region. All true, and all marginal. The real waste sits elsewhere, and
nobody measures it: **code written for nothing**. A migration to redo, a tool bought then
dropped, a feature shipped that nobody opens. Which leaves the question we had never put
into words: how do you *decide* not to build something?

The report gives the **three signals** we settled on, and what each one saved over one
ordinary working day: a broken feature nobody complained about — information about the
feature, not about the bug; 1,400 translations we did not write because no reader could
reach them; and a monitoring gap that turned out to be a rehearsal gap, not a tooling gap.

It also says what those signals **do not** mean. "Nobody needs it" is the perfect excuse for
doing nothing, and a rule that can only say no has stopped being a rule. Two guardrails keep
it honest — including this one: an unused feature is sometimes badly exposed rather than
useless.
