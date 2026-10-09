---
title: "An agent can do anything. It cannot answer for what it did."
standfirst: "Where development ends, where operations begin, and who decides when an AI writes half of both. The answer is not in the tooling or the org chart: it is in reversibility, and European law has already written it down for cybersecurity. Here is the line, and what it demands in practice."
key: qui-repond
date: 2026-10-12
slug: who-answers
---

The question "where is the boundary between dev and ops" has been badly posed for ten years, and coding agents have made it frankly unusable. Because we keep answering it with tools — who writes the Terraform, who carries the pager, who has production access — when the only answer that holds is somewhere else.

There is one boundary, and it separates **what you can come back from** from what you cannot.

## What the boundary is not

It is not in the tooling. Saying that development stops at `git push` and operations start at the deployment makes no sense in a chain where the same file describes the application and the infrastructure carrying it, where the same pipeline builds the image and puts it into production.

It is not in the job titles. "DevOps" solved an organisational problem by renaming it: two teams that passed the ball to each other were merged, which was progress, and from that we concluded the boundary had gone. It has not gone. It moved **inside each person**, who writes code in the morning and deploys it in the afternoon, and who must therefore arbitrate alone what an organisation used to arbitrate for them.

And it is not in the access rights. Who can connect to production is a consequence of the boundary, not its definition. We hand out rights because we have decided who answers for what — not the other way round.

## What it is: three natures, not three degrees

A change belongs to one of three categories, and confusing them is the source of most of the incidents that get told afterwards.

**Reversible and cheap.** Merging a branch, deploying behind a flag, adding an index, scaling up a replica count. Going back is one command, it costs minutes, and its cost is known *in advance*. This category needs no ceremony: ceremony costs more here than the mistake does.

**Reversible and expensive.** A schema migration with a data transformation, a provider switch, a format change in an artefact others consume. You can come back, but the return is itself a project, with risks of its own. Here ceremony earns its keep: a window, a backup that has been verified — verified, not assumed — and somebody watching.

**Irreversible.** Deleting data, rotating a key that encrypts a history, publishing. Yes, publishing: you do not unpublish, you add a correction on top. A package pushed to a public registry, an article online, a declaration filed with an authority — what left has left.

**The boundary sits between the second and the third**, and it has nothing to do with job descriptions. A `DELETE` without a `WHERE` written by a developer and a bucket purge launched by an ops engineer are the same event.

## Where an agent fits — by the same rule

This is where the reasoning becomes useful, because it needs no special rule for AI.

A coding agent is excellent on the first category. It reads more files than a human will ever open, it does not get bored, it does not skip the tedious step, and it measures where we would have read documentation. Forbidding it that category on principle means refusing a real gain out of a misplaced fear.

On the second, it prepares and does not decide. The distinction is operational, not symbolic: it produces the migration script, the rollback plan and the list of what breaks — and a human reads all three before anything moves.

On the third, it never decides. And the reason is not competence.

Experience, on the other hand, does count — but elsewhere, and the distinction is worth holding. What an agent lacks is not knowing how to perform a key rotation: it is having seen one go wrong. Experience is not what decides once you are inside the third category; it is what lets you **recognise that you are in it**, before acting, when nothing in the command announces it. An agent has no scars, it has a corpus — and a corpus holds the incidents other people have recounted, not the ones you paid for.

Which is why sorting changes into three categories is not administrative paperwork: it is the place where human experience actually enters the chain. But even an agent that sorted them perfectly still could not decide — and this time the reason owes nothing to capability.

## The law has already settled it, more clearly than our debates

There is a text that answers the question "can a machine carry a decision", and it is not theoretical. Directive (EU) 2022/2555 — NIS 2 — devotes its article 20 to governance, in these terms:

> *management bodies of essential and important entities approve the cybersecurity risk-management measures taken by those entities in order to comply with Article 21, oversee its implementation and can be held liable for infringements by the entities of that Article*

And in the following paragraph:

> *members of the management bodies of essential and important entities are required to follow training*

Three verbs, and each one carries weight. **Approve**: there is an act of acceptance, distinct from producing the measure. **Oversee**: the acceptance is not spent at the moment of signing. **Be held liable**: the consequence has a named recipient.

It is the third that settles the AI question, and it settles it without anyone needing a view on what models can do. You cannot hold an agent liable. It has nothing to lose, no training obligation to discharge, and no legal existence for a sanction to bite on. That is not a judgement on its quality: it is an observation about structure.

The training obligation says the same thing from the other side. The legislator does not require the company to possess a competence — it requires that **the people who approve** understand what they are approving. You do not train an agent into liability. You train somebody to know what they are taking on.

## The signature is the test case

All of this becomes concrete the moment something has to be signed.

A cryptographic signature does not say "this was produced correctly". It says: **somebody stands behind this.** It is an attribution of responsibility, not a certificate of quality — and that is exactly why it is the right test of the boundary.

Three practical consequences, all of which follow from that one sentence.

**The private key never touches the agent.** Not out of distrust towards any particular supplier: because a key an agent can use is a key that signs without anyone having taken anything on. In our inventory reports the key is built on the fly, it signs, and it is destroyed — it exists only for the duration of a human gesture.

**The agent proposes, the human signs.** The agent prepares the change, runs the checks, shows what it does, and stops. The authorisation is a separate act, by somebody who can answer for it. That is not a formality: it is article 20's "approve", implemented.

**The commit carries no machine co-author.** This one surprises people, and it matters most. A trailer attributing a commit to a tool feels transparent and produces the opposite effect: it dilutes. If a decision is disputed in two years, "co-written with an assistant" names nobody you can question. **A signature that names a tool names nobody.** Transparency about using agents belongs in the documentation and in the practices — not in the field whose purpose is knowing who to talk to.

## What the human checkpoint is really there to catch

There is a widespread misunderstanding: that we put a human approval in place because we assume the agent is incompetent. That is false, and believing it leads to putting the approval in the wrong place.

An agent is wrong less often than feared about things it knows how to check. It is wrong differently. Three failure modes deserve naming, because they do not look like incompetence and they do not show up in an ordinary code review.

**The test that locks in the defect.** When the same chain produces the artefact and the test that guards it, the test can encode the observed state instead of the intended one. A check verifying that a document displays the version it displayed yesterday passes perfectly, for months, while guaranteeing exactly the bug. That is worse than no test: it manufactures confidence.

**Speed, which turns a recoverable mistake into a propagated one.** A human who gets a destructive command wrong notices at the next command. An automated chain has already run fifteen more steps. The mistake is the same; its radius is not. It is speed, not accuracy, that justifies the stopping point.

**The state that does not exist for the agent.** We learned this one the hard way, and it is worth telling precisely because it does not look like carelessness.

An agent reasons about what the repository records. Anything uncommitted does not exist in its model of what is recoverable — and the most natural gesture for undoing an experiment, `git checkout <file>`, restores the last committed version **by overwriting everything that was not**. Twice in one session, while checking that a guard really did refuse what it was meant to refuse, we deliberately broke a file, confirmed the guard noticed, and then undid the experiment that way. The test passed. The uncommitted work went with it — once a documentation file, once a README rewritten from top to bottom.

A human hesitates in front of a destructive command because they remember working for two hours without committing. The agent has no such memory: it has a git index, and the index does not contain what you just wrote. This is not an attention failure, it is a difference of model — and it is stable, so you can guard against it.

Two practical consequences, and the second is counter-intuitive. **Before breaking something deliberately to exercise a guard, back it up outside the repository** — `cp` to `/tmp` is enough, and `git checkout` is not an undo button. And **commit early**, not out of history discipline, but so that what you have just done **exists** for the machine helping you.

Hence a simple rule: **the human approval goes where recovery becomes difficult, not where you doubt the competence.** The rest of the time it costs more than it returns, and a team that approves everything ends up reading nothing.

## What a reviewer brings, and what it demands

If the human contribution is to classify and then to answer, what does that look like in practice? Not like an ordinary code review.

**An agent's mistakes do not look like mistakes.** A beginner's do: it does not compile, it is visibly wrong, you catch it skimming. An agent produces working code with a confident comment explaining why it is right. A one-liner extracting a digest works perfectly on a Mac and fails under Linux, because GNU's `tr` reads three characters as a range. A test checking that a document still shows the version it showed yesterday passes for months — while guaranteeing the defect. These are not beginners' mistakes: these are mistakes that **survive a review**.

Which makes them harder to review, not easier. And it is the opposite of the intuition we have when hiring.

**What it demands of the reviewer is not knowledge, it is a habit:** refusing an explanation you do not follow. "What exactly does that mean?" costs no expertise and works very well on a machine whose output is fluent by construction. A piece of internal jargon that had leaked into three translations of a documentation fell that way — not thanks to an expert reading, thanks to somebody who refused to understand.

**What a corpus does not hold.** I can ask an agent why PHP 6 died, and the answer will be right: Unicode everywhere, a rewrite that collapsed under its own ambition, a version number we ended up skipping. But I *waited* for it. For years, building plans on top of it that were never used. That is not the same knowledge: one is a story, the other is an invoice that was paid. A corpus holds the incidents other people recounted — not the ones you remember because you lived through them.

**And the real question: a developer arriving now and doing everything through AI, what does that produce?**

What they will not acquire is not syntax. It is the memory of consequences, and the mechanism is precise: the tool removes exactly the friction that produced the learning. Three hours spent on an error message is how you eventually learn what that message really means. Solved in thirty seconds, the defect is fixed and nothing has been learned.

Honesty requires saying that every generation has said this about the previous abstraction. Garbage collection was going to produce developers who no longer understood memory, frameworks people incapable of writing a query, Stack Overflow a generation of copyists. There is still a difference this time, and it is structural: **the previous abstractions removed implementation work while leaving diagnosis intact.** This one removes diagnosis. And diagnosis is what manufactures judgement, which is exactly what we ask of a reviewer.

**But the conclusion is not "you need twenty-five years".** The quality required to review an AI is not seniority, it is the refusal to be impressed. Seniority is the most common way of acquiring it, not the only one. A junior who never accepts an explanation they cannot follow is doing real review work today; a senior who skims because "it looks fine" is doing none. It is a habit before it is a level — and a habit can be taught, which is the only good news in this section.

**One asymmetry is left, and it has to be said because it is uncomfortable.** We put the question to the agent this text was written with, asking it to be frank rather than pleasant. Its answer, as given:

> "You can work without me, more slowly. I cannot work without somebody who knows when I am wrong. The dependency does not run in both directions with the same force, and an article claiming otherwise would be flattering and false."

That is exactly it. Organising a chain as a partnership between equals means misunderstanding what you bought: a very fast executor that needs to be told where to look.

## What you gain when the split is right

A well-used agent does not just write code faster: it measures where we would have read. Three examples from our own chain, chosen because they share one shape — a documentation claim that does not survive a measurement.

An archive advertised as reproducible was not: `git archive` does give identical bytes under two versions of git, but `gzip -n` does not make two deflate implementations agree — Apple's and GNU's compress the same tar differently. The promise was true of the uncompressed stream and false of the archive.

A verification command published everywhere fails on half the distributions, because `/etc/ssl/certs/ca-certificates.crt` is a Debian convention that exists neither on Fedora, nor Rocky, nor openSUSE — and a `-CAfile` pointing at a missing file answers `Verification: FAILED`, exactly as a forgery would.

A timestamping token carries its own certificate chain, and LibreSSL — the `openssl` shipped with macOS — does not read it. Same failure message, radically different cause.

None of those three is found by reading. All three are found by running the same command against eight targets, which is exactly the kind of tedious, repetitive, glory-free task an agent does without tiring — and on which a human would, honestly, have extrapolated from two cases.

## Good practice

- **Sort changes by reversibility, not by job title.** Three categories are enough, and it is the boundary between the second and the third that deserves a procedure.
- **Give the first category to agents, without ceremony.** Putting a human approval there costs more than the mistake it prevents, and burns the attention you will need elsewhere.
- **Make approval an act distinct from production.** Article 20 of NIS 2 makes it an obligation for the entities in scope; it is good practice for everybody else.
- **Keep the private key out of the agent's reach.** A key an automaton can use signs without anyone having taken anything on.
- **Do not attribute a commit to a tool.** Put your use of agents in your documentation, not in the field whose purpose is knowing who to question.
- **Place the stopping points on recoverability**, not on your level of trust. The right criterion is "what does going back cost", not "do I trust what produced this".

## Things to watch

- A test produced by the same chain as the artefact can lock in the defect instead of detecting it. Have the test and the code written in separate passes, and check that a new test fails before believing it.
- "Approving" is not "clicking". An approval given without reading is worse than no approval: it creates a record saying the opposite of what happened.
- Reversibility is a property of the system, not of the intention. A rollback that has never been executed is not a rollback, it is a hypothesis.
- Publishing is irreversible, internally too. A report sent, a declaration filed, a package pushed: the correction adds, it does not replace.
- And the boundary moves. A change that is reversible today becomes irreversible the day somebody else depends on what it produces. That is a review to redo, not a classification to carve.

## How this text was written

It was written in dialogue with a coding agent, and the split was the one this article describes. The agent produced the drafts, read the directive in its official text rather than in a summary, and verified every measurement quoted above. The rest — recognising that a claim smelled wrong — does not delegate, and three passages of this text come directly from it.

The section on experience did not exist: it was born from a disagreement about a single sentence. The jargon that had fallen into three translations fell because somebody refused to understand one word. And an explanation about a browser cache, plausible and false — the resources would have had different freshness windows — did not survive verification: they all carried exactly the same header, to the second.

This text was therefore written in collaboration with an artificial intelligence, and it carries no machine co-signature. The two go together: what is useful to a reader is knowing how a text was made — which the above says — not reading a tool's name next to that of somebody who can answer for it.
