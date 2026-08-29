# PR workflow for major work

Agents working in **yarisa-doctor** must not push major changes directly to `main`.

1. Branch from `main`: `feature/…` or `fix/…`
2. Commit on the branch
3. Open a PR targeting `main`
4. Merge only when the user explicitly asks

Major = features, redesigns, auth/calls/notifications/infra, multi-file refactors, native dependency changes.

See root `AGENTS.md` for full criteria.
