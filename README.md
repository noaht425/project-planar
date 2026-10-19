# Project Planar site

A [Quartz](https://quartz.jzhao.xyz) site built from the Project Planar vault.

The vault stays the source of truth. Nothing here is edited by hand except the
config. `sync.py` copies the vault into `content/` on every build, keeping the
prose and dropping the settlement generator data, which is about 169 MB of YAML
across six notes and will break the build if it gets through.

## First time

    npm install

## Rebuild

    ./rebuild.sh

Or against a vault somewhere else:

    ./rebuild.sh "/path/to/vault"

## Preview locally

    ./rebuild.sh "$HOME/Vaults/Project Planar" --serve

Then open http://localhost:8080.

## What sync.py does

- Copies every `.md` file from the vault into `content/`.
- Keeps only these frontmatter keys: title, type, tags, summary, locationType,
  date, cr, ac, hp, structuredDate, aliases, draft, class, subclass.
- Skips notes whose body is empty and whose frontmatter is over 50 KB. Those are
  pure generator data, such as `Caragna Data.md` at 43.7 MB.
- Writes a front page at `content/index.md` if the vault has no `index.md`.

## Config

`quartz.config.default.yaml`. The page title and base URL are set there.

## Deploying

The site publishes to GitHub Pages from `.github/workflows/deploy.yml` on every
push to `main`. The workflow runs `npx quartz build` against the committed
`content/` folder, so run `./rebuild.sh` and commit before pushing, or the live
site will be built from stale notes.

The workflow also writes a `robots.txt` that asks search engines to stay away.
The repository itself is public and browsable regardless, so anything in the
vault that should stay unknown should not be pushed here.

### First deploy

    ./rebuild.sh "$HOME/Vaults/Project Planar"
    rm -rf .git && git init -b main
    git add -A && git commit -m "Project Planar site"
    gh repo create project-planar --public --source=. --push

Then in the repository settings, under Pages, set the source to GitHub Actions.

Quartz's own history is dropped by the `git init` above, which keeps the repo
small and avoids pushing a shallow clone. To pull Quartz updates later:

    git remote add upstream https://github.com/jackyzha0/quartz.git
    git fetch upstream
    git merge upstream/v5 --allow-unrelated-histories
