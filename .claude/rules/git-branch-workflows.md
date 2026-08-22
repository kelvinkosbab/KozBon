---
description: Fast task switching between branches and PRs — dirty-tree discipline, one-keystroke switch-back, worktrees for parallel work, and safe cleanup of merged branches (including squash merges)
globs: "**/*.{swift,h,m,mm,kt,kts}"
---

# Git Branch Workflows

Task switching is constant: a PR review lands mid-feature, a hotfix jumps the queue, then back to the feature. The goal is that a switch costs seconds and nothing is ever lost — and that merged branches get cleaned up instead of accumulating. Run the bundle's [`scripts/setup-git-shortcuts.sh`](../../scripts/setup-git-shortcuts.sh) once to install the aliases referenced below.

## Switching tasks

- **`git switch -` toggles to the previous branch** — the one-keystroke switch-back (alias: `git back`). Prefer `git switch` over `git checkout` everywhere; `checkout` does too many unrelated things.
- **Never switch with a dirty tree you care about.** Two safe parking options:
  - `git save "msg"` (`stash push -u -m`) — quick hops. The `-u` matters: plain `stash` leaves *untracked* files behind, and they follow you into the other branch as confusing strays. Restore with `git pop`.
  - A WIP commit (`git add -A && git commit -m "wip"`) — better for longer detours; nothing can be dropped, and `git reset --soft HEAD~1` un-wips on return. Never push a `wip` commit; squash or reset it first.
- **Agents:** uncommitted changes in the tree may be the user's un-parked work. Park with a *named* stash (or ask) before switching branches; never `git checkout .` / `restore .` your way to a clean tree.

## Parallel work — worktrees

When a switch isn't a hop but a *second concurrent task* (review a PR while your feature stays open in the IDE), use a worktree instead of switching in place:

```bash
git worktree add ../MyApp-pr-142 origin/feature/pr-142   # separate dir, same repo
git worktree remove ../MyApp-pr-142                       # when done
```

- Each worktree has its own working tree and checked-out branch — no stash dance, and Xcode's per-directory DerivedData / Gradle's build dirs mean **no rebuild churn** when you return to the main checkout.
- **Gitignored files don't follow you**: `local.properties`, `.env`, `settings.local.json`, provisioning assets must be recreated per worktree. Check them first when a fresh worktree won't build.
- One branch can only be checked out in one worktree at a time — that's the feature, not a bug.

## Cleaning up after merge

Merged branches rot fast, and the GitHub default (**squash merge**) makes them invisible to `git branch --merged` — the local branch's commits were never merged by ancestry, only their squashed copy was. Detection that works:

1. `git fetch --prune` — drop remote-tracking refs for deleted remote branches.
2. **Ancestry-merged** branches (`git branch --merged origin/HEAD`) are safe to delete with `-d`.
3. **Squash-merged** branches show as `[gone]` (`git for-each-ref --format '%(refname:short) %(upstream:track)'`) — upstream deleted after merge. These need `-D`, so **list and confirm before deleting**; a `[gone]` branch could also be un-merged work whose remote was cleaned up.

The `git tidy` alias (from `setup-git-shortcuts.sh`) runs exactly this sequence: fetch-prune → show both lists → delete merged with `-d` → confirm separately before `-D`-ing the gone set. Never deletes the current branch or `main`/`master`/`develop`.

- **Agents:** branch deletion is destructive — surface the candidate list and get explicit confirmation; never run `git branch -D` (or `git tidy`'s confirm step) unprompted. This restates the repo-wide git guardrails.
- Delete the *remote* branch at merge time (GitHub's "delete branch" button / auto-delete setting) so `[gone]` detection has something to detect.

## Habits that keep switches cheap

- One task, one branch, named for the task (`fix/scan-crash`, `pr-142-review`) — `git branch --sort=-committerdate` (alias: `git recent`) then reads as your task list.
- Rebase-or-merge from `main` *before* starting a switch-heavy day, not after — conflicts are cheapest when fresh.
- Commit (or `git save`) before any operation you don't fully understand. A committed change is unloseable; `git reflog` recovers almost anything else.
