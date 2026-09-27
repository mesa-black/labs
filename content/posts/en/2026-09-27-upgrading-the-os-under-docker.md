---
title: "Upgrading the OS under Docker: what is still coupled, and what nothing validates"
standfirst: "The application lives in an image, so the distribution cannot touch it. Four coupling points remain — and one of them sits in a blind spot no pipeline covers."
date: 2026-09-27
key: monter-l-os-sous-docker
slug: upgrading-the-os-under-docker
draft: true
---

Show me the REX runs on a single host: one Postgres, one Redis, one front proxy, and the application deployed blue-green — two identical instances, "blue" and "green", of which only one serves traffic at a time. A new version is started on the idle one, and once it answers correctly the proxy is switched over. At the time of writing, that host serves 52 published case studies and a little over 16,000 cumulative views.

This arrangement protects a release: if the new version misbehaves, switching back takes a second and nobody notices. It protects nothing at all against the machine itself, since both instances sit on that same host — stop it and you stop them both.

The single host is a deliberate choice, not an oversight: no redundancy until traffic justifies it, and the threshold for revisiting it is written down — a thousand visits a day. Below that, a second machine costs far more in complexity (replication, failover, consistency) than it returns in availability, and complexity nobody needs yet is the most expensive thing you can build.

Owning that choice creates an obligation, though. If you accept that a reboot takes the service down, you owe yourself an exact figure for what it costs. That is the part we got wrong that night, and we come back to it at the end.

We moved that host from one Ubuntu release to the next. The operation went through — and that is not the interesting part. The interesting part is that containerisation has narrowed what such an upgrade can still break down to a very short list, and that we found exactly the item on it that nothing in our chain was watching.

## What containerisation actually decoupled

The application is immune to a distribution upgrade, and it is worth being precise about why: it does not use anything from the host. Its PHP, its extensions, its system libraries, its CA bundle all ship inside the image. The host's `ca-certificates` can be replaced wholesale — our outbound calls to VIES, the payment provider and object storage are unaffected, because they never read that store.

This is why teams have come to treat an OS upgrade on a container host as routine. It is very nearly true, and it is the "very nearly" that costs.

## The four coupling points that remain

Once you have moved everything you can into images, what still belongs to the host is a short list — and it is the same list on every containerised server:

1. **The kernel.** Containers share it. A major jump changes the ground under a database far more than under a web process.
2. **The Docker daemon.** It is not in your image; it is a host package, installed from a third-party repository.
3. **The apt sources for that daemon.** The thing that decides whether the previous point ever gets a security patch again.
4. **The restart contract.** Which containers come back on their own after a boot, and which deliberately do not — the idle instance, for one, must stay down, or two versions of the application would fight over the same database.

Nothing else really matters. That list is short enough to be checked by hand, before and after — which is precisely what makes not checking it inexcusable.

## The only lasting damage landed on point three

A release upgrade disables or removes third-party apt sources. This is not a bug: those sources are built for the release you are leaving, and keeping them enabled across the jump is how you break a system. The tool is right to do it, and it says so.

What it does not do is tell you afterwards. Our Docker source was gone. Nothing broke — the daemon kept running, the containers with it, the site served. But the installed package had been built for the previous distribution, and there was no longer any repository able to replace it. **The failure mode is not a service that stops; it is a package manager that becomes authoritative and empty at the same time.** It reports that everything is up to date, and it is telling the truth about a universe it can no longer see.

Restoring the source is four lines and no restart. It immediately revealed seven minor versions of drift accumulated in silence. Nothing would ever have raised a hand: not the daemon, which works; not the monitoring we do not have; not `apt`, which had nothing left to compare against.

## The blind spot: the compose files

Then the structural finding, which is the one worth taking away.

Our database service had no restart policy. After a reboot, every other container would have come back and Postgres would not. The bug is trivial — one missing line. Its lifespan is not: it had been there for months, and it could only manifest on a host reboot, which had not happened in that whole time.

The real question is not how it got written. It is why nothing caught it. And the answer generalises well beyond our setup: **the compose files are the only production configuration that nothing owns.** They are not baked into the image, so the build never sees them. No test exercises them, because tests run against the application, not against the host's topology. And our deploy job does not even copy them — it opens an SSH session and runs a script. They are edited in the repository, applied by hand, and validated by nothing.

In a chain that is otherwise fully automated — tests, static analysis, image build, zero-downtime deploy — that is where a defect can sleep indefinitely. Not in the code the pipeline reads twenty times a day, but in the handful of YAML lines it never opens.

## What the kernel could have broken, and what we did not verify

A major kernel jump under a containerised Postgres deserves more than "it came back up". Three questions are worth asking, and we can only answer the first two:

- *The data directory.* It lives in a named volume, on the same filesystem, with the same storage driver. Nothing moved — and that is the reason the upgrade was survivable at all, not luck.
- *The daemon's confinement profiles.* Seccomp and AppArmor defaults ship with the Docker package, not with the distribution, which is why the containers found the same environment on the other side.
- *Durability semantics.* Whether a new kernel changes anything for Postgres under our mount options is a question we did not answer. It held, which proves nothing. We are writing it down rather than claiming a verification we never ran.

## The measurement already existed

Which leaves the obligation set out at the start: knowing the real cost of the outage we chose to accept. We stated a figure by reading container logs — the gap between a process's last error and the next one's start. That number describes the host, not the visitors. It leaves out the shutdown before it and the warm-up after, and it can be off by a factor of three.

Meanwhile all our traffic goes through a CDN, which had already recorded, request by request, exactly what people got during that window. **The measurement we thought we lacked had been taken for us, by an appliance we had been paying for and never queried.**

The reflex to fix is not "add instrumentation". It is to inventory what already measures before adding anything: the CDN, the reverse proxy's own logs, the provider's console. Our procedural slips that night — a guessed container name, shell variables that do not survive an SSH reconnection, a grep loose enough to report 41 lines for 2 errors — all belong to the same family, and they are worth exactly one sentence: a runbook must resolve what it needs, never freeze it. Which instance is live is the textbook case: it changes at every deploy.

## Why we publish all of this — and the one thing we hold back

A report is only useful if it is specific, so this one carries the commands, the failure modes and the gaps. Which raises a fair question: is publishing all that not handing an attacker a map?

Our rule fits in one sentence. **The problem is never naming a version. It is naming a version you are still vulnerable on.**

"We were on version X, it cost us this, it is patched" is ordinary post-mortem practice. The same text published before the fix is a weakness that is still true with the target attached — a case study is signed, it names a company and a domain. So: fix first, tell afterwards, and generalise whatever teaches nothing. The *gap* — seven versions of silent drift — is the lesson; our host's exact version string is not. What never gets published is the other category, the part that cannot be learned from but can be copied: host names, paths, the chain of keys that decrypts a backup. The line is not "sensitive versus harmless" — it is **does this teach, or does this open?**

## What it gave us

- **Four coupling points** isolated between a containerised application and its host: kernel, daemon, the daemon's apt sources, restart contract. Short enough to check by hand, before and after.
- **A frozen update path restored**: the daemon had drifted seven minor versions behind, with nothing able to report it.
- **A structural blind spot named**: the compose files, the only production configuration that no build, no test and no deploy job ever reads.
- **A measurement recovered rather than built**: the CDN had already recorded what visitors saw, for free.

## Good practices

- Write down your coupling points once. On a container host there are four of them, they are always the same, and checking them takes ten minutes.
- After a release upgrade, re-check the third-party sources first: a package manager with nothing left to compare against reports that everything is up to date, and it is not lying.
- Look for what your automation does not own. In a fully automated chain, the defect that survives is in the file the pipeline never opens.
- Inventory what already measures — CDN, proxy, provider console — before adding instrumentation. The figure you are missing has often already been recorded.
- A runbook resolves, it never freezes: which instance is live, its container name, the service id — all of it is asked for at call time.

## Watch-outs

- The dangerous failure is not the service that stops, it is the one that keeps working while losing its ability to be updated. It emits nothing.
- "It came back up" proves nothing about durability. Write down the questions you did not answer rather than claiming a verification you never ran.
- A defect that can only manifest on a host reboot has the lifespan of the interval between two reboots. On a well-behaved server, that is months.
- An internal log says when a process died, never when visitors stopped being served. Only a measurement taken in front of the stack says that.
- **Fix before you tell: a report describing a weakness that is still open, signed with your own name, is not transparency — it is an instruction manual.**
