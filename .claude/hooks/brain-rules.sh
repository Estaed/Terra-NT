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
# "Hafiza" -> "HafÄ±za". The corruption is silent and irreversible. Measured: without
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
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"Beyin uyarisi: python3 yok, TarikOS kurallari enjekte edilemedi."}}\n'
}

RULES_FILE="$BRAIN/850-Companion 🔮/Kurallar.md"
if [ ! -f "$RULES_FILE" ]; then
  emit "[Beyin uyarısı] TarikOS kuralları okunamadı — beklenen yol: $RULES_FILE
Beyin taşınmış olabilir. Doğru yolu bul, TARIKOS_HOME ortam değişkenini ayarla ya da
bu projedeki .claude/hooks/brain-rules.sh içindeki varsayılanı düzelt. Bu oturum
TarikOS ev kuralları OLMADAN çalışıyor."
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
[not: kurallar ${CAP} karakterde kırpıldı — tamamı için $RULES_FILE]"
fi

emit "[Hafıza: TarikOS Kuralları] Bu proje dizininde de geçerlidir. Beyin: $BRAIN
$RULES$NOTE

Bu projenin kendi CLAUDE.md Part 1 / Part 2 kuralları da bağlayıcıdır ve çakışma
hâlinde proje kuralı bu dizinde önceliklidir."
exit 0
