#!/bin/bash
# Rebuild and publish both sites if the vault has changed. Run by launchd.
set -uo pipefail

SITE="/Users/Noah/Sites/project-planar"
VAULT="/Users/Noah/Vaults/Project Planar"
PLAYERS="/Users/Noah/Sites/project-planar-players"
LOG="$SITE/autopublish.log"
STAMP="$SITE/.last-vault-state"

cd "$SITE" || exit 1

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

# DM site: push the source, the Action builds and deploys it
if [ -n "$(git status --porcelain)" ]; then
  git add -A
  git commit -q -m "Update site $(date '+%Y-%m-%d %H:%M')"
  if git push -q origin main; then
    echo "dm site pushed"
  else
    echo "dm site push failed"
    exit 1
  fi
else
  echo "dm site built, no changes to publish"
fi

# Player site: push the built files to their own repo
if [ -d "$PLAYERS/.git" ]; then
  rsync -a --delete --exclude '.git' "$SITE/public-players/" "$PLAYERS/"
  cd "$PLAYERS"
  if [ -n "$(git status --porcelain)" ]; then
    git add -A
    git commit -q -m "Update player site $(date '+%Y-%m-%d %H:%M')"
    if git push -q origin main; then
      echo "player site pushed"
    else
      echo "player site push failed"
    fi
  else
    echo "player site built, no changes to publish"
  fi
  cd "$SITE"
else
  echo "player site repo not found at $PLAYERS, skipping"
fi

echo "$STATE" > "$STAMP"
