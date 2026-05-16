#!/usr/bin/env bash
# Smoke test for the SmartMemory Claude Code skill bundle.
#
#   ./smoke-test.sh          structure + frontmatter validity only
#   ./smoke-test.sh --full   also install -> verify -> uninstall in an
#                            isolated temp dir (never touches ~/.claude/skills)
#
# Exit non-zero on any failure. Never reports success without checking.
set -u

BUNDLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS=(recall uncompact remember)
FAIL=0

fail() { echo "FAIL: $*"; FAIL=1; }
ok()   { echo "OK:   $*"; }

echo "== Structure =="
for f in README.md INSTALL.md; do
  if [ -f "$BUNDLE_DIR/$f" ]; then ok "$f present"; else fail "$f missing"; fi
done

# Hard rule: no license text or license file anywhere in the bundle.
if find "$BUNDLE_DIR" -iname 'LICENSE*' -print -quit | grep -q .; then
  fail "a LICENSE file exists (bundle must contain no license file)"
else
  ok "no LICENSE file"
fi
if grep -ril -e 'MIT License' -e 'licensed under' "$BUNDLE_DIR" \
     --include='*.md' >/dev/null 2>&1; then
  fail "license text found in bundle (must contain none)"
else
  ok "no license text"
fi

echo "== Skill frontmatter =="
for s in "${SKILLS[@]}"; do
  SK="$BUNDLE_DIR/skills/$s/SKILL.md"
  SFAIL=0
  if [ ! -f "$SK" ]; then fail "skills/$s/SKILL.md missing"; continue; fi

  # Frontmatter must be a --- delimited block at the very top of the file.
  if [ "$(head -n 1 "$SK")" != "---" ]; then
    fail "$s: file does not start with '---' frontmatter fence"; continue
  fi
  # Extract the block between the first two '---' fences.
  FM="$(awk 'NR==1&&$0=="---"{f=1;next} f&&$0=="---"{exit} f' "$SK")"
  if [ -z "$FM" ]; then fail "$s: empty/unterminated frontmatter"; continue; fi

  NAME="$(printf '%s\n' "$FM" | sed -n 's/^name:[[:space:]]*//p' | head -n1)"
  DESC="$(printf '%s\n' "$FM" | sed -n 's/^description:[[:space:]]*//p' | head -n1)"

  [ -n "$NAME" ] || { fail "$s: frontmatter missing 'name'"; SFAIL=1; }
  [ -n "$DESC" ] || { fail "$s: frontmatter missing 'description'"; SFAIL=1; }
  if [ "$NAME" != "$s" ]; then
    fail "$s: frontmatter name '$NAME' != directory '$s'"; SFAIL=1
  fi
  # Body must reference the SmartMemory MCP tool the skill is meant to call.
  if ! grep -q -e 'memory_recall' -e 'memory_search' -e 'memory_add' "$SK"; then
    fail "$s: SKILL.md does not reference any SmartMemory MCP tool"; SFAIL=1
  fi
  # Must not silently degrade when MCP is absent.
  if ! grep -qi 'SmartMemory MCP server not detected' "$SK"; then
    fail "$s: missing explicit no-MCP fallback message"; SFAIL=1
  fi
  [ "$SFAIL" -eq 0 ] && ok "$s: frontmatter valid (name=$NAME)"
done

if [ "${1:-}" = "--full" ]; then
  echo "== Install -> verify -> uninstall (isolated; does not touch ~/.claude) =="
  # Use an isolated temp skills dir so a developer's real, possibly modified
  # ~/.claude/skills/{recall,uncompact,remember} are never overwritten or
  # deleted. This mirrors the documented install steps exactly, only the
  # destination root differs.
  TMPROOT="$(mktemp -d "${TMPDIR:-/tmp}/sm-cc-skills-smoke.XXXXXX")"
  if [ -z "${TMPROOT:-}" ] || [ ! -d "$TMPROOT" ]; then
    fail "mktemp failed; cannot run isolated --full test"
    echo "SMOKE TEST FAILED"; exit 1
  fi
  trap 'rm -rf "$TMPROOT"' EXIT
  DEST="$TMPROOT/skills"
  for s in "${SKILLS[@]}"; do
    mkdir -p "$DEST/$s"
    cp "$BUNDLE_DIR/skills/$s/SKILL.md" "$DEST/$s/SKILL.md" \
      && ok "installed $s" || fail "could not install $s"
  done
  for s in "${SKILLS[@]}"; do
    [ -f "$DEST/$s/SKILL.md" ] && ok "verified $s installed" \
      || fail "$s not found after install"
  done
  for s in "${SKILLS[@]}"; do
    rm -rf "${DEST:?}/$s"
    [ ! -e "$DEST/$s" ] && ok "uninstalled $s" || fail "$s not removed"
  done
fi

echo
if [ "$FAIL" -eq 0 ]; then
  echo "SMOKE TEST PASSED"
  exit 0
else
  echo "SMOKE TEST FAILED"
  exit 1
fi
