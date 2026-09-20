# Implementation Plan: Post-Commit Transaction Isolation and Error Handling

## Summary
Refactor post-commit callbacks execution on `Cursor` (`PostcommitCallbacks`) to ensure each post-commit callback executes in its own transaction, exceptions in individual callbacks are caught and logged without interrupting the remaining callbacks, and the cursor is left in a clean committed/rolled-back state.

## Tasks
- [x] Task 1: Create `PostcommitCallbacks` class and update `Cursor` in `odoo/sql_db.py`
- [x] Task 2: Add comprehensive unit tests in `odoo/addons/test_base/tests/test_orm/test_registry_signaling.py` covering:
  - All postcommits execute even if an intermediate callback raises an exception
  - Exceptions are logged properly
  - Each postcommit callback runs in its own transaction (committed on success, rolled back on failure)
  - The cursor remains clean with no uncommitted or pending work after `postcommit.run()`
  - Re-entrancy and data aggregation in postcommit callbacks
- [x] Task 3: Run existing and new test suites to verify full test passing
- [x] Task 4: Git commit with descriptive message and push to `20.0-numa` branch
- [x] Task 5: Document results and update `tasks/todo.md` review section

## Review
- Implementation is complete and fully verified.
- `PostcommitCallbacks` guarantees per-callback transaction isolation, error logging, and cursor cleanliness.
- Changes committed and pushed to `origin/20.0-numa` (commit `4406c83698f4`).
- All unit tests pass cleanly.
