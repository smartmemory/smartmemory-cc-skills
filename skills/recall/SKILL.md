---
name: recall
description: Recall what you've discussed before from SmartMemory, rendered as an adaptive view (turns/items in original chat order with pointers back to source memory IDs) rather than a ranked hit list. Use when the user types /recall, /sm-recall, asks "what did we decide/discuss about X", or needs context that was compacted out of the current session. With an argument, searches recent context for that query; with no argument, recalls everything from the current session that was compacted away.
---

# /recall — adaptive recall from SmartMemory

You expose SmartMemory's `memory_recall` MCP tool through the slash-command picker.

## When this fires

- User types `/recall [query]` or the alias `/sm-recall [query]`.
- User asks "what did we decide about X", "remind me what we discussed", or references something that was compacted out of context.

## Preflight: detect the MCP server

Check whether a SmartMemory MCP tool is available (look for tools named
`memory_recall`, `memory_search`, or `memory_add`).

If **no SmartMemory MCP tool is present**, do NOT silently produce nothing.
Print exactly this and stop:

> SmartMemory MCP server not detected. Install it with:
> `pip install smartmemory` then add the MCP server to your Claude Code config and restart Claude Code. See https://docs.smartmemory.ai/smartmemory/intro

## Scope detection (local vs cloud)

`memory_recall` auto-resolves scope from the active SmartMemory session
(local-mode for free/self-hosted, workspace-scoped for cloud). Do not pass
auth or workspace arguments — call the tool plainly and let it resolve scope.
If the tool returns an auth/scope error, surface that error verbatim to the
user (do not retry silently with a different scope).

## Tool call

- With an argument: `memory_recall(query="<the user's query>")`
- With no argument: `memory_recall(query="")` — recall the current session's
  compacted-out context.

If `memory_recall` is unavailable but `memory_search` is:

- **With an argument:** fall back to `memory_search(query="<the user's query>", top_k=8)`
  and state in your output: "(memory_recall unavailable — showing
  memory_search results instead; ordering is by relevance, not chat order.)"
- **With no argument:** there is no query and `memory_search` cannot
  reconstruct session-scoped compacted-out context, so do NOT silently
  substitute it. Print: "Bare `/recall` (session compacted-context recall)
  requires the `memory_recall` MCP tool, which is not available. Re-run as
  `/recall <something to search for>` to use search instead, or update your
  SmartMemory MCP server." Then stop.

## Output: adaptive view (not a ranked list)

Render results as a reconstructed conversation/notes view in **original
chronological order**, not as a scored hit list. For each recalled item:

- Lead with the content as prose, in the order it originally occurred.
- Append a structural pointer in the form `↳ [<memory_type> · <item_id>]` so
  the user can trace any line back to its source memory.
- Group consecutive items from the same session/turn together.

Example shape:

> **Earlier in this work** (recalled from SmartMemory)
>
> You decided to use FalkorDB for the graph layer because vector + graph in
> one engine avoided a second datastore.
> ↳ [decision · 7f3a-...-91c]
>
> You later noted the embedding model was switched to text-embedding-3-small
> for cost.
> ↳ [semantic · a18b-...-04e]

End with a one-line summary of how many items were recalled and the source
(session vs cross-context). If zero items are returned, say so explicitly
("No prior context found for that query") — never fabricate recalled content.
