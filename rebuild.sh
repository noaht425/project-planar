#!/bin/bash
# Rebuild the Project Planar site from the vault.
set -e
VAULT="${1:-$HOME/Vaults/Project Planar}"
cd "$(dirname "$0")"
rm -rf content
python3 sync.py "$VAULT" content
npx quartz build "${@:2}"
