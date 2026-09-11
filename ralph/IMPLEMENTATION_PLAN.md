# Implementation Plan — pin every GitHub Action to a commit SHA

> Worked top-to-bottom by `ralph/loop.sh`, one task per iteration. Done means
> `ralph/VALIDATION_CONTRACT.md` holds; read it before you start.

## Why

This template seeds every repo `start-project` creates. Today every `uses:` in
it is a floating ref (`@v7`, `@v4`, `@v5`, ...), so whoever controls an action's
tag or branch controls CI in every repo seeded from here. The fix: pin each
reference to the commit its floating ref points at **today** — pinning must not
change behaviour, so no version moves — and add a CI guardrail that fails on any
unpinned reference, so new repos stay pinned.

Measured 9/11/26 (keep these in mind, do not re-derive them):
- `actions/dependency-review-action@v5` resolves to a **branch** named `v5`, not
  a tag. That is why its CI job is green today; it is also the most floating ref
  in the repo. Its head is the same commit as the `v5.0.0` tag.
- `dtolnay/rust-toolchain` has **no version tags**, only branches, so it cannot
  carry a verifiable `# vX.Y.Z` comment. The Rust snippet switches to `rustup`,
  which GitHub's hosted runners ship (Spec B).
- `actionlint` does **not** catch a bad pin (a truncated SHA passes it). The pin
  checker is not redundant with it.
- With no `.git` directory, a bare `actionlint` exits 3 ("no project was
  found"). Always pass the files: `actionlint .github/workflows/*.yml`.

## Conventions

- `- [ ]` open · `- [x]` done · `- [!]` blocked (reason in `PROGRESS.md`)
- The loop always takes the topmost open item.
- **How to test in this repo.** The template has no stack yet, so the command
  table in `AGENTS.md` is still placeholder text — do not try to run it. The
  checks that matter are the `guardrails` job in `.github/workflows/ci.yml`;
  Spec F is that job, runnable locally. Install the linters with the Toolbox
  block first.
- Never change a version while pinning. If a reference on the branch no longer
  matches its Pin table row (a dependabot PR merged first), resolve the version
  that IS on the branch with the resolve command in Spec D. Never bump.

---

## Tasks

- [ ] T1 — Create the pin checker at .github/scripts/check-action-pins.sh, mode 755, exactly per Spec A. Verify: `bash .github/scripts/check-action-pins.sh; echo "exit=$?"` lists every current floating ref as `path:line:` lines, then the summary line, then `exit=1`; and `shellcheck -S warning .github/scripts/check-action-pins.sh` exits 0.
- [ ] T2 — Pin every `uses:` in the five files under `.github/workflows/` using the Pin table, including the commented `# - uses: actions/setup-node@v4` example in `.github/workflows/ci.yml`. Verify: `grep -rn 'uses:' .github/workflows | grep -vE '@[0-9a-f]{40} # v[0-9]'` prints nothing and exits 1.
- [ ] T3 — Pin the CI setup blocks in `plugin/skills/start-project/references/` (go.md, node-ts.md, python.md, rust-cache in rust.md) from the Pin table; replace rust.md's toolchain step per Spec B. Verify: `grep -rn 'uses:' plugin/skills/start-project/references | grep -vE '@[0-9a-f]{40} # v[0-9]'` prints nothing; `grep -c 'uses: dtolnay' plugin/skills/start-project/references/rust.md` prints 0.
- [ ] T4 — Wire the checker into the `guardrails` job of `.github/workflows/ci.yml`, exactly the five edits in Spec C. Verify: `grep -c '\.github/scripts/' .github/workflows/ci.yml` prints 5, and `bash .github/scripts/check-action-pins.sh; echo "exit=$?"` prints the `all pinned` summary and `exit=0`.
- [ ] T5 — Document the rule in `docs/security.md` per Spec G. Verify: `grep -n 'check-action-pins' docs/security.md` prints the new bullet, and `git diff --stat docs/security.md` shows only insertions.
- [ ] T6 — Prove every pin comment is true: run the Spec D audit block. It prints `OK` on every line (10 lines on the 9/11/26 tree) and no `MISMATCH`. Paste the output into PROGRESS.md. On a MISMATCH, re-resolve that row with Spec D's resolve command and fix the SHA, never just the comment.
- [ ] T7 — Prove a regression is caught with no git checkout: run the Spec E block. Its first run prints a `.github/workflows/ci.yml:<n>:` line and `exit=1`; its second prints `exit=0`. Paste both into PROGRESS.md. This task changes no tracked file except the notebook.
- [ ] T8 — Full local guardrail run: install linters with the Toolbox block, then run every command in Spec F; each exits 0, and `actionlint .github/workflows/*.yml` prints nothing. Paste the summary lines into PROGRESS.md. If all eight tasks are ticked and green, append RALPH_COMPLETE.

---

## Pin table

Resolved 9/11/26 with `git ls-remote`. Every floating ref below pointed at
exactly this commit, so each pin is a no-op for behaviour. Replace the whole
`owner/repo@ref` token and add the comment with exactly one space each side of
`#`, e.g. `uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1`.

| today | pin to | comment | where |
|---|---|---|---|
| `actions/checkout@v7` | `actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1` | `# v7.0.1` | ci.yml ×2, claude-issue.yml, codeql.yml, dependency-review.yml, release-skill.yml |
| `anthropics/claude-code-action@v1.0.211` | `anthropics/claude-code-action@833fb0f8c9f6686b33d963a8bae0a94f4936ab2a` | `# v1.0.211` | claude-issue.yml |
| `github/codeql-action/init@v4` | `github/codeql-action/init@b96794f015dfd88f77b49b1c93e0fa7110f94c63` | `# v4.38.0` | codeql.yml |
| `github/codeql-action/autobuild@v4` | `github/codeql-action/autobuild@b96794f015dfd88f77b49b1c93e0fa7110f94c63` | `# v4.38.0` | codeql.yml |
| `github/codeql-action/analyze@v4` | `github/codeql-action/analyze@b96794f015dfd88f77b49b1c93e0fa7110f94c63` | `# v4.38.0` | codeql.yml |
| `actions/dependency-review-action@v5` | `actions/dependency-review-action@a1d282b36b6f3519aa1f3fc636f609c47dddb294` | `# v5.0.0` | dependency-review.yml |
| `actions/setup-node@v4` | `actions/setup-node@49933ea5288caeca8642d1e84afbd3f7d6820020` | `# v4.4.0` | ci.yml (commented example), references/node-ts.md |
| `actions/setup-go@v5` | `actions/setup-go@40f1582b2485089dde7abd97c1529aa768e1baff` | `# v5.6.0` | references/go.md |
| `actions/setup-python@v5` | `actions/setup-python@a26af69be951a213d495a4c3e4e4022e16d87065` | `# v5.6.0` | references/python.md |
| `Swatinem/rust-cache@v2` | `Swatinem/rust-cache@6323deb102c322ba6fcbdcafc7e3dddab59af2b6` | `# v2.9.2` | references/rust.md |
| `dtolnay/rust-toolchain@stable` | removed — see Spec B | — | references/rust.md |

In the commented ci.yml example keep the leading `# ` and the indentation; only
the ref changes.

## Spec A — the pin checker

A bash script at .github/scripts/check-action-pins.sh (create the directory),
committed with mode 755. Pure bash plus grep/sed/awk, `set -uo pipefail`, no
network, **no git dependency** — it must work on a copy with no `.git`.

- **Usage:** `bash .github/scripts/check-action-pins.sh [ROOT]`. ROOT defaults to `.`.
- **Scans:** every `*.yml` and `*.yaml` directly under `ROOT/.github/workflows/`,
  plus every `*.md` directly under `ROOT/plugin/skills/start-project/references/` **if that
  directory exists** — `plugin/` is deleted from generated projects, so skip it
  silently when absent.
- **Fails closed:** if `ROOT/.github/workflows` does not exist, print
  `check-action-pins: no .github/workflows under ROOT` (with the real ROOT) to
  stderr and exit 2.
- **A reference** is any line whose content, after leading whitespace, is
  `uses:`, `- uses:`, `# uses:` or `# - uses:` followed by a value. Commented
  lines count: they are examples that get pasted into real workflows.
- **A reference passes** when its value is a local path starting with `./`, or
  `owner/repo@SHA` or `owner/repo/sub/path@SHA` where SHA is exactly 40 lowercase
  hex characters, followed by exactly ` # v` and a digit (e.g. `# v7.0.1`).
  Anything else fails — `@v7`, `@main`, `@stable`, a short SHA, a SHA with no
  version comment, a `docker://` ref.
- **Output per failure** (stdout): `path:line: <the line, leading whitespace
  trimmed>`, path relative to ROOT — e.g.
  `.github/workflows/ci.yml:26: - uses: actions/checkout@v7`.
- **Summary** (stdout, last line):
  - pass, exit 0: `check-action-pins: N references, all pinned to a commit SHA`
  - fail, exit 1: `check-action-pins: K of N references are not pinned to a commit SHA -- pin to the full 40-char SHA with a '# vX.Y.Z' comment (docs/security.md)`
- A header comment of 3-6 lines saying why it exists (the template seeds every
  new repo; a floating tag is a supply-chain path into all of them) and what
  passes. Do not put a `uses:` example inside the script.

## Spec B — the Rust starter snippet

In `plugin/skills/start-project/references/rust.md`, the CI setup block becomes
exactly:

```yaml
      - run: rustup toolchain install stable --profile minimal --component clippy,rustfmt && rustup default stable
      - uses: Swatinem/rust-cache@6323deb102c322ba6fcbdcafc7e3dddab59af2b6 # v2.9.2
```

(`--component` takes a comma-separated list — checked against `rustup toolchain
install --help`.) Then add this bullet under that file's `## Notes`:

- The toolchain comes from `rustup`, which GitHub-hosted runners ship, not from a
  third-party action: `dtolnay/rust-toolchain` publishes branches rather than
  version tags, so it cannot be pinned with a verifiable version comment.

## Spec C — CI wiring (all in `.github/workflows/ci.yml`, `guardrails` job)

1. **Required context files exist** — add a continuation line holding
   .github/scripts/check-action-pins.sh directly after the line that lists
   `ralph/PROMPT.md ralph/IMPLEMENTATION_PLAN.md ralph/PROGRESS.md ralph/loop.sh \`,
   matching that line's indentation and ending in ` \`.
2. **New step**, directly after the "Required context files exist" step:
   ```yaml
         - name: Actions pinned to commit SHAs
           run: bash .github/scripts/check-action-pins.sh
   ```
3. **Hooks are executable** — `for h in .claude/hooks/*.sh ralph/loop.sh; do`
   becomes `for h in .claude/hooks/*.sh .github/scripts/*.sh ralph/loop.sh; do`.
4. **Shell syntax** — `for f in .claude/hooks/*.sh ralph/loop.sh; do` becomes
   `for f in .claude/hooks/*.sh .github/scripts/*.sh ralph/loop.sh; do`.
5. **shellcheck** — append ` .github/scripts/*.sh` to the
   `shellcheck -S warning .claude/hooks/*.sh ralph/loop.sh .claude/statusline.sh` line.

Nothing else in ci.yml changes except the two `actions/checkout` pins and the
commented setup-node example from T2.

## Spec D — audit the pins against upstream (T6)

Run from the repo root. Needs network, nothing else.

```bash
grep -rhoE 'uses: [A-Za-z0-9_.-]+/[A-Za-z0-9_./-]+@[0-9a-f]{40} # v[0-9][^ ]*' \
    .github/workflows plugin/skills/start-project/references | sort -u |
while read -r _ ref _ ver; do
  repo=$(printf '%s\n' "${ref%@*}" | cut -d/ -f1-2); sha=${ref#*@}
  if git ls-remote --tags "https://github.com/$repo" "refs/tags/$ver" "refs/tags/$ver^{}" | grep -q "^$sha"; then
    echo "OK       $repo $ver $sha"
  else
    echo "MISMATCH $repo $ver $sha"
  fi
done
```

The three codeql-action refs share one repo and SHA, so they print three
identical `OK` lines; that is expected.

**Resolve command** (only to fix a MISMATCH, or a version that moved on main):
`git ls-remote --tags https://github.com/<owner>/<repo> 'refs/tags/<version>' 'refs/tags/<version>^{}'`
— take the SHA on the `^{}` line if there is one (annotated tag), otherwise the
plain line.

## Spec E — prove a regression is caught (T7)

```bash
tmp=$(mktemp -d)
cp -r .github "$tmp/"
mkdir -p "$tmp/plugin/skills/start-project"
cp -r plugin/skills/start-project/references "$tmp/plugin/skills/start-project/"
sed -i -E '0,/actions\/checkout@[0-9a-f]{40} # v[^ ]+/s//actions\/checkout@v7/' "$tmp/.github/workflows/ci.yml"
bash .github/scripts/check-action-pins.sh "$tmp"; echo "exit=$?"   # a ci.yml:<n>: line, then exit=1
bash .github/scripts/check-action-pins.sh; echo "exit=$?"          # all pinned, exit=0
rm -rf "$tmp"
```

The copy has no `.git`, which is the point: the verifier's clean room has none.

## Spec F — the guardrails job, locally (T8)

```bash
./.claude/hooks/test-hooks.sh
shellcheck -S warning .claude/hooks/*.sh ralph/loop.sh .claude/statusline.sh .github/scripts/*.sh
shellcheck -S warning plugin/skills/start-project/scripts/*.sh
actionlint .github/workflows/*.yml
bash .github/scripts/check-action-pins.sh
```

## Toolbox — linters on the Ralph pod

The pod image (node:22-bookworm-slim, arm64) has git, curl, jq and python3 but
no shellcheck or actionlint. This installs both into `$HOME/bin` and was run
clean on 9/11/26:

```bash
mkdir -p "$HOME/bin"; export PATH="$HOME/bin:$PATH"
case "$(uname -m)" in aarch64|arm64) al=arm64; sc=aarch64 ;; *) al=amd64; sc=x86_64 ;; esac
command -v actionlint >/dev/null || curl -fsSL "https://github.com/rhysd/actionlint/releases/download/v1.7.7/actionlint_1.7.7_linux_${al}.tar.gz" | tar -xz -C "$HOME/bin" actionlint
command -v shellcheck >/dev/null || { curl -fsSL "https://github.com/koalaman/shellcheck/releases/download/v0.10.0/shellcheck-v0.10.0.linux.${sc}.tar.xz" | python3 -c 'import io,sys,tarfile; t=tarfile.open(fileobj=io.BytesIO(sys.stdin.buffer.read()),mode="r:xz"); open(sys.argv[1],"wb").write(t.extractfile("shellcheck-v0.10.0/shellcheck").read())' "$HOME/bin/shellcheck" && chmod +x "$HOME/bin/shellcheck"; }
```

## Spec G — docs/security.md

Under `### 4. Dependencies`, after the Dependabot bullet, add exactly one bullet:

- Every GitHub Action is pinned to a full 40-character commit SHA with a
  `# vX.Y.Z` comment naming the tag it came from. A tag or branch can be
  re-pointed by whoever controls the action; a SHA cannot. CI enforces this
  (`bash .github/scripts/check-action-pins.sh` in the guardrails job), and
  Dependabot bumps the SHA and the comment together.

Write it as a single bullet line in the file (wrapped here for reading only).

---

## Files touched

The only paths this milestone may change. A diff outside this list is rejected.

- .github/scripts/check-action-pins.sh (new)
- .github/workflows/ci.yml
- .github/workflows/claude-issue.yml
- .github/workflows/codeql.yml
- .github/workflows/dependency-review.yml
- .github/workflows/release-skill.yml
- plugin/skills/start-project/references/go.md
- plugin/skills/start-project/references/node-ts.md
- plugin/skills/start-project/references/python.md
- plugin/skills/start-project/references/rust.md
- docs/security.md
- ralph/IMPLEMENTATION_PLAN.md and ralph/PROGRESS.md (ticks and notebook only)

## Out of scope

Things deliberately NOT being done, so no iteration wanders into them.

- Bumping any action to a newer major. setup-go, setup-node and setup-python
  are two majors behind (v7 exists); moving them is a separate, deliberate change.
- Dependabot PR #10 (claude-code-action 1.0.211 → 1.0.217). Do not merge,
  rebase or copy it; Dependabot rebases it onto pinned form itself.
- Making Dependabot update the markdown snippets — it only reads workflow files.
  A pasted snippet is kept current by the new repo's own Dependabot.
- Checksum-pinning the actionlint tarball the guardrails job downloads, or the
  spec-kit install in README.md. They are not `uses:` references; log them as
  findings in PROGRESS.md if you want them tracked.
- `AGENTS.md` (150-line budget), CodeQL enablement, and any placeholder marker
  already in the tree.
