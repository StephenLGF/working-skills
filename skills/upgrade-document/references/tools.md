# 工具适配与命令参考

这些是已验证的命令形态示例，运行时仍以安装版本的 `--help` 为准。全部路径、profile、远端、仓库及 token 使用本次真实上下文，不照抄作者环境。不要安装/升级 CLI 或扩大权限来绕过错误。

## 能力对应

| 必需信息 | 推荐路径 | 替代路径 |
|---|---|---|
| PR 状态和分支 | `gitee code pr view` | Gitee 只读 API / 连接器 |
| commit 和 diff | 本地 Git，fetch 后固定 SHA | 可提供完整提交及差异的代码 API |
| 类型、父子层级、负责人 | `gitee team item view` | 番茄只读详情/层级/字段接口 |
| 飞书正文和 Wiki 目录 | `lark-cli` | 已配置且有权限的只读连接器 |
| 预览 | UTF-8 Markdown 文件 | 宿主附件或 Markdown 渲染器 |

无终端的助手若只能读 API，必须得到相当的最新分支 SHA、完整提交和 diff，不能声称做过 Git fetch。只有用户提供的静态导出时，标明其快照时间及信息缺失。

## Git

先确认当前目录和 remote 与 PR 仓库相符。完整 PR URL 的项目路径与 Git clone URL 可能不同，不凭 UI URL 拼 clone 地址。

```sh
git remote -v
git status --short
git fetch origin '+refs/heads/<base>:refs/remotes/origin/<base>' '+refs/heads/<source>:refs/remotes/origin/<source>'
git rev-parse 'origin/<base>' 'origin/<source>'
git merge-base '<BASE_SHA>' '<TARGET_SHA>'
git log --format='%H%n%B%n---END---' '<BASE_SHA>..<TARGET_SHA>'
git diff --name-status '<MERGE_BASE_SHA>' '<TARGET_SHA>'
git diff '<MERGE_BASE_SHA>' '<TARGET_SHA>' -- '*.yml' '*.yaml'
```

上面的尖括号是占位符，替换后执行。分叉 PR 使用 merge-base 到源头的 diff；普通祖先范围可直接用 BASE 到 TARGET。按需读取完整 diff，不只依靠 stat。跨 fork 可用明确的远端 URL fetch 到独立临时引用，不修改用户已有 remote；源、目标仓库信息必须来自 PR。

## Gitee CLI

```sh
command -v gitee
gitee code pr view --help
gitee code pr view <number> --repo '<full_path_or_project_id>' --json
gitee code pr diff <number> --repo '<full_path_or_project_id>'
gitee team item view --help
gitee team item view '<card_key>' -o json
gitee team item search --help
gitee team itemtype list --help
gitee team field workspace --help
```

使用正确账号；需要 profile 时使用使用者已配置的 profile，不固定为 `osc`。认证失败查看 `gitee auth status/login --help`，由使用者完成登录。不要打印配置文件或凭证。

响应可包含 `itemType.key/name`、`ancestor`（直接父项）、`ancestors`（祖先 ID）、`values.assignee/QA`，字段因空间而异，需用元数据识别。直接父项不是需求时继续读取祖先；只有 ID 列表不足以证明类型。接口空数组且已确认字段完整才可认定无父项；字段缺失不能当无父项。

部分 CLI 将 JSON 打印到 stderr 并混入进度或 ANSI 字符。先检查退出码及实际输出通道；若保存 stdout 为空，检查捕获的 stderr。可将二者保存到本轮临时文件并提取完整 JSON 对象，拒绝错误对象，不截断或把日志当业务字段。原始响应可能含私人信息，仅输出本任务所需字段，不纳入分享包。

## 飞书 CLI

```sh
command -v lark-cli
lark-cli docs +fetch --help
lark-cli docs +fetch --doc '<完整飞书链接>' --doc-format markdown
lark-cli wiki +node-get --help
lark-cli wiki +node-list --help
```

读取需要检查 `ok=true`、完整的 `data.document.content`，保存 document_id/revision_id。Markdown 响应可能保留 cite/table/figure XML，不要误当纯 Markdown。图片 alt 或附件元数据不等于已完整读取图片/脚本。

机器人能读正文不一定能列 Wiki 目录。目录权限不足时可尝试已授权的 user 身份；用户登录过期则按 `auth login --help` 和错误提示走授权流程。只申请实际需要的读取权限，不自动要求所有权限。设备登录使用 `--no-wait --json`，将原样授权 URL（及 CLI 要求的二维码）交给用户，用户完成后再续用 device code；不在同一轮阻塞等待、不保存凭证到 Skill。

写入阶段再按需查看：

```sh
lark-cli docs +create --help
lark-cli docs +update --help
lark-cli docs +media-insert --help
lark-cli wiki +node-create --help
lark-cli skills read lark-doc/references/lark-doc-update.md
lark-cli skills read lark-doc/references/lark-doc-md.md
```

多行内容优先用 `@file`，避免 shell 引号、反引号和变量替换破坏内容。块级更新前用 with-ids 获取真实 block ID；结构变化后重新读取，不复用过期 ID。不要凭示例构造未知 XML 标签。
