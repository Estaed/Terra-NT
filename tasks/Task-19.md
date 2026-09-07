# Task-19 — Account and Language screens

> **Execution:** agent `codex` · effort `high` · plan mode no
> *Why:* Two thin settings screens riding patterns the earlier tasks already established.

**Lane**
- OWNS: `terra_nt/lib/features/profile/account/`, `terra_nt/lib/features/profile/language/`, `terra_nt/test/features/profile/account/`, `terra_nt/test/features/profile/language/`
- MUST NOT TOUCH: `terra_nt/lib/features/profile/` outside those two subtrees (Task-18 owns the Profile screen itself), `terra_nt/lib/app/` (Task-06), `terra_nt/pubspec.yaml` (append-only, Task-00)
- GATE: `cd terra_nt && flutter analyze && flutter test test/features/profile/`
- DEPENDS ON: Task-06, Task-18

## Objective

Build the two screens that Decision D9 added so the Profile rows honour their chevrons.
**Neither exists in the prototype** — they are the only screens in the project with no
design source. The ten captures in `docs/screenshots/` do not cover them either:
`10-profile.png` shows the two *rows* and their chevrons, never their destinations.

## Execution Guide

**Files:** `terra_nt/lib/features/profile/account/` and `.../language/`.

**Because there is no design source, invent no new visual language.** Compose Task-02's
existing widgets — `SettingsRow`, `AppIcon`, tokens from Task-01 — and reuse Stop detail's
back-button pattern. If a screen here needs a widget that does not already exist, that is a
signal to simplify the screen, not to design a new component.

Both are minimal and **read-only** (D9). This is scope, not laziness: editable account
details and real language switching are in `docs/PRD.md` §8 out of scope, and i18n would be
a cross-cutting change to every string in the app.

### Account

Back button, then read-only rows: avatar circle, display name "NT Explorer", and the
session email (same `explorer@example.com` fallback as Profile). **No editing, no text
fields, no save button.**

### Language

Back button, then a single-select list with **English as the only entry, checked**. Tapping
it is a no-op — there is nothing to switch to. Do not add a second language, and do not add
any localisation machinery.

Both push onto the **Profile** tab's stack and hide the bottom nav (Task-06 already routes
them this way).

## Acceptance Criteria (DoD)

- [ ] Widget test: Account renders "NT Explorer" and the session email, with the `explorer@example.com` fallback when empty.
- [ ] Widget test: Account contains **no** `TextField`, `TextFormField` or save button — `find.byType(TextField)` finds nothing.
- [ ] Widget test: Language lists exactly one entry, "English", rendered as checked.
- [ ] Widget test: tapping the English row changes no state and pushes no route.
- [ ] Widget test: both screens' back buttons return to Profile.
- [ ] Widget test: neither screen renders the bottom nav.
- [ ] Both screens are built from existing shared widgets — `ls lib/features/profile/account lib/features/profile/language` contains no new reusable component definitions.
- [ ] `grep -rn "flutter_localizations\|AppLocalizations\|intl" lib/` returns nothing.
- [ ] `grep -rnE "0x[0-9a-fA-F]{8}" lib/features/profile/` returns nothing.
- [ ] No layout exception at 360px width on either screen.
- [ ] `cd terra_nt && flutter analyze` exits 0 with no warnings.
- [ ] `cd terra_nt && flutter test test/features/profile/` exits 0.
