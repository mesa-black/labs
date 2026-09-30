---
title: "Our domain layer contains nothing but exceptions. On purpose."
standfirst: "Nine contexts, twenty-nine commands, a single query handler, zero ports. What we kept of DDD and hexagonal architecture, what we turned down, and the five places infrastructure crosses the boundary anyway. This is not purist DDD, it is time to market."
key: domaine-sans-ports
date: 2026-10-04
slug: our-domain-layer-is-only-exceptions
---

Articles about hexagonal architecture almost always show the same diagram: a circle in the middle, ports around it, adapters outside, and an arrow pointing inward. None of them ever shows what the `Domain/` folder actually holds six months later.

Here is ours. Nine contexts, and twelve domain files in total: nine exceptions, two enums, one role. Zero interfaces. Zero aggregates. Zero value objects. Calling that a business layer would be a lie, and that is precisely what this piece is about.

## What we kept: the C in CQRS, not the Q

The bus configuration declares three channels with explicit semantics:

```yaml
default_bus: command.bus
buses:
    command.bus:            # a command mutates state, exactly one handler
        default_middleware: { enabled: true, allow_no_handlers: false }
    query.bus:              # a query returns a value, a single handler
        default_middleware: { enabled: true, allow_no_handlers: false }
    event.bus:              # a domain event: 0..n subscribers
        default_middleware: { enabled: true, allow_no_handlers: true }
```

The actual count today: **twenty-nine command handlers, one query handler.** The query bus exists, it is configured, and it is very nearly empty.

That is not migration debt, it is a conclusion. A command earns its ceremony because it brings three things we did not have: a name for an intent (`ChangeCompanySubscriptionPlan` is not `setSubscriptionPlan`), a guarantee that exactly one place executes it — `allow_no_handlers: false` fails at boot, not in production — and an obvious transaction boundary, the handler's.

A read brings none of that. Its shape is dictated by the screen that displays it: this page needs these seven columns, joined this way, sorted like that. Putting that on a bus adds no rule, adds a layer, and moves the SQL from one file to another. So we read through Doctrine repositories, directly, without apologising for it.

One detail matters more than it looks: `default_bus: command.bus`. A bare `dispatch()` is a command. The default is the channel that mutates state — the one thing you never want travelling down the wrong channel by accident.

## What we turned down: dependency inversion

This is the heart of the hexagon in the literature: the domain declares interfaces, infrastructure implements them, the dependency arrow points inward. We did not do it. Here is a full handler, uncut:

```php
#[AsMessageHandler(bus: 'command.bus')]
final readonly class ChangeCompanySubscriptionPlanHandler
{
    public function __construct(
        private EntityManagerInterface $entityManager,
        private LoggerInterface $logger,
    ) {}

    public function __invoke(ChangeCompanySubscriptionPlanCommand $command): void
    {
        $company = $this->entityManager->find(Company::class, Ulid::fromString($command->companyId));
        if (!$company instanceof Company) {
            throw CompanyNotFoundException::withId($command->companyId);
        }
        // …
    }
}
```

`EntityManagerInterface` as a direct dependency. Out of thirty-eight handlers, **twenty-four** depend on it. The `Company` entity comes from `App\Entity`, shared by every context. There is no abstract repository, no port, no domain model distinct from the table.

Two remarks on that example, because they say more than the diagram does.

First, the command carries `string $companyId`, not a `CompanyId` value object. That is not laziness: the message has to be serialisable for asynchronous transport. The bus boundary dictates the shape of the message — infrastructure setting the signature of what we call the domain, from the very first line.

Second, `Ulid::fromString(...)`. The domain identifier exists in two forms depending on whether you are carrying it or querying with it, and that conversion is a storage constraint, not a business one.

## What the boundary buys anyway

One thing, exactly one, and it is worth its price: **coupling between contexts became visible in the import list.**

The handler above lives in `App\Billing`. It imports `App\Company\Domain\Exception\CompanyNotFoundException`. That single import says billing depends on the Company context, and it says so at the top of the file, in one line, with no diagram to keep up to date. The cross-context dependency graph is a `grep` over `use` statements.

That is modest. Compared with a codebase where everything lives in `App\Service`, it is the difference between "we assume it's coupled" and "here is exactly where". That benefit is what we bought, and nothing else.

## The five places infrastructure crosses

Here is what no diagram shows: the places where Doctrine decides the shape of a business operation. These are real leaks, all of them in the code today.

**1. The business rule written in two dialects.** Our policy for keeping internal companies out of commercial figures is one predicate. It exists in two versions, because some read paths are native SQL for performance and others are DQL:

```php
public static function sql(string $alias = 'c'): string  // native queries
{ return ($alias !== '' ? $alias.'.' : '').'excluded_from_stats = false'; }

public static function dql(string $alias = 'c'): string  // ORM queries
{ return $alias.'.excludedFromStats = false'; }
```

One rule, two spellings, because of the query language. The divergence is a single character — `excluded_from_stats` against `excludedFromStats` — so it is invisible to a quick read, and no test would fail if one of the two drifted.

**2. The ambient filter.** Doctrine's soft-delete filter is mutable global state. A query looking for a unique identifier finds nothing while the unique index still holds it. The way out is to disable the filter and put it back:

```php
$filters = $this->em->getFilters();
$wasEnabled = $filters->isEnabled('softdeleteable');
if ($wasEnabled) { $filters->disable('softdeleteable'); }
$existing = $repo->findOneBy(['slug' => $slug]);
if ($wasEnabled) { $filters->enable('softdeleteable'); }
```

A "business query" whose result depends on ambient state is not a function. This is not a Doctrine defect — the filter does exactly what we asked of it — but it forbids reasoning about application code without knowing which mode it runs in.

**3. Write ordering inside the unit of work.** Replacing a piece of content's translations looks like one operation: drop the old ones, add the new ones, save. Within a single `flush()`, Doctrine runs `INSERT`s before orphan `DELETE`s, and the unique constraint on `(feedback_id, locale)` breaks. The operation has to be split into two successive saves.

Put differently: the shape of the application-level operation is not set by the business but by the ORM's internal scheduling. No port would have protected us, because the constraint lives neither in the domain nor in the adapter — it lives in the execution order that connects them.

**4. The join alias that truncates in silence.** Filtering on an association already joined with `fetch` also restricts the hydrated collection: you think you are filtering rows, you are amputating the returned object. Filtering needs its own second join:

```php
$qb->innerJoin('f.industries', 'i_filter')      // alias distinct from the fetch one
   ->andWhere('i_filter.id IN (:industries)');
```

The bug is invisible: the query returns the right entities, with incomplete collections. That is infrastructure semantics, right in the middle of what reads like a search rule.

**5. The identifier's type.** Identifiers travel as ULIDs, compare as RFC 4122 in queries, and forgetting the conversion yields an empty result rather than an error. A port would have moved the conversion; it would not have removed it.

## The migration rule

Which leaves the question that kills rewrites: what do we do with the existing code, written as classic Symfony services?

Nothing, as long as nobody touches it. The policy is written down: **CQRS for new writes and new reads; existing code migrates on demand only.** Never a wholesale rewrite in the name of consistency.

Because consistency is not a business outcome. Rewriting a service that works so it resembles its neighbours produces risk without producing value — and it is exactly the kind of work that justifies itself indefinitely, because its stopping criterion is aesthetic.

## This is not purist DDD, it is time to market

The real reason has to be named, because everything above reads differently once it is on the table.

We have already written here that [the cheapest feature is the one you don't build](/en/the-code-we-dont-write/). A port is a feature. So is an aggregate, so is a value object, so is an anti-corruption layer. Each one costs writing, costs reading for whoever arrives next, and costs upkeep for as long as the code lives. An abstraction is not free because it is immaterial.

So the useful question is not "is this correct DDD". It is: what does this abstraction buy today, and what is it merely postponing? A repository behind an interface buys the ability to change storage — we are not leaving PostgreSQL. It also buys tests without a database, and that one is a real benefit: it is the single argument that may yet make us pay the bill.

What we did instead fits in one sentence: ship, and keep only the boundaries that pay for themselves. The command bus costs three files and helps the same day. Ports cost a whole layer and may help, later, a team that does not exist yet.

The risk in that position is well known, and writing it down is part of the price: it is indistinguishable from laziness at a glance. The difference comes down to one detail — we can name what we did not build, and why.

And we own it. These are our choices, not accidents we would discover on a re-read. We correct them when we can and when we have the time: the day a friction becomes real and measurable, not the day an architecture article explains that they are incorrect. A debt that is written down, dated and argued is not a denied debt — it is the only kind you are able to repay at the right moment.

## What it produced

- **Nine named contexts**, whose mutual coupling is read in the imports rather than in an out-of-date diagram.
- **Twenty-nine commands**, each with an intent name, a single handler guaranteed at boot, and an obvious transaction boundary.
- **One query handler**, deliberately: reads go through repositories.
- **Twelve domain files** — nine exceptions, two enums, one role — which is to say no business rule genuinely isolated from Doctrine.
- **Zero rewrites** of the existing classic code, which keeps working alongside.

## Good practices

- Treat every abstraction as a feature: it has to say what it buys today, not what it would allow one day.
- Adopt the pieces separately. A command bus delivers something without the rest; ports, aggregates and value objects are distinct purchases, each with its own bill.
- Pick the strictest default: the default bus is the one that mutates state, and a missing handler fails the boot rather than production.
- Use namespaces as a coupling detector rather than a barrier: they protect nothing, they make things visible.
- Write the migration rule down, with its stopping criterion. Without one, "harmonising the architecture" is infinite work.
- Look at what `Domain/` actually contains before claiming you do DDD. The count is instructive.

## Watch-outs

- **The folder is not the boundary.** Creating `Domain/`, `Application/`, `Infrastructure/` gives a comforting sense of measurable progress — and measuring an architecture by its folder count is the surest way to get none of the guarantees they suggest.
- **Twenty-four of thirty-eight handlers depend on the `EntityManager`**: none can be tested with an in-memory repository. The test suite needs a real database. That is a cost, it is accepted, it is not free.
- **Shared Doctrine entities are the real coupling**, and it is invisible in the folder tree. The day two contexts want the same table to diverge, that is the wall we will hit — not the absence of ports.
- **A business rule duplicated across two query dialects will eventually drift**, and today nothing would catch it. That is the most concrete debt in everything above.
