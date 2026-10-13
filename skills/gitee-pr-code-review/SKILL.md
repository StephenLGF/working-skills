---
name: gitee-pr-code-review
description: Review Gitee pull requests with code MCP-first diff retrieval, merged-state detection, requirement context, immutable Git evidence, merge-contamination detection, code-quality analysis, isolated validation, and optional publication of an explicitly requested completed review. Use when asked to review, CR, audit, or assess a Gitee PR or merge request, including checking whether a PR is already merged, whether conflict resolution restored code already deleted from the target branch, or whether unrelated code was accidentally committed.
---

# Gitee PR Code Review

Produce an evidence-backed review without changing the contributor's branch or the user's working tree.

## Repository identity and capabilities

Resolve the repository from the user's full PR URL or explicit repository context. PR IIDs are repository-local; do not guess an enterprise, host, project ID, or clone URL. No organization aliases or remembered PR numbers are bundled.

Prefer a configured Gitee code MCP when available. Without it, use the installed `gitee code pr view/diff` CLI (check --help), configured read-only APIs, and Git evidence. For Tomato cards use `gitee team item view` or a configured work-item connector; Code Issues are not Team cards. Tool names below describe the reference MCP integration; inspect actual schemas and adapt to capabilities present in the user's environment.

Review alone produces local feedback. Publish comments only when the user explicitly asks to post the completed review; approve/merge remain separate actions. If a precise inline-comment API is unavailable, retain those findings in the local report rather than invent diff positions.

## Workflow

1. Read the repository's `AGENTS.md` and task-specific authoritative docs. Inspect `git status` and preserve every unrelated local change.
2. Discover the `code` MCP tools and use them as the primary PR source:
   - Resolve the exact `project_id`, PR `iid`, and optional `pr_id`; never guess identifiers or confuse the global PR ID with the repository-local IID.
   - Fetch PR metadata with `search_merge_request`, then call `get_pr_current_state` before retrieving the diff. Record whether the PR is open, closed, merged, or drafted, plus the merge commit SHA, merged-at time, and merger when returned. Cross-check conflicting state fields instead of assuming `closed` means `merged`.
   - Fetch the changed-file inventory and diff with `get_pr_changes`. Use `get_pr_diff_tree` and `get_pr_diff_details` to retrieve complete or focused diffs when available. Paginate until exhausted and request full text where the schema supports it.
   - Prefer MCP-derived PR title, author, target/source branches, commits, changed files, discussions, state, and diff. Record tool names, pagination, truncation, omitted/binary files, and failed calls as review evidence.
   - Treat a summary, file tree, or truncated patch as insufficient. Retry through the MCP's focused diff tools before using Git fallback.
   - If a commit or PR references a Tomato/Gitee Team item, read that exact item through MCP. Capture acceptance intent, root cause, proposed solution, status, and relevant comments or attachments.
   - If MCP diff retrieval is unavailable, incomplete after retries, or inconsistent, say so precisely and use immutable Git PR refs for the missing evidence. Never imply fallback evidence came from MCP.
3. Refresh and pin the PR refs for independent verification. For standard Gitee refs, run `scripts/prepare_review.sh <repo> <pr-number> [base-ref]`. Treat the merge ref's first parent as the target snapshot and the head ref as the proposed source. Compare the MCP file inventory and diff with the pinned Git snapshot; investigate discrepancies before reviewing.
4. Establish scope with the pinned commit list, merge commits, `diff --stat`, `diff --name-status`, and complete diffs. Inspect both `base...head` for branch-introduced history and `base..head` for the final snapshot delta; do not rely on the current checkout or only one diff form.
5. Run the mandatory contamination audit below before reviewing behavior.
6. Trace each changed behavior through its callers, sibling components, data contracts, error paths, and existing tests. Compare the implementation against the MCP-derived requirement, not only against the patch description.
7. Run the mandatory code-quality audit below. Treat correctness and maintainability problems as findings when they have a concrete impact; do not reduce review to formatting or lint.
8. Validate in the isolated worktree created by the script. Start with `git diff --check`, then run the smallest relevant lint, type-check, unit, build, or UI checks. Never run a fixer in the user's worktree.
9. Re-read the final snapshot delta after validation. Confirm that every finding exists at the pinned head, is absent from the pinned base where relevant, and is reproducible from the pinned refs.
10. Classify the result as a normal review when unmerged or a post-merge audit when already merged. When explicitly asked to post, publish reliable line-level findings and one overall review through the available verified interfaces using the protocol below, then verify read-back. Otherwise deliver the review locally.

## MCP Diff Protocol

Use as much MCP diff evidence as the server can provide before falling back to Git.

1. Call `search_merge_request` to pin identity and metadata.
2. Call `get_pr_current_state` to establish whether the PR has already merged.
3. Call `get_pr_changes` for the authoritative changed-file set and initial patch.
4. Call `get_pr_diff_tree` when available to detect files or sections omitted from the initial response.
5. Call `get_pr_diff_details` for every truncated, omitted, suspicious, or finding-relevant path. Use `is_full_text: true` when supported, paginate when supported, and preserve whitespace changes unless intentionally auditing with them ignored.
6. Compare MCP paths and hunks with `git diff --name-status` and the pinned final snapshot. If they disagree, do not publish until the discrepancy is resolved or explicitly documented as a limitation.

If the PR is already merged, continue the requested review against the immutable merged/head snapshot. Label the result `post-merge audit`; replace `approve` or `request changes` with `merged — no findings` or `merged — follow-up fix required`. Recommend a follow-up PR for actionable findings and never imply the merged PR can still be blocked.

Do not pass credentials in review text, logs, or final output. Supply `token`, `authorization`, and `enterprise` only through the MCP arguments or configured authentication mechanism.

## Publish Review Through MCP

A review or CR request by itself does not authorize publishing comments. Only an explicit request to post the completed review to that PR authorizes publication. Approval, merge, branch updates, and work-item transitions remain unauthorized unless separately requested.

Use these MCP interfaces as distinct publication channels:

- `create_pr_review`: publish one inline code-review comment. Required arguments are `project_id`, repository-local `iid`, and `note`. Also pass the reviewed head `commit_id`, `noteable_type: "PullRequest"`, and an exact position returned by the MCP diff: either `line_code` or `diff_position_attributes` with the matching path and changed-side line. Do not use this interface without a verified diff position.
- `add_pull_request_comment`: publish the single overall PR review. Required arguments are `project_id`, repository-local `iid`, and `note`; pass `noteable_type: "PullRequest"`. Omit `commit_id`, `line_code`, `diff_position_attributes`, `parent_id`, and `reply_user_id` so the result is an unpositioned PR-level comment rather than a code-line comment or reply.
- `get_pr_comments`: read back both publication types and verify their content, author-visible position when present, and returned IDs.

If these interfaces are not exposed in the active MCP session, refresh tool discovery once. If they remain unavailable, complete the analysis but do not silently substitute an unrelated mutation interface; report that publication is unsupported in the current session.

1. Draft the complete findings set before publishing anything. For each finding, record the exact head path/line, severity, scenario, impact, and fix direction. Separately draft one findings-first overall review containing the PR merge state, verdict, all actionable findings, evidence SHAs, contamination/code-quality audit outcomes, validation, and residual risks. Include merge commit/time when available. Add a stable, unobtrusive marker to each draft using the reviewed head SHA and either the finding path/line or `overall`; use the same marker for duplicate detection and read-back verification. Do not publish partial analysis or progress notes.
2. Re-fetch `get_pr_current_state` immediately before publishing. If the PR head changed, stop and re-review. If an initially unmerged PR became merged, reclassify the verdict as a post-merge audit and revise every blocking/request-changes statement before publishing. Never post a stale verdict.
3. Publish one code-line comment per finding when the MCP diff provides an unambiguous position. Use `create_pr_review` with exact head `commit_id`, `noteable_type: "PullRequest"`, finding text and stable marker in `note`, and verified `diff_position_attributes` (`new_path`/`old_path` and the applicable `new_line` or `old_line`) or the exact `line_code` returned by `get_pr_diff_details`. Never guess a diff position, synthesize `line_code`, or mix a new-side line with an old-side path. If a finding concerns multiple lines, comment on the narrowest causal line and reference the other paths/lines in the note.
4. Keep any finding that cannot be positioned reliably in the overall review only. If a line-comment call fails, record the failure and retain the full finding in the overall review; do not drop it or retry with a guessed position.
5. Always publish exactly one overall review after the line comments. Use `add_pull_request_comment` with `project_id`, `iid`, `noteable_type: "PullRequest"`, and the self-contained review plus its stable marker in `note`. Omit all line-position and reply fields. Do not use a positionless `create_pr_review` as an automatic fallback: if `add_pull_request_comment` is unavailable or fails, preserve the completed review locally and report the publication failure rather than risk creating the wrong review type.
6. In the overall review, list all findings even when separately posted inline, and mark each as `inline posted`, `overall only`, or `inline failed`. This makes the overall review self-contained and prevents lost context.
7. Before retrying any ambiguous timeout, call `get_pr_comments` and search for a stable marker containing the reviewed head SHA plus finding path/line or overall-review heading. Do not duplicate a line comment or the overall review.
8. After publication, call `get_pr_comments` and verify every expected line comment and the overall review. Record returned comment/review IDs, paths/lines when returned, and the reviewed head SHA. Report partial or total publication failure explicitly; never claim a comment was posted without read-back evidence.

## Mandatory Contamination Audit

### Target-deletion resurrection

Detect code that the target branch deliberately removed after the PR branch diverged and that a merge, rebase, cherry-pick, or conflict resolution restored.

1. Pin `merge_base=$(git merge-base <base-sha> <head-sha>)` separately from the current target `base-sha`.
2. Inspect target-only history and deletions with `git log <merge-base>..<base-sha>`, `git diff --diff-filter=D <merge-base>..<base-sha>`, and the deleted hunks in `git diff <merge-base>..<base-sha>`.
3. For every target-deleted file, symbol, configuration block, dependency, flag, route, or behavior, check whether equivalent content exists in the PR head. Use exact searches plus history-aware evidence such as `git log -S`, `git log -G`, `git blame`, and focused diffs; account for moved or renamed code instead of relying only on identical text.
4. Inspect every merge/conflict-resolution commit and compare it with each parent. A clean `base...head` diff is not proof that deleted target code did not return.
5. Classify a match as a finding only when history or requirement evidence shows intentional target deletion and the PR restores it without a documented reason. Report the deletion commit, restoring commit when identifiable, affected path/symbol, and current head line.

### Accidental-change inventory

Prove that every changed file and commit belongs to the PR's stated requirement.

- Map each commit and changed file to a requirement, necessary refactor, generated consequence, dependency update, or test. Investigate anything unmapped.
- Check for unrelated features or fixes, debug logs, temporary instrumentation, commented-out code, local paths, secrets, fixtures, snapshots, generated artifacts, lockfile churn, broad formatting, copied code, and configuration or dependency changes not required by the PR.
- Compare merge and cherry-pick commits against their parents to identify changes imported from another branch. Check suspicious patches with `git patch-id`, `git log --cherry`, or equivalent history searches when useful.
- Do not call a change accidental merely because it is large or unfamiliar. Require concrete scope, history, requirement, or build evidence; otherwise report it as a residual risk requiring author confirmation.

## Mandatory Code-Quality Audit

Review the final code in context, not only changed lines. Check at minimum:

- correctness, boundary conditions, null/empty/error paths, state transitions, concurrency, cleanup, and idempotency;
- delayed and asynchronous callback lifetime: for code added inside timers, promises, subscriptions, event listeners, or debounced/throttled callbacks, verify unmount/disposal behavior, ref nullability, stale closures, cancellation, and races. Attribute only the risk introduced or worsened by the PR; keep pre-existing lifecycle debt separate;
- security, permissions, injection, sensitive data, unsafe parsing, data loss, and compatibility;
- API/data contracts, callers, sibling implementations, repeated UI/API patterns, and backward compatibility;
- complexity, duplication, misleading abstractions, dead code, naming that obscures behavior, and maintainability where it creates a concrete defect risk;
- performance risks such as repeated I/O, unbounded work, unnecessary renders/queries, large allocations, or hot-path regressions;
- tests that cover the requirement, regression, conflict resolution, and important failure paths. Missing tests are findings when existing test infrastructure could reasonably catch the risk.

## Review Rules

- Prioritize correctness, regressions, security, data loss, race conditions, compatibility, and missing test coverage over style.
- Never approve before completing both contamination checks and the code-quality audit. Record each as passed, failed, or not fully verifiable with a reason.
- Check repeated UI/API patterns completely. A fix applied to two of three equivalent controls is a functional gap, not a style nit.
- Verify helper behavior from its implementation and downstream dependencies; do not infer effects such as table refreshes or duplicate requests from names or comments alone. Report duplicate I/O only when the call chain, request trace, or state dependency demonstrates it.
- Consolidate observations with the same root cause into one finding. Separate proven findings from residual risks and author-confirmation questions; do not present speculative concerns as defects.
- Use exact file and line references from the PR head. Explain the triggering scenario, observable impact, and smallest safe direction for correction.
- Publish only when the user explicitly requests posting to the PR. Do not approve, merge, update branches, modify issues, transition work items, or perform any other remote mutation unless the user explicitly asks.
- Do not modify business code during a review-only request.
- Keep MCP pagination and tool limitations explicit. Report failed MCP calls before changing query shape.

## Output

Keep the user-facing review concise and easy to scan. Lead with the verdict, then findings ordered by severity:

1. `Conclusion: approve | approve after changes | request changes` (or the merged equivalents).
2. For each finding, give `[P1|P2|P3] Short title` — `path:line`, the concrete scenario and impact, and the smallest safe fix.
3. Add at most three genuinely material confirmation points, clearly separated from findings.

Do not put passed contamination checks, "no unrelated code found", "no resurrected deletion found", raw SHAs, tool names, or routine validation success in the main review body unless the user asks for the audit trail or the result is necessary to understand a finding. Preserve that evidence internally and include only failures, limitations, material residual risks, or unusual state in the concise review.

When a detailed audit report is requested, include:

- review verdict: approve or request changes for unmerged PRs; merged — no findings or merged — follow-up fix required for merged PRs;
- PR state: open, closed, drafted, or merged; for merged PRs include merge commit/time when available;
- evidence: pinned head/base SHAs and requirement item key;
- contamination audit: target-deletion resurrection result and accidental-change inventory result, including merge-base and relevant commits;
- code-quality audit result and material residual risks;
- validation results and anything not tested;
- MCP capability boundary or fallback used.
- publication result: line-comment status per finding, overall-review status, MCP tools used, verified comment/review IDs or other read-back evidence, and any posting failure or fallback.

If there are no findings, state the verdict directly and mention only material residual risks or missing validation. Do not pad the response with passed checks.

## Script

`scripts/prepare_review.sh` validates the repository and numeric PR ID, fetches Gitee's head and merge refs into review-only refs, derives the target snapshot and merge base, creates a detached temporary worktree, and prints shell-safe review metadata for both history and final-snapshot comparisons. It does not clean up automatically so evidence remains available until the review is complete.
