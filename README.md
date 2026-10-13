# Working Skills

把日常研发流程整理成可复用的 AI 助手 Skill。首批分享版来自本地自用流程，已移除个人主机配置、账号 profile、固定版本 ID 和项目别名；本地原版与分享版可以不同。

## Skills

| Skill | 用途 | 主要依赖 |
|---|---|---|
| [upgrade-document](skills/upgrade-document/SKILL.md) | 用升级 PR 的最新内容整理需求、独立 Bug、配置操作和正式预览，最终补版本/附件 | Git、Gitee/番茄、飞书 |
| [lark-cli-read](skills/lark-cli-read/SKILL.md) | 优先通过本地 CLI 读取飞书文档和 Wiki | lark-cli |
| [card-id-commit](skills/card-id-commit/SKILL.md) | 按卡片范围提交，提交信息携带卡片编号 | Git、目标仓库规范 |
| [tomato-bug-transition](skills/tomato-bug-transition/SKILL.md) | 发现真实可用动作，补齐字段并核验番茄状态流转 | gitee 或番茄连接器 |
| [tomato-defect-transition](skills/tomato-defect-transition/SKILL.md) | 测试缺陷修复完成到待测试的专门流程 | gitee 或番茄连接器、字段元数据 |
| [gitee-pr-code-review](skills/gitee-pr-code-review/SKILL.md) | Gitee PR 评审、合并污染检查、隔离验证及可选发布评论 | Git、Gitee CLI/API/MCP |
| [ssh-environment-ops](skills/ssh-environment-ops/SKILL.md) | SSH/Docker 日志检查、受控服务变更与健康核验 | 使用者自己的 SSH/机器配置 |
| [multi-agent-coding](skills/multi-agent-coding/SKILL.md) | 分配、实现、独立评审的多代理协作流程 | 宿主支持的代理能力 |

## 使用

```sh
git clone https://github.com/StephenLGF/working-skills.git
```

按你的助手说明，将所需的整个 `skills/<name>/` 目录复制到它支持的 Skill 目录。保留 `references/` 和 `scripts/`，不要只复制 SKILL.md。支持 SKILL.md 的助手可以加载该目录；不支持自动加载的助手可直接读取 SKILL.md，并按里面的相对引用读取其他文件。这里不捆绑特定助手的安装器、模型或账号。

示例请求：

- “使用 upgrade-document，根据这个升级 PR 链接和现有飞书文档，先整理预览。”
- “使用 lark-cli-read，读取这篇飞书需求。”
- “使用 card-id-commit，只提交这张卡片相关的修改。”
- “使用 tomato-defect-transition，将这张已修复缺陷转到待测试。”
- “使用 gitee-pr-code-review，评审这个 PR，先把结果给我看。”

CLI 与账号权限需要使用者自行配置。本仓库不提供安装包、认证凭证或机器连接信息，命令参数以当前安装版本的帮助为准。流程不会把阅读文档当作写入授权，评审不会默认发布评论，SSH 变更需按其计划确认。

## 分享版调整

- 升级文档：PR 可作为范围入口，每次重新获取最新内容；预览不显示待确认清单或 PR/commit 数量。
- 番茄流程：元数据优先，移除固定工作空间、修复版本 ID 和个人 profile。
- Gitee Review：移除企业仓库映射及历史 PR 记录，提供 CLI/API 适配；评论发布改为用户明确要求时执行。
- SSH：仅包含空的使用者配置说明，不包含原作者机器地址、用户名或 key 路径。
- 多代理：角色保持明确，模型与调用参数由宿主能力决定。
- 卡片提交：检查当前仓库规范，不假设所有项目安装了相同 hooks。

## 本次未收录

- frontend-design、PDF、Playwright：看起来是通用来源的 Skill，来源/许可及转载边界未单独核实，不混入自制集合。
- investment-research：依赖原项目的金融数据规则和工具，当前副本不能作为完整独立流程交付；需确认来源和补齐依赖后再评估。

本仓库未替第三方材料声明许可；如需正式开源许可，可由作者另行选择。检查通过不等于已在所有助手、CLI 版本和工作空间完成真实端到端测试。
