#!/bin/bash
# Rebuild both sites from the vault.
#   ./rebuild.sh                        both sites
#   ./rebuild.sh "/path/to/vault"       both, from a vault elsewhere
#   ./rebuild.sh "" --serve             DM site, served locally
#
# Quartz reads one config and looks for content only in its own "content"
# directory, so each site is built in turn with both swapped into place.
#
#   quartz.config.dm.yaml       the full wiki: explorer, graph, search, tags
#   quartz.config.players.yaml  the walkthrough: no browsing furniture
#
# The DM build goes last, which leaves the config and content/ holding the DM
# copy for the repository.
set -e
VAULT="${1:-$HOME/Vaults/Project Planar}"
cd "$(dirname "$0")"
CONFIG=quartz.config.default.yaml

# Player site: only notes marked "audience: player"
cp quartz.config.players.yaml "$CONFIG"
rm -rf content
python3 sync.py "$VAULT" content player
npx quartz build -o public-players
touch public-players/.nojekyll
# Quartz writes a CNAME from the base URL. On a branch-served repo that reads
# as a custom domain claim and breaks the site, so it goes.
rm -f public-players/CNAME

# DM site: everything in the vault
cp quartz.config.dm.yaml "$CONFIG"
rm -rf content
python3 sync.py "$VAULT" content
npx quartz build "${@:2}"
