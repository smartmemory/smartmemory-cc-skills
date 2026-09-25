# Install the SmartMemory Claude Code skill bundle

Three slash commands for Claude Code: `/recall`, `/uncompact`, `/remember`.
Markdown-only — a thin presentation layer over SmartMemory's existing
`memory_recall` / `memory_search` / `memory_add` MCP tools. No backend, no
build step.

## Prerequisites

- Claude Code installed.
- The SmartMemory MCP server connected (`pip install smartmemory`, then add it
  to your Claude Code MCP config). The skills detect this and print a one-line
  install hint if it is missing — they never fail silently.

## Paste-into-CC install (single command)

Paste this into Claude Code:

> Please install the SmartMemory skill bundle: copy each `skills/<name>/SKILL.md`
> from https://github.com/smartmemory/smartmemory-cc-skills into
> `~/.claude/skills/<name>/SKILL.md` for name in recall, uncompact, remember.

Or run it directly in a shell (clone, then copy):

```bash
git clone https://github.com/smartmemory/smartmemory-cc-skills /tmp/sm-cc-skills
for s in recall uncompact remember; do
  mkdir -p "$HOME/.claude/skills/$s"
  cp "/tmp/sm-cc-skills/skills/$s/SKILL.md" "$HOME/.claude/skills/$s/SKILL.md"
done
echo "Installed: recall, uncompact, remember"
```

Installing from a local checkout of this bundle instead:

```bash
BUNDLE="$(pwd)"   # run from the bundle root
for s in recall uncompact remember; do
  mkdir -p "$HOME/.claude/skills/$s"
  cp "$BUNDLE/skills/$s/SKILL.md" "$HOME/.claude/skills/$s/SKILL.md"
done
```

## Restart Claude Code

**Restart Claude Code after install** so it re-scans `~/.claude/skills/`.
The three commands then appear in the slash-command picker.

## Verify

```bash
for s in recall uncompact remember; do
  test -f "$HOME/.claude/skills/$s/SKILL.md" && echo "OK  $s" || echo "MISSING  $s"
done
```

Then in Claude Code: type `/remember install test note`, then
`/recall install test` — you should see the note recalled with a
`↳ [... · <id>]` pointer. (Bare `/recall` recalls the session's
compacted-out context rather than an arbitrary note, so pass the query.)

## Uninstall (clean removal)

```bash
rm -rf "$HOME/.claude/skills/recall" \
       "$HOME/.claude/skills/uncompact" \
       "$HOME/.claude/skills/remember"
echo "Removed SmartMemory CC skill bundle"
```

Restart Claude Code; the commands disappear from the picker. Removing the
bundle does not touch any memories already stored in SmartMemory.

## Namespace note

`/recall` is intentionally claimed by this bundle. If you also run another
tool that defines `/recall`, last-installed-wins. The `recall` skill also
responds to `/sm-recall` as an explicit non-colliding alias.
