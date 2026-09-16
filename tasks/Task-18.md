# Task-18 — Profile and inline delete-account confirm

Status: DONE

> **Execution:** agent `codex` · effort `high`
> *Why:* Profile plus an inline delete confirm; V6 fixes exactly what deleting clears.

**Lane**
- OWNS: `terra_nt/lib/features/profile/`, `terra_nt/test/features/profile/`
- MUST NOT TOUCH: `terra_nt/lib/features/profile/account/` and `terra_nt/lib/features/profile/language/` (Task-19 fills those bodies), `terra_nt/lib/data/` (Task-03, Task-05), `terra_nt/lib/app/` (Task-06), `terra_nt/pubspec.yaml` (append-only, Task-00)
- GATE: `cd terra_nt && flutter analyze && flutter test test/features/profile/`
- DEPENDS ON: Task-05, Task-06

## Objective

Build the Profile tab, including the inline delete-account confirmation and the two
distinct clearing behaviours. This task carries **Deviation V6**, where the prototype's
"delete account" quietly restores the demo routes it was meant to destroy.

## Execution Guide

**Files:** `terra_nt/lib/features/profile/`.
Sources: `Terra NT.dc.html` L613–675, logic L1066–1070.

**Rows** (all `SettingsRow` from Task-02):

| Row | Content | Behaviour |
|---|---|---|
| Account | avatar circle, "NT Explorer", session email, chevron | pushes the `account` route (Task-06 already routes it; Task-19 fills the body) |
| Offline Maps | `Download` icon, label, sub-label "Download maps for areas with no signal" | pill toggle |
| Language | `Globe` icon, "Language", value "English", chevron | pushes the `language` route (Task-06 already routes it; Task-19 fills the body) |
| Log Out | `LogOut` icon + label, both in `AppColors.tagRed` | returns to Login |

The email falls back to `explorer@example.com` when the session's is empty.

**Offline Maps toggle:** off = `surface2` track, hairline border, `inkTertiary` thumb,
thumb left. On = `surface3` track, `hairlineStrong` border, `ink` thumb, thumb right. It is
**session state only** and downloads nothing — Task-05 already forbids persisting it.

### Delete account — deliberately low-prominence

Below a flexible spacer sits a small, centred, `inkTertiary` **12px caption text link**
reading "Delete account". No card, no icon, no button chrome. That understatement is the
design intent; do not promote it.

Tapping it **swaps the link in place** for an inline confirm card reading "Delete your
account and all saved routes? This can't be undone." with Cancel and Delete account
buttons. It must **not** navigate away, and must **not** open a dialog, sheet or route.

### The two clearing paths must not share a code path

| Action | Clears | Keeps |
|---|---|---|
| **Log Out** | email, password | saved routes, `onboardingDone` |
| **Delete account** (confirm) | email, password, `onboardingDone`, **and saved routes → empty list** | nothing |

**Deviation V6:** the prototype sets saved routes to `null`, which falls back to the seed —
so "delete account" resurrects the two demo routes it claims to delete. Clear to a genuinely
empty list, and make sure a subsequent fresh read stays empty.

Bottom nav visible, Profile active.

## Acceptance Criteria (DoD)

- [x] Widget test: the account row shows "NT Explorer" and the session email; with an empty session email it shows `explorer@example.com`.
- [x] Widget test: the Language row shows value "English".
- [x] Widget test: the Offline Maps toggle flips state on tap, and its resolved track/thumb colours match the on and off specifications.
- [x] Widget test: toggling Offline Maps writes **no** key to `PreferencesStore`.
- [x] Widget test: "Delete account" renders as centred `inkTertiary` caption text with no surrounding card or icon.
- [x] Widget test: tapping it swaps in the confirm card **in place** — no route is pushed and no dialog or bottom sheet is present in the widget tree.
- [x] Widget test: the confirm copy reads exactly "Delete your account and all saved routes? This can't be undone."
- [x] Widget test: Cancel returns to the idle link.
- [x] **V6 test:** confirming returns to Login, and saved routes are **empty** — then a fresh read from `PreferencesStore` still returns empty, **not** the two seeded entries.
- [x] **Log-out test:** logging out returns to Login and clears the email, while saved routes and `onboardingDone` are **unchanged**.
- [x] A test asserts the log-out and delete-account paths produce different state — they cannot be the same code path.
- [x] Widget test: Log Out's icon and label resolve to `AppColors.tagRed`.
- [x] `grep -rnE "0x[0-9a-fA-F]{8}" lib/features/profile/` returns nothing.
- [x] No layout exception at 360px width in both the idle and confirming states.
- [x] `cd terra_nt && flutter analyze` exits 0 with no warnings.
- [x] `cd terra_nt && flutter test test/features/profile/` exits 0.
