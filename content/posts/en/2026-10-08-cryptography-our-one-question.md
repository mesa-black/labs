---
title: "Cryptography: we put our one question to a real company director. He understood none of it."
standfirst: "Our tool reads a project, says how long each protection will hold, and asks the business for one thing only. Here is what it produces, and what happened when we put that question to somebody who is not an engineer: three sessions, three failures, and 986 words to read in order to answer two questions."
key: la-seule-question-ne-passe-pas
date: 2026-10-08
slug: cryptography-our-one-question
---

Almost everything that protects a company's data today rests on sums that are easy one way and impractical the other. A powerful enough quantum computer makes the return trip possible, and states have set dates: today's methods will be discouraged around 2030 and disallowed around 2035.

This is not a problem for 2035, and that is the point almost everyone misses. An adversary does not have to wait: it is enough to **copy a backup or a stream today** and keep it until the day it can be opened. Which means data encrypted this morning that must stay confidential beyond 2035 is already lost — changing method later protects what comes after it, not it.

[Sablier](https://github.com/mesa-black/sablier) is our tool for turning that sentence into figures on a real project. This piece is what it produces, and then the failure of the one thing it asks a human for.

## What the tool does

It reads a repository — running nothing, sending nothing — and records every place the code encrypts, signs or hashes something: library calls, keys and certificates sitting in the tree, server configuration, deployment scripts, declared dependencies, and the infrastructure when it is written in Terraform. Then it crosses that inventory with how long each category of data has to stay confidential, and returns a verdict per place.

Run on an example project, that looks like this:

```
  /project — 3 files read, 7 findings, 0.0 s
  declaration: /project/sablier.json

    COMPROMISED              1
    BROKEN TODAY             1
    WATCH                    2
    CLEAR                    2
    LIKELY NOT CRYPTO        1

  → /project/r.html
```

Five categories, and two that count. Here is the red finding, as the report writes it:

> **COMPROMISED** — `deploy/backup.sh:3`
> Encrypted today, to be kept confidential until 2036 — one year after RSA expires. A capture made now will be readable.

And the one that has nothing to do with quantum computing, because an inventory that only talks about 2035 misses what has been broken for twenty years:

> **BROKEN TODAY** — `src/Tokens.php:17`
> Classically broken, quantum computing aside. The deadline was yesterday.
> *references CVE-2005-4900*

An inventory that concludes nothing gets filed in a folder, so the report decides and puts things in order. The first item of the plan is never "migrate":

> **Decide what happens to the data already emitted.** This is the decision nobody takes, and it comes before the migration. The domains concerned are protected by an algorithm that will not last out their confidentiality lifetime: what has already been encrypted and transmitted is beyond the reach of a fix. Three outcomes, and one has to be chosen explicitly — re-encrypt the existing stock, rotate the keys and re-issue what can be re-issued, or record in writing that the risk is accepted. Migrating without settling this protects future data and leaves the old exposed without anybody having decided it.

It can also read a breach backwards. Given a date of compromise, it stops reasoning about what an adversary will harvest: it counts what is already in their hands, and for how long it keeps hurting.

> **After the breach of 29/07/2026** — What left is already in somebody's hands. The only protection remaining is the algorithm, and it has an end date.
> *backups* — confidentiality asked for: 10 years, so until 2036. The algorithm protecting it expires in 2035. 1 year of what was taken will become readable, and no migration reaches it.
> *session tokens* — protected by cryptography quantum does not reach. Nothing becomes readable on that side.

The report exists in two versions: a technical one, read next to an editor, and a numbered audit document separating facts from opinion, for the exhibit produced in front of a third party. Both print what they did not look at, because an inventory that hides its blind spots manufactures false assurance. Everything runs on the machine of whoever types the command: no data leaves, the code is MIT, and [the example reports](https://github.com/mesa-black/sablier/tree/main/examples) are in the repository.

## The one thing it cannot guess

One verdict above says "to be kept confidential until 2036". That 2036 does not come from the code. It comes from a duration somebody declared: ten years for those backups.

That is the hinge of the whole tool, and no software can guess it. A login session lasts hours, an invoice ten years, a contract thirty — and none of that is a technical fact. So the tool asks for it, in one question, of somebody who knows the business: *how long must this stay secret?*

On 2 October, a piece published here ended on an uncomfortable sentence: every tool in this field, ours included, assumes the confidentiality lifetime of data is an *obtainable* fact, and nobody appears to have checked that a real business can state it. It closed by admitting that this conclusion too had been validated with nobody.

It was validated this week. Three times, with the director of a company that uses our tools every day. The result fits in one sentence, his:

> "I am sorry but this is gibberish to me, I do not know what it means, I do not understand the sentences. In short, I am lost."

This is not a teaching problem, and it is not a problem with him. It is a measurement of the instrument, and it could be counted.

## The measurement

To ask that question remotely, the tool produces a standalone HTML file: no server, no network, you open it, you answer, you hand back a block of JSON. Built for the rooms a live interview cannot enter — a closed network, a machine nobody may connect to.

On the third attempt, I counted what that file gave somebody to read before they could answer. **986 words.** For seven subjects and two questions each. With the word *fingerprint* five times, and *algorithm*, *deadline*, *regime*, *declaration*, *plumbing* on the way.

The detail that matters: **most of those 986 words had been written that same day**, while fixing the two previous failures. At every pass I had added a paragraph out of honesty — what the tool cannot know, why this question is being asked, where this date comes from, what the answer implies. Each defensible on its own. Together, a document nobody outside the field gets through.

Prose arrives one justified paragraph at a time. That is why it does not show.

## What the answers really said

The second session had produced a file of answers. It looked complete: seven subjects, seven answers, no empty box. It arrived with a comment — "I understood nothing" — and it is reading it line by line that shows the real problem.

Seven subjects, **the same duration seven times**: five years. No legal retention declared anywhere. No written justification. No name to say who was committing to it. 182 seconds in total, with the time per subject collapsing: 20.8 s, 36.1, 16.8, 15.9, 23.8, **8.9**, 10.6.

The seven buttons offered ran from 0 to 30 years. Five was the middle one.

And that uniform five is demonstrably wrong in at least two places. The domain he named "REX" is **published content**: its confidentiality lifetime is zero by construction. The one he named "Facturation" carries ten years of mandatory accounting retention — answered five, with "legal retention: 0" right beside it.

**One part did work.** He renamed all seven subjects in his own words: Login, Facturation, Information, REX, Profile, Sécurité, Paramètres. That is exactly the task he was given, and he did it. The vocabulary of *data* was not the blocker. The vocabulary of *durations* was.

And the form's last two questions — "a question you expected and were not asked", "a word you did not understand" — came back empty. 7.8 seconds on that screen. Somebody who does not understand does not fill in the field where you say so.

## Why that is worse than no answer

That file was not empty. It was **plausible**. And the tool, importing it, printed "7 answers taken", wrote a declaration, and said nothing else.

A declaration, in this tool, is what makes a person accountable for a figure: the audit report prints beside every duration who declared it and when. Turning seven clicks on the middle button into a dated declaration manufactures exactly the false assurance the project spends its time denouncing elsewhere. No declaration beats a laundered one.

So the dangerous failure mode of a tool like this is not "the person cannot answer". It is "the person produces something that looks like an answer".

## The six corrections

**Subjects are named by their place, no longer by the cryptography they hold.** Subjects were merged by family of algorithms, which means a subject could only be *named* after a family: we were asking how long "public-key encryption" and "content digests" had to stay confidential. Those are mechanisms, not data. Worse, the one subject he could have handled well — five business directories — had been collapsed into one of them.

**Durations became consequences.** No more 0/1/3/5/10/20/30 buttons, but four sentences: *it is public, or of no consequence* / *it would embarrass us, until it blew over* / *a client could hold it against us, or walk away* / *we would be held to it for years, or end up in court*. The arithmetic is the tool's job.

**And those sentences are anchored on the project's own history.** Where the repository knows when it started — the oldest author date in its git log — the choices name years the person lived through: *what we were writing in 2023 would still be awkward*, *even what we were writing in 2019, at the start*. The longest choice is then the project's own age rather than a round number. Nobody estimates seven years forward well; everybody can say whether the invoices from the first year still matter.

**986 words became 235, and a test fails over 260.** A budget, not a review: nothing else catches prose that arrives one paragraph at a time. A second test fails if a trade word returns to the reader's path. Everything removed is still written down — in the audit report, read by whoever has to weigh the figures, not by whoever supplies one of them. I was confusing the two readers.

**A whole question disappeared: the regulatory regime.** Nobody outside the field picks between NIST IR 8547, CNSA 2.0 and an ANSSI position. The question printed five lines of acronyms — then deadlines of 2030 and 2035 right under the year the person had just given as the end of the application's life. It is the auditor's choice, in a versioned file, and the tool reminds them when it has been left at the default.

**The tool now reports a uniform answer.** Identical durations throughout, no justification, nobody named: it says so, names the figures, and points out that published content and ten years of accounting do not share a duration. It reports, it does not refuse — judging whether those answers mean anything belongs to whoever ran the session.

## What we refused to do

**Pre-fill the answer.** It was the most tempting correction: propose a duration per category and ask for a confirmation. A yes/no on a concrete proposition is far easier cognitively than producing a duration.

It is also the surest way to obtain a declaration nobody read. A tired reader accepts whatever is in the box, and the box ends up signed. The field that names the data is no longer pre-filled at all, for the same reason: it used to arrive carrying a family of algorithms, and filling it with the directory name — "Entity" — would have been no better.

## What it produced

- **An assumption shared by the whole field, tested**: a business cannot spontaneously state the confidentiality lifetime of its data. Not "not yet": not the way we were asking.
- **A failure mode named**: the plausible answer. A form that does not force thought produces figures, not information.
- **Three failures with the same person**, which is a measurement of the instrument and not of them.
- **751 words removed** from a document I had written believing I was being honest.

## Good practice

- Measure the document before rewriting it. "Too technical" is an impression; 986 words and *fingerprint* five times is a defect you can fix.
- Put a budget where the drift is slow. A test that counts words catches what no review catches, because every added paragraph is defensible at the moment it is added.
- Separate the readers. An honest tool's caveats go into the report, read by whoever weighs the figures — not into the form, filled in by whoever supplies one.
- Ask for a consequence when you want a duration. People know what it would cost them; they do not know how to convert that into years.
- Watch the time per question. The falling curve says you lost the person, and it says it before they do.

## Things to watch

- **A sample of one.** One director, one company, one field. The six corrections are justified by an observation, not by a study.
- Subject headings are still code words — "Billing", "Entity". Translating them into business vocabulary would mean inventing what the tool does not know; it shows the place and asks for the name.
- **The standalone file was not built for this.** It exists for closed networks, not for somebody alone in front of their inbox. Three failures in a row say mostly that we used the instrument meant for an isolated room where a twenty-minute conversation, side by side, would have reworded out loud what no written sentence catches up with.
- Nothing guarantees the fourth attempt gets through. What is guaranteed is that we will be able to measure it.
