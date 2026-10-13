---
name: tomato-bug-transition
description: Safely discover, execute, and verify Tomato/Gitee Team Bug status transitions with the gitee CLI first and the configured work-item connector as fallback. Use when the user asks to flow, transition, start development on, resolve, close, reopen, or otherwise change the status of a 番茄/Gitee Team Bug or work item, including requests such as “帮我流转番茄 bug”, “转到开发中”, or “开始开发”.
---

# Tomato Bug Transition

Prefer the `gitee` CLI for item reads, field updates, transition discovery, and transition execution. Use persisted item state and enabled transitions as the source of truth. Never guess transition names or infer success from a mutation response alone.

## Choose the execution channel

1. Check that `gitee` is available, then use its Team commands with `--output json` so results remain structured and auditable.
2. Use these CLI mappings:

   | Operation | Preferred command |
   | --- | --- |
   | Read item | `gitee team item view <item-key> --output json` |
   | Update fields | `gitee team item edit <item-key> --values '<json-object>' --output json` |
   | List transitions | `gitee team transition list <item-key> --output json` |
   | Execute transition | `gitee team transition execute <item-key> --transition '<exact-name>' --output json` |

3. Fall back to the configured work-item connector only when the CLI is unavailable, unauthenticated, or lacks the required operation. The connector mappings are `getItemDetail`, `updateItem`, `getItemAvailableTransitions`, and `transitionItem`.
4. Keep one channel for all mutations in an operation. If a CLI mutation returns an uncertain result, reread with the CLI before considering any retry; do not switch to the connector and repeat the mutation. A definite pre-mutation CLI failure may use the connector fallback.
5. Never place credentials, tokens, cookies, or connector internals in commands or reports. Quote item keys, transition names, and JSON safely; do not build a shell command from untrusted text without argument-safe quoting.

## Execute the transition

1. Resolve the exact item key and requested target state from the user request. Do not use the most recently viewed card as an implicit target.
2. Read the item with `gitee team item view ... --output json` (or connector fallback `getItemDetail`). Record its current status and canonical item key.
3. If the persisted status already equals the requested target, make no mutation and report that the item is already in the target state.
4. Run `gitee team transition list ... --output json` (or connector fallback `getItemAvailableTransitions`) immediately before the mutation.
5. Filter to transitions returned with `disabled=false`. Select the exact raw transition value that clearly leads to the requested state.
6. If no enabled transition clearly matches, stop without mutating. Report the current status and enabled transition names; ask the user to choose only when intent cannot be resolved safely.
7. If the user's request explicitly asks to change the status, run `gitee team transition execute ... --transition '<exact-name>' --output json` (or connector fallback `transitionItem`) with the exact item key and exact returned transition value. A request to inspect, explain, or list transitions does not authorize mutation.
8. Read the item again through the same channel. Treat this persisted state as the success criterion.
9. Report the item key, previous status, transition used, and verified final status.

The preferred CLI pattern is:

```text
gitee team item view
  -> gitee team transition list
  -> choose exact enabled transition
  -> gitee team transition execute
  -> gitee team item view
  -> verify persisted target status
```

The connector fallback pattern is:

```text
getItemDetail
  -> getItemAvailableTransitions
  -> choose exact enabled transition
  -> transitionItem
  -> getItemDetail
  -> verify persisted target status
```

For example, an item in `待开发` may expose the enabled transition `开始开发`, which can result in `开发中`. Re-discover this every time; do not encode it as a permanent mapping.

## Preflight required Bug fields

For a Gitee-Team `测试缺陷` moving through `修复完成` to `待测试`, treat the five fields below as a known required preflight set. This set is a reference, not a universal schema. Confirm current workflow requirements and fields before writes; do not rediscover requirements by repeatedly triggering errors.

| Display field | Known key | Value shape | Rule |
| --- | --- | --- | --- |
| `根因分析` | `reason2` | one enum value | Select an evidence-supported value; `代码逻辑错误` is a verified value for ordinary code defects, not a universal default. |
| `RD引入原因分析` | `Dropdown12` | one enum value | Select an evidence-supported value; `功能实现遗漏` is verified when the implementation omitted required behavior, not a universal default. |
| `原因描述` | `Editor33` | editor text | Describe the verified technical or process cause. Explain why the defect occurred; do not copy the symptom or the solution. |
| `修复版本` | `CustomVersion2` | array of version strings | Use the current workspace version field metadata and verified fix version; resolve its actual ID and required value shape. Never reuse a version ID from another workspace or infer fix version from impact version. |
| `解决方案` | `Solution` | editor text | Describe the actual implemented fix concisely; do not copy the symptom as the solution. |

Use this preflight:

1. Read the five display fields from the CLI item detail before executing the transition. When using the connector fallback, read them from `getItemDetail` before calling `transitionItem`.
2. Before filling cause or solution fields, inspect the current card's comments, repair records, and user-provided task conversation. Treat those records as the primary evidence for `根因分析`, `RD引入原因分析`, `原因描述`, and `解决方案`; do not use generic defaults or infer them from the symptom alone. The user-provided task conversation remains valid card evidence even when the Tomato item itself has no comments.
3. The keys above are examples from one deployment. Confirm the current workspace schema once per operation; use its actual keys, types and enum values. Reuse within the same operation only while the metadata remains valid.
4. Derive values only from the user's request, the card's conversation/repair record, verified item data, or inspected implementation evidence. Reuse a verified enum value only when the card evidence clearly supports its meaning for the current Bug.
5. An explicit status-transition request authorizes updating required fields when the user's request, user-provided task conversation, repair record, verified item data, or inspected implementation evidence clearly establishes their values. In that case, update the fields and continue the transition without asking the user to approve the evidence-supported proposal. Ask only after checking all available evidence when a categorical value, cause, solution, or fix version remains genuinely ambiguous. A status-transition request does not authorize fabricating business facts.
6. When the evidence clearly establishes the values, run `gitee team item edit <item-key> --values '<json-object>' --output json` with the known field keys, then reread the item to verify every value persisted. With the connector fallback, call `updateItem` and check `outcome`, `appliedFields`, and `rejectedFields` before rereading.
7. After all known required fields are persisted, re-query transitions through the same channel, attempt the original transition once, and perform the final status reread.

Only refresh a field definition or enum when the CLI or connector returns evidence that the known rule is stale or incomplete, such as an unknown field, invalid value, data-format error, rejected field, or a new required-field validation error. Prefer `gitee team field list --output json` and its supported filters; with the connector fallback use `getSearchFields`. Query by display name, inspect the returned key/type/schema/options, correct the affected rule for the current operation, and retry only after verifying the field update.

If `transitionItem` returns `INVALID_ARGUMENT: <field>字段必填` with `outcomeUnknown=false`, treat it as a newly discovered or workflow-specific required field. The transition did not occur. Discover that additional field by display name and follow the same update-and-reread process. Do not use an error's internal name such as `fixVersions` as an input key without discovery; one deployment used `CustomVersion2`; use the key verified for the current workspace. Add no guessed value and do not blindly retry after each guess.

Required-field updates are separate persisted mutations. If some field updates succeed but the status transition later fails, report the result as partial and list the fields already applied.

## Handle uncertain or failed mutations

- On `403 PERMISSION_DENIED` with `outcomeUnknown=false`, state that no write occurred. Do not claim success or automatically retry the same mutation.
- On `400 INVALID_ARGUMENT` with `outcomeUnknown=false`, state that the attempted transition did not occur. Preserve any earlier successful `updateItem` writes in the report.
- On any error with `outcomeUnknown=true` or missing outcome semantics, reread the item before considering a retry. Avoid duplicate transitions.
- If the mutation returns success but the reread does not show the target state, report the verification failure rather than success.
- If rereading is unavailable, report the mutation as unverified, not completed.
- Preserve the intended item key and transition in the report so the operation can be retried after permissions recover.

## Keep the operation auditable

When the user requests technical details, show:

- the CLI command or connector tool name;
- the exact non-secret arguments sent;
- the returned transition names and `disabled` flags relevant to the decision;
- the mutation result and the final reread result.

Never invent or expose connector URLs, HTTP headers, bearer tokens, cookies, or other authentication details. Do not substitute browser automation for the connector unless the user explicitly requests that route and an operable signed-in page is available.

## Response templates

For verified success:

```text
已完成并复核：<itemKey> 从「<before>」通过「<transition>」流转到「<after>」。回读事项详情确认当前状态为「<after>」。
```

For a definite permission denial:

```text
未完成流转：<tool> 返回 403 PERMISSION_DENIED，且 outcomeUnknown=false，因此可以确认本次没有写入。目标操作是将 <itemKey> 通过「<transition>」流转；权限恢复后可重试。
```
