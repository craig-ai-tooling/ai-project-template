#!/usr/bin/env bash
# Ralph loop — run Claude Code headless, ONE task per iteration, fresh context.
#
# The whole point is a fresh context every iteration. Long-running sessions drift,
# forget the plan, and start inventing. Each iteration re-reads the plan from disk,
# does exactly one task, commits, and exits. State lives in git and in
# the notebook (ralph/*.md, or ralph/plans/<id>/ for a dispatched task; see
# "which notebook?" below) — never in a conversation.
#
# Usage:
#   ./ralph/loop.sh              # up to 20 iterations
#   ./ralph/loop.sh 5            # up to 5
#   DRY_RUN=1 ./ralph/loop.sh 1  # print the command, run nothing
#   RALPH_PLAN=<id> ./ralph/loop.sh  # work ralph/plans/<id>/ instead of ralph/
#
# Stops when: the cap is hit, the plan reports complete, or an iteration fails.
set -euo pipefail

MAX_ITERATIONS="${1:-20}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# ── which notebook? ─────────────────────────────────────────────────────
# A dispatched run works ONE task's notebook at ralph/plans/<id>/, the shape
# ai-lawnmower's ralph-prepare.sh writes and its runner Job names with
# RALPH_PLAN. Before this block the loop always read ralph/*.md, so a pod sent
# to do task X worked whatever the root notebook held instead.
#
# Resolution order: $RALPH_PLAN_DIR verbatim if set; else ralph/plans/$RALPH_PLAN
# if that is set; else <id> from a branch literally named plan/<id>; else the
# root notebook (ralph/*.md), which is how a human runs a freshly scaffolded
# repo. A named task whose notebook is missing FATALs below; it never falls back
# to the root notebook.
PLAN_ID="${RALPH_PLAN:-}"
if [[ -z "${RALPH_PLAN_DIR:-}" && -z "$PLAN_ID" ]]; then
  CUR_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
  if [[ "$CUR_BRANCH" =~ ^plan/([A-Za-z0-9._-]+)$ ]]; then
    PLAN_ID="${BASH_REMATCH[1]}"
  fi
fi
if [[ -n "${RALPH_PLAN_DIR:-}" ]]; then
  case "$RALPH_PLAN_DIR" in
    ralph/plans/*..*)
      echo "FATAL: invalid RALPH_PLAN_DIR '$RALPH_PLAN_DIR' (no '..')" >&2
      exit 2 ;;
    ralph/plans/*) ;;
    *)
      echo "FATAL: invalid RALPH_PLAN_DIR '$RALPH_PLAN_DIR' (must start with ralph/plans/)" >&2
      exit 2 ;;
  esac
elif [[ -n "$PLAN_ID" ]]; then
  case "$PLAN_ID" in
    *..*|.*|*/*)
      echo "FATAL: invalid RALPH_PLAN '$PLAN_ID' (no '..', no leading '.', no '/')" >&2
      exit 2 ;;
  esac
  RALPH_PLAN_DIR="ralph/plans/${PLAN_ID}"
else
  RALPH_PLAN_DIR="ralph"
fi

PROMPT_FILE="${RALPH_PLAN_DIR}/PROMPT.md"
PLAN_FILE="${RALPH_PLAN_DIR}/IMPLEMENTATION_PLAN.md"
PROGRESS_FILE="${RALPH_PLAN_DIR}/PROGRESS.md"
DONE_SIGNAL="RALPH_COMPLETE"

for f in "$PROMPT_FILE" "$PLAN_FILE" "$PROGRESS_FILE"; do
  [[ -f "$f" ]] || { echo "FATAL: missing $f" >&2; exit 1; }
done
command -v claude >/dev/null 2>&1 || { echo "FATAL: 'claude' CLI not on PATH" >&2; exit 1; }

if [[ -n "$(git status --porcelain)" ]]; then
  echo "FATAL: working tree is dirty. Commit or stash first — the loop commits" >&2
  echo "       after every iteration and must start from a clean base." >&2
  exit 1
fi

# A sentinel already in the notebook would end iteration 1 and report the plan
# complete with every task still open. Refuse at startup instead.
if grep -qxF "$DONE_SIGNAL" "$PROGRESS_FILE" 2>/dev/null; then
  echo "FATAL: ${PROGRESS_FILE} already contains a ${DONE_SIGNAL} line." >&2
  echo "       Archive the finished notebook and start a fresh one." >&2
  exit 1
fi

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$BRANCH" == "main" || "$BRANCH" == "master" ]]; then
  echo "FATAL: refusing to run on '$BRANCH'. Branch first:" >&2
  echo "       git switch -c feat/<name>" >&2
  exit 1
fi

echo "Ralph loop: max ${MAX_ITERATIONS} iterations on branch '${BRANCH}'"
echo

for (( i=1; i<=MAX_ITERATIONS; i++ )); do
  echo "──────────────────────────────────────────────────────────"
  echo "  Iteration ${i}/${MAX_ITERATIONS}  ($(date -u +%H:%M:%SZ))"
  echo "──────────────────────────────────────────────────────────"

  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    echo "[dry-run] claude -p \"\$(cat $PROMPT_FILE)\" --permission-mode acceptEdits"
    break
  fi

  # Fresh process = fresh context. Settings are passed explicitly so the repo
  # hooks (danger-guard, format-and-lint) apply to autonomous runs too.
  set +e
  claude -p "$(cat "$PROMPT_FILE")" \
    --permission-mode acceptEdits \
    --settings .claude/settings.json
  rc=$?
  set -e

  if [[ $rc -ne 0 ]]; then
    echo
    echo "Iteration ${i} exited ${rc}. Stopping so a human can look." >&2
    exit "$rc"
  fi

  # The agent is instructed to commit its own work. If it left anything staged
  # or dirty, capture it rather than silently carrying it into the next context.
  if [[ -n "$(git status --porcelain)" ]]; then
    git add -A
    git commit -m "ralph: iteration ${i} (sweep uncommitted changes)" --no-verify
    echo "  (swept uncommitted changes into a commit)"
  fi

  # A whole line, not a substring: PROGRESS.md's own header names the signal
  # while explaining it, so a substring match "finished" every plan after
  # iteration 1 with all its tasks still open.
  if grep -qxF "$DONE_SIGNAL" "$PROGRESS_FILE" 2>/dev/null; then
    echo
    echo "Found ${DONE_SIGNAL} in ${PROGRESS_FILE}. Plan complete after ${i} iteration(s)."
    exit 0
  fi

  echo "  Iteration ${i} done."
  echo
done

echo "Reached the ${MAX_ITERATIONS}-iteration cap without ${DONE_SIGNAL}."
echo "Review ${PROGRESS_FILE}, then re-run to continue."
