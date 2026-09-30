---
title: "We were our own best customer. That was a bug."
standfirst: "Our company publishes on our platform — and was counting itself in our revenue, our funnel and our follow-up lists. How we took it out of the statistics without taking it off the site."
key: notre-propre-meilleur-client
date: 2026-09-30
slug: our-own-best-customer
---

Everyone tells you to use your own product. Nobody warns you about the side effect: the moment your company has an account, it enters your figures. Not in a footnote — in the revenue, in the conversion rate, in the list of customers to chase.

Our case: BlackMesa publishes real case studies on Show me the REX. The account is real, the plan is real, the articles get read. What is not real is the revenue — we do not invoice ourselves. So a zero-euro customer sat inside our MRR, inflated the plan breakdown, and filled a slot in the conversion funnel without ever having converted anything.

The obvious fix — "exclude our own company" — is wrong. It assumes the problem is the company. The problem is somewhere else.

## It isn't "who to exclude", it's "what does this number answer"

The reflex is to look for a list of entities to leave out. The right question is asked metric by metric: which question is this number the answer to?

A view counter answers "how many people read this text". The answer is the same whether the reader came from our offices or from anywhere else: the page was served, it was read, the content exists. Excluding our views would make that number wrong.

Monthly revenue answers "how much do our customers pay us". Our own company is not a customer. Its presence makes that number wrong.

Both metrics look at the same database, sometimes at the same row, and need opposite rules. That is not an exception to handle, it is the rule: **the unit of exclusion is not the data, it is the question being asked.**

## The case that settles it: a view that counts and does not count

The clearest example is also the most uncomfortable, because it rules out every implementation shortcut.

On the platform, a case-study view feeds two distinct things. On one side, audience: the counter shown on the article, the dashboard total, the traffic curve. On the other, a commercial signal: "which companies have read your case studies", used to identify contacts worth following up.

Same event, same record. In the first group, a read from our own offices counts — somebody really did read it. In the second, it must not count at all: we are not a prospect to call back, and an internal reader sitting in a lead list is a sales action triggered for nothing.

So there is no global filter to install once at the door. Every query has to know which family it belongs to.

## A flag in the database, not a constant in the code

First version, the quickest one: a hardcoded list of company names. It lasted an hour. A constant forces a deployment to reclassify a company, and more importantly it lies about the nature of the information: "this company is not a customer" is business data — it changes, it gets decided, and it has to be visible to whoever administers the accounts.

So it became a checkbox on the company form, with its help text spelled out, because an option whose scope nobody understands ends up ticked at random:

> Our own companies publish and stay visible on the public site, but count in no commercial or marketing figure: MRR, plans, funnel, upsell/churn, leads, digests. Views and visits, however, still count.

The list of names did not disappear: it bootstraps a freshly installed environment so it never starts with polluted metrics. But it no longer decides anything.

The predicate itself lives in one small class, in two flavours — one for ORM queries, one for raw SQL. That sounds trivial; it is what makes the rule auditable. Finding every place that applies it became a text search, and checking it against the list of commercial figures takes a minute by eye.

## Verify rather than re-read

Re-reading your own exclusion code proves nothing: you read back what you believe you wrote. The only verification worth the name is to toggle the checkbox and compare the dashboards before and after, figure by figure.

About thirty values moved. Seven stayed strictly identical — and that was the expected result: they are the audience counters and the published-content volumes. A number that moves when it shouldn't is a bug; a number that stays put when it should have moved is an omission. Without that pass, we would have caught neither.

The final shape: one flag, one policy class, thirty-four predicates across eight files — MRR, plans, funnel, upsell, churn risk, follow-ups, lead intelligence, monthly digests, coupon expiry, nurturing.

That last one deserves a mention. Without the exclusion, our own company sat in the automated re-engagement sequence. We would have been sending ourselves our own win-back e-mails.

## What it produced

- **An MRR with no zero-euro customer in it**, and a conversion rate that no longer counts our own sign-up in its denominator.
- **About thirty corrected values** across the commercial dashboards, seven deliberately unchanged.
- **Zero change on the public site**: the case studies stay published, visible, filterable, and their views still count.
- **One rule written in one place**, with its reason, rather than an `AND` copied from query to query.
- **A checkbox** that reclassifies a company without a deployment.

## Good practices

- Classify each metric before coding the filter: audience measurement, or commercial signal. The answer sets the rule, and it is not the same for two numbers drawn from the same table.
- Put membership in the database, not in a constant: it is business data, it changes and it gets decided.
- Keep the predicate in a single class even if it fits on one line: the point is not reuse, it is being able to find every call site.
- Verify by toggling: comparing figures before and after is the only way to tell an omission from a decision.
- Write the scope into the admin interface, right where the box gets ticked.

## Watch-outs

- **Nothing stops the next query from forgetting the predicate.** The rule is held by code review, not by a test, and that is the main weakness of the setup today.
- An exclusion that is too broad is as wrong as no exclusion at all: pulling our views out of the audience counter would have produced a lie in the other direction.
- The day an internal company becomes a real paying customer, the box has to be unticked — and nobody will remind you. That decision is human, and it needs a scheduled moment where it gets revisited.
- Saying publicly that your statistics exclude your own data costs nothing, and beats having someone else discover it for you.
