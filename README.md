# smartmemory-cc-skills

SmartMemory for Claude Code, as slash commands.

| Command | What it does |
|---|---|
| `/recall [query]` | Adaptive recall from SmartMemory — turns/items in original chat order with pointers back to source memory IDs. No-arg recalls the current session's compacted-out context. Alias: `/sm-recall`. |
| `/uncompact` | Recovers the most recent pre-compact turns from SmartMemory's tier-4 hook captures and re-injects the raw detail into context. |
| `/remember <text>` | Saves a note/decision/fact to SmartMemory (`origin=cli:add`, tier 1) and confirms the item ID. |

Markdown-only. Each skill is a `SKILL.md` that instructs Claude Code to call
SmartMemory's existing MCP tools (`memory_recall`, `memory_search`,
`memory_add`). No backend, no build, no bundled package — the skills detect
the MCP server and print a one-line install hint if it is absent.

## Install

See [INSTALL.md](INSTALL.md). One paste-into-Claude-Code command, restart,
done in under a minute.

## Smoke test

```bash
./smoke-test.sh
```

Verifies bundle structure and that every `SKILL.md` has valid Claude Code
skill frontmatter (`name`, `description`). With `--full` it also performs an
install → verify → uninstall round-trip in an isolated temp directory (it
never touches your real `~/.claude/skills/`).

## Requires

SmartMemory MCP server — `pip install smartmemory`. Docs:
https://docs.smartmemory.ai/smartmemory/intro

Feature: DIST-CC-SKILLS-1.
