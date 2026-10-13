---
name: multi-agent-coding
description: Orchestrate repository coding work with a an allocator, one or more implementation workers, and an independent reviewer. Use when the user asks for multi-agent development, role-separated research/implementation/review, parallel coding, delegated code changes, or an allocator-worker-validator workflow.
---

# Multi-Agent Coding

Run a role-separated coding workflow. Use the host assistant’s available agent or task delegation capabilities. No specific vendor or model is required; if delegation is unavailable, report that limitation and run clearly separated planning, implementation and review passes without claiming independence.

## Roles

### Allocator

Use a model appropriate for planning. Own the user conversation and:

- Inspect repository instructions, status, relevant history, and the complete behavior chain.
- Translate the request into acceptance criteria and bounded implementation units.
- Identify dependencies, shared files, risks, and the validation strategy.
- Dispatch implementation work and send concise progress notifications.
- Integrate findings and decide whether another fix/review cycle is required.

Do not make routine code edits in the allocator role. Small coordination-only edits are allowed only when delegation would add more risk than value.

### Worker

Spawn with:

- A model appropriate for implementation, selected from the host’s actual available models.
- Only the task context needed for the assigned scope; avoid propagating sensitive or noisy history.
- A concrete, independently executable task.

The worker must:

- Read applicable repository instructions before editing.
- Inspect the existing implementation chain before changing it.
- Modify only assigned scope and preserve unrelated user changes.
- Run proportional targeted checks.
- Report changed files, checks, unresolved risks, and any scope conflict.

Never assign two live workers overlapping files or coupled behavior. Parallelize only independent units.

### Validator

Spawn a fresh agent with:

- A fresh read-only reviewer session or agent.
- The raw request, acceptance criteria and actual diff; exclude earlier confidence claims.
- A review-only prompt that does not reveal the allocator's expected verdict.

The validator must:

- Review the actual diff and surrounding behavior for correctness, regressions, security, data loss, concurrency, performance, and missing coverage.
- Check the user acceptance criteria explicitly.
- Run automation only when risk or uncertainty justifies it.
- Report findings first, ordered by severity, with exact file/line evidence.
- Make no code edits.

Choose reviewer capabilities according to task risk and the user’s cost/speed preferences.

## Workflow

1. **Establish scope**
   - Read `AGENTS.md` and applicable skill instructions.
   - Inspect `git status` without disturbing existing changes.
   - Research the end-to-end path relevant to the request.
   - Write acceptance criteria and note assumptions.

2. **Partition**
   - Prefer one worker for a cohesive change.
   - Use multiple workers only for non-overlapping files or clearly independent components.
   - Keep repository-wide integration decisions with the allocator.

3. **Notify and dispatch**
   - Tell the user the discovered approach, main risk, and dispatched roles in a short commentary update.
   - Spawn workers with bounded prompts containing:
     - objective and acceptance criteria;
     - exact repository/worktree and likely file scope;
     - constraints and non-goals;
     - required checks;
     - required completion report.

4. **Supervise**
   - Continue safe read-only research while workers run.
   - Relay material progress, blockers, or changed assumptions to the user.
   - Use the host’s supported agent messaging and follow-up tools.
   - Never silently reassign overlapping work.

5. **Inspect worker output**
   - Read the diff and worker report.
   - Confirm no unrelated changes were introduced.
   - If a worker is blocked, resolve repository facts before changing scope.

6. **Validate independently**
   - Give the validator the raw request, acceptance criteria, repository location, and current diff.
   - Do not include the worker's confidence or the allocator's suspected issues.
   - Automation policy:
     - Run formatting, type checks, or focused tests when cheap and directly relevant.
     - Run broader automated tests for shared infrastructure, state/data transformations, concurrency, security, public APIs, or uncertain cross-module impact.
     - Skip broad automation for low-risk localized changes when static review plus a focused check is sufficient; state what was skipped and why.

7. **Fix loop**
   - If the validator finds actionable issues, send them to the original implementation worker.
   - After fixes, launch a fresh validator pass or re-trigger the validator with the new diff.
   - Stop after acceptance criteria pass or report a concrete blocker requiring user authority.

8. **Deliver**
   - Lead with the outcome.
   - Summarize implementation, review result, checks run, and residual risks.
   - Distinguish confirmed validation from untested assumptions.
   - Do not commit or push unless the user explicitly requested it.

## Dispatch Templates

Worker prompt:

```text
Act as the implementation worker. In <repo>, implement <bounded objective>.
Acceptance: <criteria>.
Scope: <files/components>. Do not touch <non-goals>; preserve unrelated changes.
Inspect existing behavior before editing, implement the smallest cohesive change,
run <targeted checks>, then report changed files, results, and unresolved risks.
```

Validator prompt:

```text
Act as an independent read-only code reviewer. Review the current diff in <repo>
against this request and acceptance criteria: <request/criteria>.
Inspect surrounding code. Run only risk-justified checks. Do not edit files.
Return findings first by severity with exact file/line evidence, then checks run,
coverage gaps, and a pass/fail verdict.
```

## Host Constraints

- Discover available agents, models and concurrency limits; do not invent unsupported model identifiers or copy another host's arguments.
- Keep user interaction with the coordinator. Delegate only when requested or permitted by the active session's policies.
- Respect the concurrency limit and count the coordinator when budgeting workers.
- Agents may share a filesystem. Use isolated worktrees when concurrent Git operations or overlapping edits require them; do not dispatch overlapping ownership.
- A sequential self-review is a fallback, not an independent review. State this limit in delivery.
