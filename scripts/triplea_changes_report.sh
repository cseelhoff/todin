#!/usr/bin/env bash
# Produce a report of all local changes made to the upstream triplea Java
# project (which is checked out under ./triplea but NOT tracked by the
# parent ~/todin workspace).
#
# Output: ./triplea_changes_report/  (created/overwritten)
#
# Scope:
#   - Modified / deleted / renamed files tracked by triplea's own git repo
#     (anything that differs from the upstream HEAD it sits on).
#   - Untracked Java files added under game-app/ (new files we authored).
#   - Modified non-Java build files (gradle, etc.) for completeness.
#
# Excluded:
#   - The Odin port output under triplea/conversion/ (huge, generated).
#   - Other ad-hoc untracked debug dirs (dbg-*, dbg_runner, odin_flat).
#
# Run from the workspace root:  ./scripts/triplea_changes_report.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TRIPLEA="$ROOT/triplea"
OUT="$ROOT/triplea_changes_report"

if [[ ! -d "$TRIPLEA/.git" ]]; then
  echo "error: $TRIPLEA is not a git checkout" >&2
  exit 1
fi

rm -rf "$OUT"
mkdir -p "$OUT"

GIT=(git -C "$TRIPLEA" --no-pager)

UPSTREAM_SHA="$("${GIT[@]}" rev-parse HEAD)"
UPSTREAM_DESC="$("${GIT[@]}" log -1 --format='%h %s (%ad)' --date=short HEAD)"

echo "Generating triplea changes report against HEAD=$UPSTREAM_SHA ..."

# 1) name-status for tracked changes
"${GIT[@]}" diff --name-status HEAD > "$OUT/01_name_status.txt"

# 2) diffstat
"${GIT[@]}" diff --stat=200 HEAD > "$OUT/02_diffstat.txt"

# 3) full unified diff of tracked changes
"${GIT[@]}" diff HEAD > "$OUT/03_tracked.diff"

# 4) untracked new Java files under game-app/ — show full content as a "new file" diff
UNTRACKED_JAVA=()
while IFS= read -r f; do
  [[ -n "$f" ]] && UNTRACKED_JAVA+=("$f")
done < <("${GIT[@]}" ls-files --others --exclude-standard 'game-app/*.java')

: > "$OUT/04_untracked_new_java.diff"
for f in "${UNTRACKED_JAVA[@]}"; do
  # `git diff --no-index` returns 1 when files differ, which is expected; allow it.
  "${GIT[@]}" diff --no-index --no-prefix /dev/null "$f" \
    >> "$OUT/04_untracked_new_java.diff" || true
done

# 5) summary markdown
MOD_JAVA="$(grep -c '\.java$' "$OUT/01_name_status.txt" || true)"
MOD_TOTAL="$(wc -l < "$OUT/01_name_status.txt" | tr -d ' ')"
NEW_JAVA="${#UNTRACKED_JAVA[@]}"

{
  echo "# triplea local-change report"
  echo
  echo "Generated: $(date -Iseconds)"
  echo "Upstream baseline: \`$UPSTREAM_DESC\`"
  echo "Workspace path:    \`$TRIPLEA\`"
  echo
  echo "## Counts"
  echo
  echo "- Tracked files changed vs upstream HEAD: **$MOD_TOTAL** (Java: $MOD_JAVA)"
  echo "- New untracked Java files under \`game-app/\`: **$NEW_JAVA**"
  echo
  echo "## Files"
  echo
  echo "| Section | File |"
  echo "| --- | --- |"
  echo "| Name + status (M/A/D/R) of tracked changes | [01_name_status.txt](01_name_status.txt) |"
  echo "| Per-file line counts                       | [02_diffstat.txt](02_diffstat.txt) |"
  echo "| Full unified diff of tracked changes       | [03_tracked.diff](03_tracked.diff) |"
  echo "| New untracked Java files (game-app/)       | [04_untracked_new_java.diff](04_untracked_new_java.diff) |"
  echo
  echo "## New untracked Java files"
  echo
  if (( NEW_JAVA == 0 )); then
    echo "_(none)_"
  else
    for f in "${UNTRACKED_JAVA[@]}"; do echo "- \`$f\`"; done
  fi
  echo
  echo "## Reproduce"
  echo
  echo '```sh'
  echo "./scripts/triplea_changes_report.sh"
  echo '```'
} > "$OUT/00_summary.md"

echo "Wrote report to: $OUT"
ls -lh "$OUT"
