# 使用者机器配置

本分享版不包含作者的机器地址、用户、SSH key 路径或日志路径。执行前由使用者在本地私有配置中提供并核验：

| 字段 | 用途 |
|---|---|
| selector / SSH alias | 用户指定的机器标识 |
| host / user | 经确认的连接目标及用户 |
| identity file | 使用者自己的专用密钥路径 |
| host key fingerprint | 已验证的主机指纹 |
| Compose directory / service | 经现场读取确认的服务位置 |
| health check | 已配置的只读健康检查 |

优先使用已验证 SSH alias；通过 ssh -G 查看最终配置。缺少必需字段时停止连接，不猜 IP、用户、key、容器或邻近机器。私人配置不要提交到分享仓库。
