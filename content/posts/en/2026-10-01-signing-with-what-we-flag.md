---
title: "Our tool flags Ed25519. It signs with Ed25519."
standfirst: "Why that is not a contradiction, what it reveals about post-quantum that almost everyone misses, and why there will be no blockchain."
key: signer-avec-ce-qu-on-denonce
date: 2026-10-01
slug: signing-with-what-we-flag
---

We wrote a tool that inventories a project's cryptography and says, for each use, how long the protection will hold. It is called Sablier, it is [open](https://github.com/mesa-black/sablier), and it files Ed25519 under algorithms to migrate: it is an elliptic curve, so Shor's algorithm finishes it.

Then comes the moment to sign its own reports. PHP ships exactly one signature scheme: Ed25519.

So the tool signs with the very thing it points at. The temptation is to hide the problem — sign without mentioning it, or not sign at all. We did the opposite: the report prints the contradiction, with the expiry year filled into it. Because looking straight at it lands you on the distinction that nearly all post-quantum discourse skips.

## The need, before the solution

A report like this ends up in front of someone: a customer, an auditor, a regulator. Three questions arise then, and they are separate.

Has the content changed since it was produced? Does it really come from the tool and the person named? Did it exist on the date shown?

The first calls for a digest. The second for a signature. The third for a third party who dates things, or an append-only ledger.

## Why it will not be a blockchain

It is the first answer that comes to mind, and it solves the one problem we do not have.

A blockchain exists to remove trusted parties between actors who do not trust each other, at the price of spent computation and permanent infrastructure. Running your own is one node, which is one person: exactly as credible as the signature it would replace, plus a machine to keep alive forever. Using a public one means the digest leaves the machine — and our report promises in writing to emit nothing.

The proportionate answer was three things already at hand. A digest of the findings inside the document. A detached signature, with a key we control. And for an opposable date, a standard timestamping authority, in one request, the day somebody genuinely needs a date they did not get from us.

One design point matters more than it sounds: **we do not sign the file, we sign the findings.** Two runs of the same analysis produce different bytes — a rendering date, a duration — while saying precisely the same thing. The same inventory rendered in French and in Spanish yields the same digest. Signing the file would have produced an alert on every run, and within six months the habit of ignoring them.

And the expected public key lives in the project's versioned declaration. A signature that verifies against the key delivered beside it proves one thing only: somebody had a key. Putting it under code review makes changing it a commit someone reads.

## The distinction everyone misses

Which leaves the contradiction. It dissolves on one sentence: **a signature cannot be harvested.**

The post-quantum threat model is called *harvest now, decrypt later*. An adversary captures encrypted traffic today and keeps it until the day they can open it. For confidential data the compromise date is therefore the day of encryption, not the day of the attack — which is what makes the deadline present rather than future.

None of that applies to a signature. Nobody captures a signature to "decrypt" it later: there is nothing inside. The day the curve falls, an adversary can forge new signatures — not backdate 2026 ones into a world that has already watched the algorithm die and stopped accepting them.

The practical consequence is sharp, and it depends entirely on the lifetime of what the signature has to prove.

A signature whose usefulness is measured in months — a report presented this quarter — is perfectly served by Ed25519 today. A signature that must stay verifiable in fifteen years is not served at all. And that second category has a name: **long-lived trust anchors**. Code signing, an internal certificate authority, firmware, timestamping. And, precisely, a compliance report that may have to be produced in court in 2041.

It is the same reasoning the tool applies to data. The question is never "is this algorithm post-quantum". The question is "how long does it have to hold".

## What the report says

So the report says it, with the year filled in:

> This signature is Ed25519 — which this very report classifies as quantum-vulnerable. A signature cannot be harvested: it holds as long as the curve does. So the only question that matters is this one: will you still need to prove this report genuine after 2035? If so, Ed25519 will not do.

That is not a compliance warning, it is a question handed back to the reader, because only they know the answer. Nothing in the code can tell whether a report will be archived for fifteen years or thrown away next quarter.

For the cases where the answer is yes, the way out exists and is rather elegant: hash-based signatures. They rest on no rich mathematical structure, only on the strength of SHA-256 — which makes them immune to Shor by construction. The price is in bytes: ten to forty kilobytes per signature where Ed25519 asks for sixty-four. For a report archived fifteen years, that is a trivial bill. It is the planned next step, and it is waiting for a real need rather than an urge.

## What it produced

- **The findings signed, not the file**: two renderings of the same inventory, in two languages, carry the same digest.
- **The expected public key in the versioned declaration**: changing it is a reviewed commit, not a command-line detail.
- **Three distinct verification failures** — content changed, key other than the declared one, unreadable block — because a bare "invalid" teaches nothing to whoever has to decide.
- **Zero dependencies added**, zero infrastructure, zero blockchain.
- **The contradiction printed in the document**, with the expiry year inside it.

## Good practices

- Separate the three needs before choosing a tool: integrity, authenticity, opposable date. They do not call for the same answer, and conflating them leads to building ten times too much.
- Sign what carries meaning, not what carries bytes: signing a rendering produces an alert on every run, and a systematic alert ends up ignored.
- Put the expected public key under code review. Without it, verification proves only that a key exists.
- Judge a signature by the lifetime of what it proves, not by the fashion of its algorithm.
- Write the caveat into the deliverable, with its figures, rather than into a footnote nobody opens.

## Watch-outs

- **A signature dates nothing.** It says who, not when: the date field is declarative and signed by whoever wrote it. An opposable date needs a third party, and saying so beats letting people believe otherwise.
- A private blockchain is a trusted party dressed as a protocol. If you have to be taken at your word anyway, sign and own it.
- Hash-based signatures carry state in some variants: pick a stateless one, or a restored backup becomes a silent catastrophe.
- **The real risk here is not the algorithm, it is the habit.** A signature nobody verifies is worth nothing, whatever its curve. The verification command has to fit on one line, or nobody will type it.
