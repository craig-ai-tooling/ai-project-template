# Validation contract

What "done" means for this milestone, decided before the work was decomposed.

A later pass checks the finished repository against this file as a **black box** —
no diff, no history, no knowledge of how it was built, and possibly no `.git`
directory. Every assertion below names its own check and stands on its own. Run
every command from the repository root.

Context in one sentence: this template is copied into every repo the
`start-project` skill creates, so a floating action tag here is a supply-chain
write path into every repo seeded from it.

---

## Assertions

- Nothing the template ships names a GitHub Action by a floating tag or branch — not its own workflow steps, not the commented-out starter example in the CI workflow, not the language starter snippets the bootstrap skill pastes into a new repo. Checked: `grep -rn 'uses:' .github/workflows plugin/skills/start-project/references | grep -vE '@[0-9a-f]{40} # v[0-9]'` prints no lines and exits 1, i.e. every reference carries a 40-hex commit SHA followed by a `# vX.Y.Z` version comment.

- Every version named in a trailing pin comment really exists upstream as a tag and really is the commit that was pinned — the comment is evidence, not decoration. Checked, for each pinned reference: `git ls-remote --tags https://github.com/<owner>/<repo> 'refs/tags/<version from the comment>' 'refs/tags/<version from the comment>^{}'` prints a line that starts with the pinned SHA.

- Pinning moves no action to a new major version, so it changes no behaviour. Checked: `grep -rhoE '[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+(/[A-Za-z0-9_.-]+)*@[0-9a-f]{40} # v[0-9]+' .github/workflows plugin/skills/start-project/references | sed -E 's/@[0-9a-f]{40} # / /' | sort -u` prints only these repository/major pairs: actions/checkout v7, anthropics/claude-code-action v1, github/codeql-action/init v4, github/codeql-action/autobuild v4, github/codeql-action/analyze v4, actions/dependency-review-action v5, actions/setup-go v5, actions/setup-node v4, actions/setup-python v5, Swatinem/rust-cache v2.

- Re-introducing a floating tag is caught mechanically rather than by a reviewer noticing it, and the check needs no git checkout. Checked: copy `.github/` and `plugin/skills/start-project/references/` into an empty directory with no `.git`, edit one pinned `actions/checkout` reference in the copy's CI workflow back to `@v7`, then run the pin-guardrail step from the `guardrails` job of `.github/workflows/ci.yml` with that directory as its argument — it exits 1 and prints the offending `path:line`. Run against the real repository, the same command exits 0.

- Pinning does not freeze the template on stale actions: automated dependency updates still cover GitHub Actions, so a pinned SHA gets bumped and re-pinned. Checked: `grep -n -A3 'package-ecosystem: github-actions' .github/dependabot.yml` prints a block whose `interval:` is `weekly`.

- The pinned workflows are still valid GitHub Actions. Checked: actionlint v1.7.7 (the release the CI guardrails job downloads) run as `actionlint .github/workflows/*.yml` from the repository root exits 0 and prints nothing. The explicit file list matters: with no `.git`, a bare `actionlint` exits 3 with "no project was found".

- The template's own guardrails still pass on the finished tree. Checked: `./.claude/hooks/test-hooks.sh; echo "exit=$?"` prints `failed: 0` and `exit=0`, and every `shellcheck -S warning` command in the `guardrails` job of `.github/workflows/ci.yml` exits 0 when run as written.

- The Rust starter snippet still yields a stable toolchain with clippy and rustfmt, without a third-party toolchain action (`dtolnay/rust-toolchain` publishes branches, not version tags, so it cannot carry a verifiable pin comment). Checked: `grep -n 'rustup toolchain install stable' plugin/skills/start-project/references/rust.md` prints a line naming both `clippy` and `rustfmt`, and `grep -c 'uses: dtolnay' plugin/skills/start-project/references/rust.md` prints `0` (the name may still appear in prose explaining why).
