#!/bin/bash
# Rebuild and publish the site if the vault has changed. Run by launchd.
set -uo pipefail

SITE="/Users/Noah/Desktop/DnD Stuff/Project Planar/site"
VAULT="/Users/Noah/Vaults/Project Planar"
LOG="$SITE/autopublish.log"
STAMP="$SITE/.last-vault-state"

cd "$SITE" || exit 1

# keep the log from growing without limit
if [ -f "$LOG" ] && [ "$(wc -c < "$LOG")" -gt 1000000 ]; then
  tail -n 200 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
fi
exec >> "$LOG" 2>&1
echo "=== $(date '+%Y-%m-%d %H:%M:%S')"

# cheap change check: newest modification time across the vault's notes.
# macOS stat first, GNU stat as fallback.
STATE=$(find "$VAULT" -name '*.md' -exec stat -f '%m' {} + 2>/dev/null | sort -rn | head -1)
if [ -z "$STATE" ]; then
  STATE=$(find "$VAULT" -name '*.md' -exec stat -c '%Y' {} + 2>/dev/null | sort -rn | head -1)
fi
if [ -z "$STATE" ]; then
  echo "could not read vault at $VAULT"
  exit 1
fi
if [ -f "$STAMP" ] && [ "$STATE" = "$(cat "$STAMP")" ]; then
  echo "vault unchanged, nothing to do"
  exit 0
fi

./rebuild.sh "$VAULT" || { echo "build failed"; exit 1; }

if [ -n "$(git status --porcelain)" ]; then
  git add -A
  git commit -q -m "Update site $(date '+%Y-%m-%d %H:%M')"
  if git push -q origin main; then
    echo "pushed"
    echo "$STATE" > "$STAMP"
  else
    echo "push failed"
    exit 1
  fi
else
  echo "built, no changes to publish"
  echo "$STATE" > "$STAMP"
fi
