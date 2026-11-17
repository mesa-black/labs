---
title: "A date nobody has to believe"
standfirst: "In October we took the date of our reports off our own clock and handed it to three timestamping authorities. The report itself admits the limit: their tokens are worth nothing beyond the RSA that signs them. Here is the sequel: a proof of date made of SHA-256 alone, ending in a Bitcoin block, that anybody can check without trusting anybody. And what it does not prove, because that is half of the subject."
key: une-date-que-personne-n-a-besoin-de-croire
date: 2026-11-24
slug: a-date-nobody-has-to-believe
draft: true
---

[[TO COMPLETE before publication: the post's date, the number and time of the block that anchors this site's inventory, and the outputs of the commands replayed in an empty container. Nothing below is to be published until those three are done.]]

Our post ["A signature proves who and what. Never when."](/en/when/) ended on a sentence the report prints next to every attested date:

> What the token does not prove: anything beyond RSA-4096, the scheme that signs it.

That is honest, and it is awkward. A tool that spends forty pages explaining that RSA expires cannot be content with dating its own conclusions with RSA. We had split the trust between three authorities, in three jurisdictions. But splitting trust is not doing without it.

Then the question came in a more direct form: *why would my signature be worth more than a public reference? Can't we date against something everybody can check?*

We can. But the question holds two questions, and they have to be pulled apart before answering.

## Who, and when: two questions, two tools

A signature answers **who**. Our declaration says "this data does not need to stay confidential", and the whole verdict of the report depends on it. What matters is that an identifiable person commits to it. A public reference cannot do that: anybody can anchor any file, which proves that it existed, not that somebody stands behind it.

A date answers **when**. And there the question is right: nothing requires it to be carried by somebody you have to believe. A timestamping authority *signs* a date; you can also *write* a digest into a public ledger, where nobody can move it any more.

So we keep the signature for **who**, and we change tools for **when**.

## OpenTimestamps, in one sentence

[OpenTimestamps](https://opentimestamps.org) links a digest to a block of the Bitcoin chain through a sequence of hash operations that anybody can redo.

The mechanism, without the jargon:

1. You send the **digest** of the findings, thirty-two bytes, to public servers called **calendars**. As with a timestamping authority, the document never leaves.
2. Each calendar puts the digests it receives into a **Merkle tree**: digests are hashed two by two, then the results two by two, until a single value is left, the root.
3. Every few hours, the calendar writes that root into **one** Bitcoin transaction. One transaction for thousands of digests: that is why the service is free.
4. Once that transaction is in a block, the proof becomes complete. It is the list of hashes leading from **your** digest to the Merkle root of **that** block.

Checking it means redoing those hashes and comparing the result with the block header. There is no signature, no certificate and no authority in the loop. What you get has the same shape as in October: *this digest existed **no later than** when that block was mined.*

## Why it is stronger than three authorities

**There is no signature left to believe.** An RFC 3161 token says "the authority asserts". An OpenTimestamps proof says "redo the computation". The difference is not about how much you trust the operator: there is no operator left whose word matters. A calendar that went down tomorrow, or wanted to lie, could take nothing away from a proof that is already complete.

**Forging costs a block.** To backdate a document, its digest would have to appear in an old block. That block is copied by tens of thousands of nodes, and the chain of work that follows it amounts to years of electricity. To show a fake header to a verifier that checks the proof of work, you would have to mine a block at the real difficulty. At today's prices that is **[[TO COMPLETE: order of magnitude, in euros, of the cost of one block at today's difficulty]]**, to lie to a single person.

**And above all, it is only hashing.** This is the point we care about, since it is what this whole site is about. A token signed with RSA-4096 falls the day a quantum computer runs Shor's algorithm at that size: tokens can then be made at any date. An OpenTimestamps proof is made of SHA-256 alone (and sometimes RIPEMD-160). Against a hash function, a quantum computer has Grover's algorithm, which **halves** the security margin instead of erasing it. Finding another document that follows the same hash path would still take in the order of 2¹²⁸ operations, even with Grover. The proof we produce today has every reason to still be readable in 2040.

One precision, so as not to claim more than is true: the security *of Bitcoin* as a currency also rests on ECDSA, which is quantum vulnerable. But a proof of date does not depend on it. It needs the block header to exist and to have cost work, not anybody to still be able to spend their bitcoins.

## "You just swapped an authority for a blockchain"

This is the serious objection, and it needs a precise answer. **There is one place left where you trust somebody: whoever gives you the block header.**

To check, you need the Merkle root of block number N. If you run your own Bitcoin node, you have it, and you believe nobody. Otherwise you ask somebody, usually a public explorer, and that is where trust comes back.

Here is what we did about it in [Sablier](https://github.com/mesa-black/sablier), in this order:

1. **Your own node**, if one is configured. No trust needed.
2. Otherwise, **two independent explorers** (blockstream.info and mempool.space), **which must return the same header**. If they disagree, verification fails loudly.
3. And in every case, **the header itself is checked**: its double SHA-256 must be below the difficulty target it declares, and that difficulty must be above a floor. An explorer that wanted to lie cannot invent a header: it would have to **mine** one.

That is the difference with an authority: we do not believe the explorer, we check what it gives. It can refuse to answer; it cannot lie cheaply.

Offline, in `--airgap` mode, the header can be supplied by hand. It then goes through the same checks.

## What it does not prove

This is half of the subject, and we print it in the report rather than in a footnote.

- **Who.** An OpenTimestamps proof says nothing about the author. That is the signature's job, and it stays so.
- **A precise time.** A Bitcoin block's timestamp is set by the miner, within a margin: it must be later than the median of the previous eleven blocks and no more than two hours ahead. The date is therefore right **to within a few hours**, not to the second. To say "inventoried before 31 December 2026", that is plenty; to separate two filings ten minutes apart, it is not.
- **Right away.** The proof is only complete once it is in a block, usually **[[TO COMPLETE: measured delay between submission and complete proof]]**. In the meantime you have a promise from the calendars, not a proof.
- **That the document did not exist before.** Like an RFC 3161 token, it is an upper bound. Proving the opposite ("this report was not made in advance") would require including an unpredictable public value of the day, such as a draw from the [drand](https://drand.love) beacon. That is another tool, and we have not built it.
- **Legal standing.** A *qualified* electronic timestamp under eIDAS enjoys a presumption that its date is accurate (Regulation (EU) No 910/2014, Article 41). An OpenTimestamps proof has none: a court may admit it, nothing obliges it to.

## Both together, and why

Hence our choice: **we keep the RFC 3161 tokens, and we add the anchoring.** They do not serve the same horizon.

| | RFC 3161 token | OpenTimestamps proof |
|---|---|---|
| what you must believe | the authority, and the RSA that signs it | nothing, if you run a node; otherwise a header whose work is checked |
| precision | the second | a few hours |
| available | immediately | after a block, within hours |
| legal recognition | a presumption, if the timestamp is eIDAS qualified | none |
| against a quantum computer | falls with RSA | rests on hashing alone |

The token is for a dispute in the next three years. The proof is for the question we will be asked in 2040, when nobody will be able to check a 2026 RSA signature without wondering who made it yesterday.

## Doing it yourself, today, without us

As in October, none of this needs our tool. The official client is enough.

[[TO COMPLETE: replay this block in an empty container, paste the real outputs, and check in particular what `ots verify` does without a local Bitcoin node.]]

```
pip install opentimestamps-client

# 1. anchor: the digest goes to the calendars, a .ots file comes back
ots stamp artefact.json

# 2. a few hours later: fetch the complete proof
ots upgrade artefact.json.ots

# 3. verify: redo the hashes up to the block
ots verify artefact.json.ots
```

Keep the `.ots` next to the artefact, like the `.tsr`. Your reader needs neither you nor a home-made format.

## In Sablier

All of this fits in one flag, next to `--timestamp`:

```
sablier scan . --sign=sablier.key \
  --timestamp=http://time.certum.pl \
  --anchor=opentimestamps
```

Unlike `--timestamp`, there is a default here: `opentimestamps` names the project's public calendars. For authorities we refused any default, because choosing who attests your dates is a decision about trust. A calendar cannot lie: at worst it does not anchor, and the proof checks without it.

The rules are the same as in October:

- a proof that already anchors these findings is **kept**, because the oldest one is the only one that counts;
- an unreachable calendar is reported loudly, without failing the analysis;
- `--airgap` mode refuses anchoring, since it goes over the network.

`sablier verify` fetches the complete proof when it is still pending, then checks it.

This site's inventory has been anchored since **[[TO COMPLETE: date]]**, in block **[[TO COMPLETE: number]]**. The proof is online next to the report, with its three tokens:

```
curl -sO https://mesa.black/audit/report.html.ots
ots verify -d 8ecb829ccc278ef7ab3138f56e07ee13319cbb72ce1dabbfc58ee7b4d6b670b5 report.html.ots
```

[[TO COMPLETE: real output of this command.]]

## Good practice

- **Separate who and when.** A signature commits a person. A date does not need to commit anybody; it needs to be checkable.
- **Anchor a digest, not a file.** Thirty-two bytes leave, nothing else.
- **Keep both proofs.** The token for the coming years and for legal recognition, the anchoring for the horizon where RSA is worth nothing.
- **Complete the proof, then keep it.** A pending proof still depends on the calendars. A complete proof depends on nobody, but it does not complete itself.
- **Check the header, do not believe it.** Without a node, compare at least two sources and check the proof of work.

## Watch out for

- An OpenTimestamps proof bounds a date from above, to within a few hours. Presenting it as an exact time is the kind of approximation that backfires in front of a careful reader.
- A public explorer is still a third party. Without a node and without checking the proof of work, you have simply moved the trust once more.
- A pending proof is not a proof. A report that said "anchored" before the block would be saying more than it knows.
- Anchoring carries no legal standing. If you need a presumption before a court, you need an eIDAS qualified timestamp as well.
- Anchoring says nothing about the author. A digest anchored without a signature proves that a file existed, not that anybody answers for it.
