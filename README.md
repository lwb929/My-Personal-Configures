# My Personal Configures

个人配置与部署脚本索引。

| 目录 | 内容 | 说明 |
|---|---|---|
| [`deploy/open-design/`](deploy/open-design/) | OpenDesign 服务端部署包（Docker Compose） | 单容器：Web UI + `/api` + SQLite；含备份/恢复/反代/自检脚本 |

## 约定

- 所有含密钥的文件（`.env`、`*.tgz`、`backups/`）由各目录内 `.gitignore` 排除，**不入库**。
- 部署类目录必须自带 `README.md`，写明前置条件、验证方式、回滚方式。
