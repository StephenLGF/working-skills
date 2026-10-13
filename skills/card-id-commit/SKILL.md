---
name: card-id-commit
description: Commit changes with a Gitee/Tomato card ID in the message subject. Use when the user asks to commit, amend, or fix a commit message and a card ID (e.g. Gitee-Test-2026-737, Proxima-1116) is available or inferable from the current branch or task context. Covers "帮我提交", "commit 一下", "记得带卡片 ID", and amend/rewrite of an existing commit to add or fix the card ID.
---

# Card-ID Commit

Commit Git changes with the work-item card ID placed in the commit **subject line**, inside square brackets, immediately after the conventional-commit type — no scope parentheses. The card ID is mandatory for this workflow. Honor the target repository’s actual commit convention and hooks; do not claim commitlint is installed without inspecting it.

## Commit message format

```
<type>: [<Card-ID>] <subject>

<body — optional>
```

Rules:

1. **`<type>`** — conventional-commit type with **no scope**: `fix`, `feat`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`. Never write `fix(mindmap):` or any `(scope)`.
2. **`[<Card-ID>]`** — the card ID in square brackets, directly after `: `. Example: `[Gitee-Test-2026-737]`.
3. **`<subject>`** — short imperative summary in the same language as the card title; no trailing period.
4. **`<body>`** — optional, separated by a blank line; explain *what changed and why*, not *what the card says*.

Illustrative examples:

```
fix: [Gitee-Test-2026-737] 修改批量生成用例禁用时tip2提示文案
feat: [Gitee-Test-2026-628] 调整组合预览第二步界面
fix: [Proxima-1116] update request handling
```

Wrong (do not produce):

```
fix(mindmap): [Gitee-Test-2026-737] ...   ← has scope parentheses
fix: Gitee-Test-2026-737 ...              ← missing square brackets
fix: [Gitee-Test-2026-737] xxx。          ← trailing full-width period
```

## Determine the card ID

Resolve the card ID from, in priority order:

1. The user's explicit instruction (e.g. "用 Gitee-Test-2026-737 提交").
2. The task/todo context or card title already provided in the conversation.
3. The current Git branch name when it contains a card-like token (e.g. `feat/Gitee-Test-2026-628` → `Gitee-Test-2026-628`).

If no card ID can be resolved safely, **stop** and ask the user for the exact card ID before committing. Do not fabricate or guess an ID.

## Stage the right files

- Stage **only the files that belong to the current card**. Other modified files in the working tree are out of scope and must not be included.
- Before staging, run `git diff --stat` (or `git status`) and compare the changed files against the card's described scope. If a file does not belong to this card, leave it unstaged.
- Do not run `git commit -a` or `git add -A` for card-scoped work.

## Amend an existing commit

When the user asks to fix/rewrite an already-created commit (e.g. "改成 xxx 风格", "记得用卡片 id"):

1. Use `git commit --amend -m "<new message>"` (or `-m` twice for subject + body) on the current `HEAD`.
2. Preserve the original author date and the originally staged file set unless the user explicitly asks to change them.
3. Keep the card ID in the amended subject line following the same format rules above.

## Pre-commit hooks and validation

Inspect the target repository's actual commitlint/Husky configuration. Run required hooks and checks; fix hook failures rather than bypassing them. Some repositories require the card token immediately after the type; others allow a scope. The repository/user convention takes priority over this skill's default.

Before amending, confirm HEAD is the intended commit and do not accidentally incorporate unrelated staged changes. Amending a published commit rewrites history; do not force-push without explicit authorization.

After a successful commit, report the short hash and the final subject line so the user can verify.
