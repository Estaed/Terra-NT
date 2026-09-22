"""Goal gate for the 2026-09-23 otopilot goal run.

Prints one number: the count of open items. 0 means the goal is met. Run from the repo
root with PYTHONUTF8=1. Frozen for the run: no lane may edit this file, and the
orchestrator does not edit it between waves. Each check is a grep or a file-exists test
so it cannot be satisfied by relaxing a test; coverage floors are read from
terra_nt/coverage/lcov.info, which `flutter test --coverage` regenerates.
"""
from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
APP = ROOT / "terra_nt"


def grep(pattern: str, *paths: str, flags: int = 0) -> list[str]:
    hits = []
    for p in paths:
        base = APP / p
        files = [base] if base.is_file() else base.rglob("*.dart")
        for f in files:
            try:
                text = f.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                continue
            if re.search(pattern, text, flags):
                hits.append(str(f.relative_to(ROOT)))
    return hits


# Blueprint (Stack, 2026-09-22): the Firebase wrappers are thin and untested by unit on
# purpose, so they are excluded from every floor rather than tested through a double.
EXCLUDED = ("firebase_auth_repository.dart", "firestore_saved_routes.dart", "firebase_options.dart")


def coverage(prefixes: tuple[str, ...]) -> float:
    lcov = APP / "coverage" / "lcov.info"
    if not lcov.exists():
        return 0.0
    hit = found = 0
    for rec in lcov.read_text(encoding="utf-8").split("end_of_record"):
        m = re.search(r"SF:(.*)", rec)
        if not m:
            continue
        f = m.group(1).replace("\\", "/")
        if not any(f"lib/{p}" in f for p in prefixes) or f.endswith(EXCLUDED):
            continue
        hit += int(re.search(r"LH:(\d+)", rec).group(1))
        found += int(re.search(r"LF:(\d+)", rec).group(1))
    return 100.0 * hit / found if found else 0.0


checks: list[tuple[str, bool]] = []

# 1. Try again on Loading re-sends with the same requestId — tested with MockClient.
checks.append((
    "loading retry test with MockClient asserting one requestId",
    bool(grep(r"MockClient", "test/features/loading")) and bool(grep(r"requestId", "test/features/loading")),
))
# 2. Account's verification read no longer swallows everything.
checks.append((
    "account_screen.dart has no catch-all around isEmailVerified",
    not grep(r"catch \(_\)\s*\{\s*return;", "lib/features/profile/account/account_screen.dart"),
))
# 3. Tests that reach Account override the auth seam instead.
checks.append((
    "tab_shell_test and itinerary_profile_test override authRepositoryProvider",
    bool(grep(r"authRepositoryProvider\.overrideWith", "test/app/tab_shell_test.dart"))
    and bool(grep(r"authRepositoryProvider\.overrideWith", "test/integration/itinerary_profile_test.dart")),
))
# 4. The seeded path keeps V1's 7000 ms: success waits for the minimum display time,
#    and the integration test asserts nothing completes at 3000 ms again.
checks.append((
    "Loading success waits AppMotion.loadingCompletionDelay; integration test expects 0 at 3000 ms",
    bool(grep(r"loadingCompletionDelay", "lib/features/loading"))
    and bool(grep(r"_backgroundAndResume\(tester\);\s*expect\(completions, 0\);", "test/integration/auth_onboarding_test.dart")),
))
# 5. Stop detail shows the empty-plan line and Result hides Cancel after success (already
#    shipped; regression guard by test key presence).
checks.append((
    "detailed-plan-empty keys asserted in tests",
    bool(grep(r"detailed-plan-empty", "test/features/itinerary")),
))
# 6. Coverage floors — tier 1 and the notifiers are the logic; widgets are eyeballed.
checks.append(("coverage lib/core/util >= 95%", coverage(("core/util",)) >= 95.0))
checks.append(("coverage lib/data (Firebase wrappers excluded) >= 97%", coverage(("data/",)) >= 97.0))
checks.append(("coverage lib/features >= 97%", coverage(("features/",)) >= 97.0))
# 7. The analyzer stays clean with the stricter lints the run may enable.
try:
    out = subprocess.run(
        ["flutter", "analyze", "--no-pub"], cwd=APP, capture_output=True, text=True, shell=True
    ).stdout
    checks.append(("flutter analyze clean", "No issues found" in out))
except OSError:
    checks.append(("flutter analyze clean", False))

open_items = [name for name, ok in checks if not ok]
for name, ok in checks:
    print(("ok   " if ok else "OPEN ") + name, file=sys.stderr)
print(len(open_items))
