#!/usr/bin/env bash
# Every repo `start-project` creates is a copy of this template, so a GitHub
# Action named by a tag or branch here is a write path into all of them: whoever
# controls that ref controls their CI. This check refuses any reference that is
# not a full 40-character commit SHA followed by a `# vX.Y.Z` comment naming the
# tag it came from. It reads the workflows and the starter snippets the
# bootstrap skill pastes into new repos, needs no network and no git checkout.
set -uo pipefail

root=${1:-.}

workflows_dir="$root/.github/workflows"
if [ ! -d "$workflows_dir" ]; then
  echo "check-action-pins: no .github/workflows under $root" >&2
  exit 2
fi

shopt -s nullglob
files=("$workflows_dir"/*.yml "$workflows_dir"/*.yaml)
references_dir="$root/plugin/skills/start-project/references"
# plugin/ is deleted from generated projects, so its absence is not a failure.
if [ -d "$references_dir" ]; then
  files+=("$references_dir"/*.md)
fi
shopt -u nullglob

total=0
bad=0

for file in "${files[@]}"; do
  rel=${file#"$root"/}
  lineno=0
  while IFS= read -r line || [ -n "$line" ]; do
    lineno=$((lineno + 1))
    trimmed=${line#"${line%%[![:space:]]*}"}
    [[ $trimmed =~ ^(#[[:space:]]*)?(-[[:space:]]+)?uses:[[:space:]]+(.+)$ ]] || continue
    value=${BASH_REMATCH[3]}
    value=${value%"${value##*[![:space:]]}"}
    total=$((total + 1))
    # A local action (`./path`) carries no upstream ref, so nothing to pin.
    [[ $value == ./* ]] && continue
    [[ $value =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._/-]+@[0-9a-f]{40}\ \#\ v[0-9] ]] && continue
    bad=$((bad + 1))
    echo "$rel:$lineno: $trimmed"
  done < "$file"
done

if [ "$bad" -eq 0 ]; then
  echo "check-action-pins: $total references, all pinned to a commit SHA"
  exit 0
fi

echo "check-action-pins: $bad of $total references are not pinned to a commit SHA -- pin to the full 40-char SHA with a '# vX.Y.Z' comment (docs/security.md)"
exit 1
