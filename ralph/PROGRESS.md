# Progress

> Append-only notebook. Newest at the bottom. Never edit or delete past entries —
> this is the loop's only memory across fresh contexts.

Each iteration appends:

```
## Iteration N — YYYY-MM-DD HH:MM
**Did:** one or two lines.
**Learned:** anything that would otherwise be rediscovered the hard way.
**Left:** what remains.
**Findings:** problems noticed but not fixed (ad-hoc bugs, smells, risks).
```

Findings are the point of this file as much as progress is. An observation that
dies in a context window is a bug you will pay for twice. Real ad-hoc fixes also
get a one-liner in `docs/fixes-log.md`.

When the whole plan is done and green, append a line containing exactly
`RALPH_COMPLETE` — `loop.sh` stops on it.

---

## Iteration 0 — template initialized
**Did:** Scaffolded the repo. No project work yet.
**Learned:** n/a
**Left:** Everything in `ralph/IMPLEMENTATION_PLAN.md`.
**Findings:** none

## Milestone brief — 2026-09-11 (lm-ai-project-template-pins-no-action-to-a-32)
**Did:** Plan and contract written by hand after the generated plan failed the readiness gate twice. Its fifth assertion had no runnable check and claimed dependency-review fails on every PR; it does not — that job has been green on every PR (7/30, 8/13, 9/3, 9/10).
**Learned:** Measured 9/11/26 — `actions/dependency-review-action@v5` is a branch, not a tag; `dtolnay/rust-toolchain` has no version tags at all; actionlint does not catch a truncated SHA; a bare `actionlint` exits 3 with no `.git`, so pass `.github/workflows/*.yml`; the Ralph pod image has no shellcheck or actionlint (the plan's Toolbox block installs both). Every SHA in the Pin table was checked against upstream with the Spec D audit on a pinned scratch copy: 10 OK, 0 MISMATCH.
**Left:** T1–T8 in `ralph/IMPLEMENTATION_PLAN.md`.
**Findings:** `ralph/loop.sh` used to match its exit sentinel as a substring, and this file's header names the sentinel, so every run stopped after iteration 1. Fixed on main (PR #11) before this milestone was dispatched.
