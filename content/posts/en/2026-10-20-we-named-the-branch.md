---
title: "We named the branch. The commit landed on main."
standfirst: "In a GitOps repository, main is production. One night in October, manifests nobody had approved landed there, with an image tag that did not exist, and nobody had typed \"main\". Two Git settings, each reasonable, and a command that is right everywhere else."
key: push-sur-main
date: 2026-10-20
slug: we-named-the-branch
---

In a GitOps repository there is no "deploy" button. Argo CD reads the `main` branch of k3s-stack, our (private) infrastructure repository, and makes the cluster converge on what it contains. Pushing to `main` is shipping to production. That is the whole point of the model, and it is why everything goes through a branch, gets reviewed, then merged.

On 19 October at 01:00, a commit landed directly on `main`: the manifests of the small service that shows readers the key exchange their browser just negotiated. Nobody had approved them. And their image carried a placeholder tag, written while waiting for CI to build the real one:

```yaml
images:
  - name: ghcr.io/mesa-black/handshake
    newTag: TO-BE-SET-AFTER-THE-FIRST-BUILD
```

Argo CD did exactly what it is told: it deployed. The pod sat in `ImagePullBackOff` for nine minutes, until CI wrote the real tag at 23:09 UTC. No harm this time: a new service nobody was calling yet. But nobody had typed `git push origin main`.

## The command that was typed

The branch was created in a worktree, from the remote branch, then pushed by naming it explicitly. In substance:

```bash
git worktree add -b feat/handshake ../k3s-handshake origin/HEAD
# … commit …
git push -u origin feat/handshake
```

It was typed by the coding agent we work with, and it is the right command in nearly every configuration. It was not right in ours, because two settings meet.

**The first is a Git default.** A branch created from a remote branch (`origin/main`, or `origin/HEAD`, which points to it) tracks it automatically: that is `branch.autoSetupMerge`, on by default. Our `feat/handshake` therefore had `main` as its upstream, without anyone asking for it.

**The second is a choice, in our `~/.gitconfig`:**

```ini
[push]
    default = upstream
```

With `upstream`, `git push` sends the current branch to its upstream. It is a legitimate setting, designed for workflows where a local branch has a different name from the branch it feeds. With a branch that tracks `main`, it pushes to `main`.

So far, nothing surprising: that is what the documentation says for `git push` with no arguments. The surprise is elsewhere.

## Even when you name the branch

We expected naming the branch, `git push -u origin feat/handshake`, to override the setting. It does not. We replayed it in a throwaway repository, with Git 2.54, each time creating a branch from `origin/main`:

| `push.default` | `git push` | `git push -u origin my-branch` |
|---|---|---|
| `simple`, Git's default | refuses, and explains why | creates `my-branch` |
| `current` | creates the branch | creates `my-branch` |
| `upstream` | **pushes to main** | **pushes to main** |

With `upstream`, a destination missing from the command is replaced by the upstream, even when you wrote the name of the source branch. The name you type says what is sent, not where it lands. Only a destination spelled out in full changes the outcome:

```bash
git push -u origin HEAD:refs/heads/feat/handshake   # does create the branch
```

The script, to check it without us:

```sh
#!/bin/sh
# A branch created from origin/main, pushed by naming it.
set -e
d=$(mktemp -d) && cd "$d"
git init -q --bare -b main remote.git
git clone -q remote.git clone 2>/dev/null && cd clone
git commit -q --allow-empty -m init && git push -q origin main
git switch -q -c my-branch origin/main
git commit -q --allow-empty -m "my-branch"
git -c push.default=upstream push -q -u origin my-branch
git --git-dir=../remote.git for-each-ref --format='%(refname:short)' refs/heads
# prints "main" alone: the branch does not exist, the commit is on main
```

## Why it is worse in a GitOps repository

In an application repository, this push would have put an unreviewed commit on `main`. Annoying, fixable, and CI would probably have complained before anything reached production.

In a GitOps repository there is no step in between. The commit is the deployment. No review, no merge, and in our case not even an image: the controller applied a manifest referencing a tag that did not exist yet. The mistake does not show in Git, where everything looks normal. It shows in the cluster.

And it does not show in the terminal either. The push succeeds, with no warning. The output does say `-> main`, on a line nobody reads after a push that worked.

## What we changed

Three rules, now written into the agent's instructions as well as ours:

1. **Create branches from local `main`, not from `origin/main`.** A branch created from a local branch tracks nothing: `git worktree add -b feat/x ../x main`, or `--no-track` if you start from the remote anyway.
2. **Push with an explicit destination:** `git push -u origin HEAD:refs/heads/feat/x`. It is longer, and it is the only form that gives the same result whatever `push.default` says.
3. **Check `origin/main` after every branch push:** `git log origin/main -1`. If the last commit is ours, it is already in production.

We did not change `push.default`. The setting is useful elsewhere, and changing it would only have fixed our own machine. The rule also protects the agent, which shares the same configuration.

## What is still missing

The real barrier is not on the workstation. It is on the server: a GitHub rule that refuses direct pushes to `main` and requires a pull request, with an exception for the CI deploy key that writes image tags.

Today, k3s-stack's `main` is not protected: no rule on the branch at all. Everything above therefore relies on the discipline of whoever pushes, human or agent. It is the next thing to fix, and we write it down here so it does not stay an intention.

## What it came to

- **One push** to `main`, at 01:00, that no command had asked for in those words.
- **Nine minutes** of a pod in `ImagePullBackOff` in production, on a service nobody was calling yet.
- **Two settings** involved: `branch.autoSetupMerge`, by default, and `push.default = upstream`, by choice.
- **One discovery:** with `upstream`, naming the branch does not change the destination.
- **Three working rules**, and a branch protection still to set up.

## Good practices

- In a repository where `main` is production, protect `main` on the server before anything else. A rule written in a guide protects those who know it; a server rule protects everyone.
- Spell out the destination of a push in full (`HEAD:refs/heads/…`) in scripts and in an agent's instructions: it is the only form independent of local configuration.
- Create working branches from the local branch, so they track nothing by accident.
- After a push, read the line that says where it landed, or check the remote branch.

## Watch out for

- **A right command is only right in one configuration.** `git push -u origin my-branch` is correct nearly everywhere. An agent that learnt it elsewhere will type it on your machine, with your `~/.gitconfig`.
- **An inherited setting shows up in no review.** `push.default = upstream` lives in the global configuration, not in the repository. Nothing flags it until it has had its effect.
- **A successful push does not say where it went.** Git gives no warning when the destination differs from the name typed. The only trace is the `-> main` line.
- **Whoever answers is whoever owns the configuration.** The agent typed the command, but it was our machine that sent it to `main`. We wrote it a few days ago: [an agent can do anything, it cannot answer for what it did](/en/who-answers/).
