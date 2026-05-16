---
name: remember
description: Save a note, fact, decision, or piece of context to SmartMemory so it can be recalled later. Use when the user types /remember <text>, says "remember that ...", "make a note that ...", "save this", or wants something persisted across sessions. Stores via memory_add with origin cli:add and confirms the item ID and origin tier.
---

# /remember — save to SmartMemory

You expose SmartMemory's `memory_add` MCP tool through the slash-command
picker. This is both a storage primitive and a teaching moment — make the
confirmation human-readable so users learn what SmartMemory captured.

## When this fires

- User types `/remember <text>`.
- User says "remember that ...", "make a note ...", "save this for later".
- `/remember` with no text: summarize the salient point of the current
  context in one or two sentences and store that summary (tell the user you
  did this and show the summary you stored).

## Preflight: detect the MCP server

If **no SmartMemory MCP tool** is available, do NOT silently drop the note.
Print exactly:

> SmartMemory MCP server not detected. Your note was NOT saved. Install it with:
> `pip install smartmemory` then add the MCP server to your Claude Code config and restart Claude Code. See https://docs.smartmemory.ai/smartmemory/intro

and stop.

## Tool call

`memory_add(content="<text>", origin="cli:add")`

- Always pass `origin="cli:add"` so the item lands in origin tier 1 (user
  content — recallable and searchable).
- Scope is auto-resolved from the active SmartMemory session (local-mode or
  cloud workspace). Do not pass auth/workspace arguments. If the tool returns
  a scope/auth error, surface it verbatim and tell the user the note was NOT
  saved (no silent success).

## Output: confirmation

After a successful call, confirm in human-readable form:

> Saved to SmartMemory.
> - **id:** `<item_id>`
> - **origin:** `cli:add` (tier 1 — user content, recallable & searchable)
> - **content:** "<the text that was stored>"
>
> You can bring this back later with `/recall`.

If the tool call fails for any reason, state clearly that the note was NOT
saved and show the error — never report success without a returned item id.
