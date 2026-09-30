---
title: "We checked our main claim. It had been wrong since 2015."
standfirst: "What the check cost, what survives it, and the one question nobody in this field seems to have tested."
key: notre-argument-etait-faux
date: 2026-10-02
slug: our-main-claim-was-wrong
---

In the scoping study for [Sablier](https://github.com/mesa-black/sablier), published a few days ago, one sentence carried everything else. It said the open space was not inventorying a project's cryptography — others do that — but **tying that inventory to the lifetime of the data**, and that nobody did it.

That sentence is wrong. We found out by checking it, a week too late, and this piece reports what the check returned, because that is more useful than correcting it quietly.

## What the check returned

**The formula has had a name since 2015.** It is Mosca's inequality: `X + Y > Z`, where X is how long the data must stay confidential, Y is how long the migration will take, and Z the years until a cryptographically relevant quantum computer exists. If the sum exceeds, there is a window during which still-sensitive data is no longer protected. It is the standard reference for security leadership and agencies.

What we presented as our angle is that inequality with Y dropped and Z replaced by the regulatory deadline. A simplification of a known framework, not a find.

**And the angle is taken.** Several projects already implement it against a codebase, with an inventory, a per-asset lifetime and a computed exposure. One of them, a Python prototype of the same age and maturity as ours, even produces a self-contained HTML report printable to PDF. The resemblance does not stop there.

## An inventory of what fell

We had listed four things that remained ours. Three did not survive an hour of checking.

**"A signature cannot be harvested."** That was our best technical argument: applying an inequality about confidentiality to a signature scores it as if traffic could be captured and opened later, which is wrong. Except that the same project makes exactly that distinction, and words it better than we did: *a quantum computer cannot un-sign a 2026 release*. It recalibrates X by purpose — data lifetime for encryption, key validity for signing — and proposes different replacements for the same algorithm depending on what it protects.

**The live probe.** Our most demonstrable functional difference: reading what a server actually negotiates rather than what a file declares. They do it too, with a precaution we had not written down — the probe is the only component that leaves the machine, and their documentation draws it as a dashed line for that reason.

**The refusal to predict.** We use the regulatory deadline and say we do not forecast the arrival of a quantum computer. They model Z as a probability distribution and return a median with its uncertainty. That is more sophisticated than our refusal, and probably more accurate.

What survives is not an idea: **the PHP ecosystem**, which these tools do not cover; **no service, no database, one command**, where they expose a local web console with a scan history; and **zero dependencies**, which on a tool that reads keys remains an argument, if a modest one.

That is much smaller than what we wrote. It is what is true.

## The question nobody has tested

But the check returned more than it cost, and this is the heart of it.

All of these tools, ours included, rest on the same variable. Mosca calls it X. We call it the confidentiality lifetime. Another calls it the security shelf life. And **all of them assume it is available.** Articles give sector-wide orders of magnitude — ten years for payments, fifty for health records — but a sector-wide order of magnitude is not one company's answer.

Yet we could find no trace, anywhere, of anyone having verified **that a real business can answer that question.** Not "what is the right answer", but "does the person who ought to know, know?" How long does it take to get it out of them? How many categories do they stall on?

If the answer is "they know, in an hour", the field is healthy and will be settled on execution. If the answer is "they do not", then **all of these tools are built on sand**, ours first, and no additional detector changes that. The question would have to be asked differently — probably starting from legal retention, which people know, instead of confidentiality lifetime, which they have never had to put into words.

That has become the only thing that matters in this project. Not one more detector: an empirical answer to whether the input exists at all.

## What it changes about method

One thing struck us afterwards. We wrote nine detectors, six probe protocols, three report languages and a signing mechanism — **before** checking the single sentence everything rested on. The order was backwards, and it was backwards for a comfortable reason: building is pleasant, checking is not, and a sentence you wrote yourself reads as true.

The fix costs nothing. The sentence that sells gets checked before the code that delivers. One search, twenty minutes, before the first line.

And since this project spends its time saying that an inventory hiding what it did not look at manufactures false confidence, it could not keep an unverified exclusivity claim in its own documentation. The scoping study was corrected in place, with an up-to-date prior-art table and the shorter list of what remains.

## What it produced

- **An exclusivity claim withdrawn** from public documentation, replaced by a checked and dated state of the art.
- **Three differentiators out of four discarded** in an hour of research, including the best one.
- **An open question identified** that the whole field assumes is settled, and which is not.
- **Zero lines of code changed**: the check invalidated nothing about the product, only about its story.

## Good practices

- Check the sentence that sells before writing the code that delivers. It is shorter to check and more expensive to get wrong.
- Treat discovered prior art as information rather than defeat: several people independently reaching the same idea within months is the best available signal that the need is real.
- Look for what everybody assumes. In a young field, the shared assumption is the most profitable place to dig.
- Correct in place, with the reasoning. A silent correction protects the author; a written one protects the reader.

## Watch-outs

- **Finding prior art says nothing about execution quality**, in either direction. A one-star prototype does not occupy a market, and neither does ours.
- The temptation after this kind of check is to hunt for a replacement differentiator until one is found. That is the same mistake, made in the other direction.
- **A sector-wide order of magnitude is not one company's answer.** "Ten years for payments" does not say how long *your* data must stay secret, and that is precisely what remains to be demonstrated.
- None of this has been validated with an outside team. Including that conclusion.
