---
name: uncompact
description: Recover the most recent pre-compact conversation turns that SmartMemory captured via its per-prompt hook (origin tier 4, hook:* captures) and re-inject the raw detail back into the current context. Use when the user types /uncompact, says context was lost after a compaction, or asks to restore the detail of what was just discussed before Claude Code compacted the session.
---

# /uncompact — restore pre-compact turns from SmartMemory

You expose SmartMemory's tier-4 hook captures through the slash-command
picker. SmartMemory's per-prompt hook (DIST-AGENT-HOOKS-1) stores raw turns
with an `origin` beginning `hook:`. After Claude Code compacts a session that
detail is gone from context but still in SmartMemory.

## When this fires

- User types `/uncompact`.
- User says context was lost / "what was I just doing" / asks to restore
  detail after a compaction.

## Preflight: detect the MCP server

If **no SmartMemory MCP tool** (`memory_search` / `memory_recall` /
`memory_add`) is available, do NOT silently return nothing. Print exactly:

> SmartMemory MCP server not detected. Install it with:
> `pip install smartmemory` then add the MCP server to your Claude Code config and restart Claude Code. See https://docs.smartmemory.ai/smartmemory/intro

and stop.

## Tool call

Retrieve the most recent hook-captured turns, scoped to the current session
and filtered to the tier-4 hook origin:

`memory_search(query="", top_k=10, origin_prefix="hook:")`

- Request at least 10 so you can reliably surface the **most recent 5**.
- If `origin_prefix` is not accepted by this tool version, call
  `memory_search(query="", top_k=15)` and then filter client-side to items
  whose `origin` starts with `hook:`. State in the output that a client-side
  filter was applied (do not silently drop the distinction).
- Order results by capture time, newest last (chat order).

## Scope

Scope is auto-resolved from the active SmartMemory session — do not pass auth
or workspace arguments. If the tool returns a scope/auth error, surface it
verbatim and stop (no silent scope fallback).

## Output: injectable context

Emit the recovered turns as a clearly delimited, re-injectable block in
original chronological order so the rest of this conversation can use them:

> **Recovered pre-compact context** (N turns, from SmartMemory hook captures)
>
> --- begin recovered turns ---
> [turn 1 content]
> ↳ [hook · <item_id> · <captured_at>]
>
> [turn 2 content]
> ↳ [hook · <item_id> · <captured_at>]
> ...
> --- end recovered turns ---

Requirements:

- Surface **at least the 5 most recent** hook-captured turns when that many
  exist. If fewer than 5 exist, show all of them and state the actual count.
- Each turn must carry its `↳ [hook · <item_id> · ...]` structural pointer.
- If zero hook captures are found, say so explicitly: "No pre-compact hook
  captures found for this session — the per-prompt hook may not be installed
  (see DIST-AGENT-HOOKS-1)." Never fabricate turns.
- After the block, add one sentence telling the user this detail is now back
  in context and can be referenced directly.
