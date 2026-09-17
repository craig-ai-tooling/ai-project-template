# Stack: Rust

## Commands

| Task | Command |
|---|---|
| Install | `cargo fetch` |
| Build | `cargo build --release` |
| Test (all) | `cargo test` |
| Test (single) | `cargo test test_name` |
| Lint | `cargo clippy -- -D warnings` |
| Format | `cargo fmt` |
| Typecheck | `cargo check` |

## CI setup block

```yaml
      - run: rustup toolchain install stable --profile minimal --component clippy,rustfmt && rustup default stable
      - uses: Swatinem/rust-cache@6323deb102c322ba6fcbdcafc7e3dddab59af2b6 # v2.9.2
```

## Dependabot ecosystem

```yaml
  - package-ecosystem: cargo
    directory: "/"
    schedule: { interval: weekly }
    labels: [dependencies]
```

## CodeQL language

CodeQL has no Rust analyzer. Rely on `clippy -D warnings` in CI and leave
`codeql.yml` on `workflow_dispatch`.

## Notes
- The `format-and-lint` hook runs `rustfmt` on changed `.rs` files.
- The toolchain comes from `rustup`, which GitHub-hosted runners ship, not from a
  third-party action: `dtolnay/rust-toolchain` publishes branches rather than
  version tags, so it cannot be pinned with a verifiable version comment.
