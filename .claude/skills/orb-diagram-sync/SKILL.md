---
name: orb-diagram-sync
description: "Renders docs/architecture/*.d2 diagrams in dark theme via the engineering-toolkit design-d2 skill and pushes the SVG into the ios-orb.wiki.git repo (flat layout). Use when the user says 'update the diagram', 'sync the wiki diagram', 'render the d2', or after editing docs/architecture/orb_pipeline.d2."
allowed-tools: Read Grep Glob Bash(d2:*) Bash(git:*) Bash(cp:*)
---

# orb-diagram-sync

This repo's diagrams are **d2 only, dark theme, never Mermaid/ASCII, never `--theme 0`**. Source of truth is `docs/architecture/*.d2` in the main repo; the wiki gets a copied *rendered* SVG, not the source.

## Repo layout

```
docs/architecture/
    orb_pipeline.d2     # imports ...@kjm-classes
    kjm-classes.d2      # shared style classes
    kjm-vars.d2         # shared vars
    icons/*.svg         # local icon set referenced by orb_pipeline.d2
    orb_pipeline.svg    # last rendered output — committed alongside the .d2
```

## Render (main repo)

Use the engineering-toolkit `design-d2` skill's renderer — do not hand-invoke `d2` with your own flags; the script bakes in the lint pass and the verified dark-theme flags (`--layout elk --theme 200 --dark-theme 200 --scale 1 --pad 24`, bundled icons/fonts):

```bash
~/.claude/plugins/marketplaces/engineering-toolkit/plugins/etk-design-diagrams/skills/design-d2/scripts/d2-render.sh \
    docs/architecture/orb_pipeline.d2 docs/architecture/orb_pipeline.svg
```

It exits non-zero on lint failure (reserved `vars` keys, remote icon URLs, `|md` labels on containers, nested `near:`, icons on a grid root) or on verification failure (an unbundled/remote image reference survived). Fix and re-render rather than bypassing.

Commit the `.d2` and the `.svg` together in the main repo:

```bash
git add docs/architecture/orb_pipeline.d2 docs/architecture/orb_pipeline.svg
git commit -m "docs(diagram): <what changed> [IOS-ORB-V3]"
```

## Sync to the wiki

The wiki repo (`kevnm67/ios-orb.wiki.git`) is a **separate git remote** that does not exist until its first push, and — per this being a public repo — `raw.githubusercontent.com` URLs *would* work here, but this repo still defaults to committing the SVG straight into the wiki repo for consistency with the private-repo-safe pattern:

```bash
git clone git@github.com:kevnm67/ios-orb.wiki.git /tmp/ios-orb-wiki
cp docs/architecture/orb_pipeline.svg /tmp/ios-orb-wiki/orb_pipeline.svg
git -C /tmp/ios-orb-wiki add orb_pipeline.svg
git -C /tmp/ios-orb-wiki commit -m "docs: sync orb_pipeline diagram"
git -C /tmp/ios-orb-wiki push
```

**Flat layout.** Wiki repos technically support subdirectories but the tooling around them is brittle — always copy to the wiki repo root, never into a subfolder.

Reference the image from a wiki page with a bare relative filename:

```markdown
![Orb pipeline](orb_pipeline.svg)
```

If a `wiki-sync` GitHub Action is wired up for this repo in the future, note that it (by default) only syncs `wiki/*.md` from main → wiki repo — image binaries still need this manual (or workflow-extended) push unless that workflow is explicitly configured to also sync `wiki/*.svg`.

## Verification

After pushing, open the wiki page in a browser and confirm the image actually renders — don't assume a successful `git push` means the embed works; a wrong relative path or a page in a subdirectory silently 404s the image (broken-image icon, not an error).

## Anti-patterns

| Don't | Why |
| --- | --- |
| `d2 --theme 0` or any light render | This repo standardizes on dark diagrams everywhere |
| Mermaid or ASCII diagrams | d2 only, per repo convention |
| Commit the SVG only to `docs/architecture/` and assume the wiki updates itself | Wiki is a separate repo; nothing syncs it automatically unless a wiki-sync workflow explicitly copies SVGs too |
| Nest the SVG in a wiki subdirectory | Flat layout is the reliable pattern — subdirectory tooling in wikis is brittle |
| Hand-invoke `d2` instead of `d2-render.sh` | Skips the lint pass and the verified bundling/dark-theme flags |
