#!/usr/bin/env python3
"""Copy the Project Planar vault into a Quartz content folder.

Keeps the prose and a short whitelist of frontmatter. Drops the settlement
generator data, which is ~169 MB of YAML across six notes, and skips notes
that are nothing but that data.
"""
import os, re, sys, shutil

INDEX = """---
title: Project Planar
---

A sourcebook for the planes of Agra.

## The Planes

[[The Cosmic Rings]] explains how the eight nest, one inside the next.

[[Nullis]] · [[Temporalis]] · [[Ventis]] · [[Tarkis]] · [[Iudis]] · [[Iris]] · [[Arcanis]] · [[Arenis]]

## The Realms Within Them

The five elemental realms of Tarkis, held by the [[Dragons]].

The seven fey domains of Iris, held by the [[Archfey]].

The twelve afterlives of Iudis, held by the halves of [[The Judgements]].

## The Languages

[[Old Iudimian]] · [[Celestial]] · [[Infernal]] · [[Iudimian]] · [[Dzoa]] · [[High Fae]] · [[Sylvan]] · [[Low Fae]] · [[Theis]] · [[Ancient Draconic]] · [[Genoan]] · [[Torren (Old Common)]]

## Elsewhere

[[Ascension Process]] · [[Sourcebook Conventions]]
"""

KEEP = {"title","type","tags","summary","locationType","date","cr","ac","hp",
        "structuredDate","aliases","draft","class","subclass"}
SKIP_DIRS = {".git", ".obsidian", "Language Build Scripts", ".attachments"}

def frontmatter_split(text):
    m = re.match(r"---\n(.*?)\n---\n?", text, re.S)
    if not m:
        return "", text
    return m.group(1), text[m.end():]

def filter_frontmatter(fm):
    """Keep whitelisted top-level keys, dropping their nested blocks if huge."""
    out, keep_block = [], False
    for line in fm.split("\n"):
        if re.match(r"^[A-Za-z_][\w]*:", line):
            key = line.split(":", 1)[0]
            keep_block = key in KEEP
        if keep_block:
            out.append(line)
    return "\n".join(out)

def main(src, dst):
    copied = skipped = 0
    for root, dirs, files in os.walk(src):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS and not d.startswith(".")]
        for f in files:
            if not f.endswith(".md"):
                continue
            sp = os.path.join(root, f)
            rel = os.path.relpath(sp, src)
            text = open(sp, encoding="utf-8", errors="ignore").read()
            fm, body = frontmatter_split(text)
            if len(body.strip()) < 5 and len(fm) > 50_000:
                skipped += 1
                continue
            fm = filter_frontmatter(fm)
            dp = os.path.join(dst, rel)
            os.makedirs(os.path.dirname(dp), exist_ok=True)
            open(dp, "w", encoding="utf-8").write(f"---\n{fm}\n---\n\n{body.lstrip()}")
            copied += 1
    return copied, skipped

if __name__ == "__main__":
    src, dst = sys.argv[1], sys.argv[2]
    if os.path.exists(dst):
        shutil.rmtree(dst)
    c, s = main(src, dst)
    idx = os.path.join(dst, "index.md")
    if not os.path.exists(idx):
        open(idx, "w", encoding="utf-8").write(INDEX)
    total = sum(os.path.getsize(os.path.join(r, f))
                for r, _, fs in os.walk(dst) for f in fs)
    print(f"copied {c} notes, skipped {s} data-only notes, {total/1e6:.2f} MB")
