# Yarisa Doctor — agent rules

These rules apply to any coding agent working in this repository (Grok, Claude, Cursor, etc.).

## Git / PR workflow (required)

### Never ship major work straight to `main`

For **any major request**, agents must:

1. Create a **feature branch** from up-to-date `main`  
   Example: `feature/<short-slug>` or `fix/<short-slug>`
2. Implement and commit on that branch only
3. Open a **Pull Request into `main`** (do not push directly to `main` unless the user explicitly overrides)
4. Summarize the PR (what / why / test plan) and leave merge to the user unless they ask the agent to merge

### What counts as a “major request”

Treat as major (→ **must use a PR**) when any of the following apply:

- New feature, redesign, or multi-screen UX change
- Auth, payments, notifications, CallKit/Jitsi, FCM, or other infra
- Schema / Firestore rules / Cloud Functions changes
- Dependency adds/upgrades that affect native builds (iOS/Android)
- Refactors touching **3+ files** or more than one layer (UI + API + services)
- Bug fixes that change behavior across flows (not a one-line typo)

### What may stay on a short local branch without a PR (only if user agrees)

- Typos, comment-only edits, tiny single-file fixes  
- Purely local experiments the user says not to push  

When unsure: **use a PR**.

### PR defaults

- Base: `main`
- Title: imperative, scoped (e.g. `feat: …`, `fix: …`)
- Body: summary, risk notes, how to test (Flutter rebuild notes if native/plugins changed)
- Do **not** force-push `main`
- Do **not** merge the PR unless the user explicitly asks

### After user approval

If the user says “merge”, prefer merging via the PR (GitHub UI or `gh pr merge`), not by committing on `main` directly.

## Product notes for this app

- Self-hosted Jitsi: `YarisaJitsiCallService.serverURL` (Contabo / see repo docs). Keep in sync with **yarisa-patient**.
- Doctor UI: follow `DOCTOR_UI_GUIDELINES.md` and `lib/ui/doctor_ui.dart`.
- Auth chrome: `lib/components/auth/`.
- Calls: `CallKitService`, `CallPermissions`, FCM background handler — debounce accepts; request mic/camera before dialing.

## Build reminders

- iOS Podfile must keep `PERMISSION_MICROPHONE=1` / `PERMISSION_CAMERA=1` (and related) for `permission_handler`.
- Prefer full `flutter run` / rebuild after changing native plugins, CallKit, or Jitsi URL.
