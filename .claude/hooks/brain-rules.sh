#!/bin/bash
# Injects the TarikOS house rules (Kurallar.md) into every session in this project.
#
# Why this exists as a hook and not as a line in CLAUDE.md: CLAUDE.md already says
# "you may read the brain". That is a rule -- something the agent has to remember to
# do, and it did not. The vault injects Kurallar.md through its own SessionStart hook,
# so a session in the vault always has the rules and a session in a project never did.
# This closes that gap structurally: the rules arrive whether anyone remembers or not.
#
# The rules are NOT copied into this repo on purpose. One copy drifts from the other
# and the stale one wins silently. There is exactly one source of truth.
#
# Brain location: $TARIKOS_HOME if set, otherwise the default below. The path used to
# be C:\TarikOS in this template and went dead when the vault moved to D: -- every
# project cloned from here inherited a pointer to a directory that no longer existed
# and would have concluded "there is no brain". Hence the loud failure below.

# Windows console code page is OEM (437/857 here). python3 treats it as the default
# for stdin/stdout and turns UTF-8 bytes into latin-1 characters one by one:
# "Memory" -> mojibake. The corruption is silent and irreversible. Measured: without
# these two lines this very hook emitted mojibake on its first run.
PYTHONUTF8=1
PYTHONIOENCODING=utf-8
export PYTHONUTF8 PYTHONIOENCODING

BRAIN=${TARIKOS_HOME:-/d/TarikOS}
[ -d "$BRAIN" ] || BRAIN="D:/TarikOS"

emit() {
  if command -v python3 >/dev/null 2>&1; then
    ESCAPED=$(printf '%s' "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))' 2>/dev/null || :)
    [ -n "$ESCAPED" ] && printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":%s}}\n' "$ESCAPED" && return 0
  fi
  # No python3: say so instead of exiting 0 with nothing. A silent skip here would look
  # exactly like a working hook.
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"Brain warning: python3 is unavailable, so the TarikOS house rules could not be injected."}}\n'
}

RULES_FILE="$BRAIN/850-Companion 🔮/Kurallar.md"
if [ ! -f "$RULES_FILE" ]; then
  emit "[Brain warning] Could not read the TarikOS house rules — expected path: $RULES_FILE
The brain may have moved. Find the correct path, set the TARIKOS_HOME environment variable, or
fix the default in .claude/hooks/brain-rules.sh in this project. This session is running
WITHOUT the TarikOS house rules."
  exit 0
fi

# Same contract as the vault's own hook: first 60 lines, then a hard character cap.
# The cap is 5000, not 4000. Measured 2026-09-04: the first 60 lines of Kurallar.md are
# 4738 characters, so a 4000 cap silently dropped 738 characters of BINDING rules in
# every session -- in the vault and here. Keep this number equal to BEYIN_CAP_RULES in
# the vault's .claude/hooks/session-start.sh; if they drift, one side quietly serves
# fewer rules than the other.
CAP=5000
RULES=$(sed -n '1,60p' "$RULES_FILE" 2>/dev/null)
NOTE=""
if [ "${#RULES}" -gt "$CAP" ]; then
  RULES=${RULES:0:$((CAP - 100))}
  NOTE="
[note: rules truncated at ${CAP} characters — see $RULES_FILE for the complete file]"
fi

emit "[Memory: TarikOS house rules] These rules also apply in this project directory. Brain: $BRAIN
$RULES$NOTE

This project's own CLAUDE.md Part 1 / Part 2 rules are also binding; if they conflict,
the project rule takes precedence in this directory."
exit 0
