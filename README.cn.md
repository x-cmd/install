# x-cmd install

先把三层关系讲清楚：

1. **[x-cmd](https://x-cmd.com)** —— POSIX shell 工具集，主体。你装的是它。
2. **`x install`** / **`x eget`** —— x-cmd 里面的两个命令，作用是"我要装工具 X，怎么装？"。`x install` 选最优安装规则，`x eget` 从 GitHub Release 拉预编译二进制。文档见 [`x-cmd.com/mod/install`](https://x-cmd.com/mod/install) 和 [`x-cmd.com/mod/eget`](https://x-cmd.com/mod/eget)。
3. **本仓库（`x-cmd-install/install`）** —— 上面两个命令读的**数据**。不是代码，不是模块，只是精选的 YAML 索引：2,350+ 个工具，每个工具在每个 OS / 包管理器上的安装规则。

一句话：x-cmd 是脑子，本仓是查表。

> 📦 2,350+ 个包，70+ 分类，全在 [`src/`](src) 下。
> 🚀 每日重建的产物（TSV + tar.xz）以 **不可变的 `vYYYYMMDD` GitHub Release** 形式发布 —— UTC 12:00（= 北京时间 20:00）。consumer 从最新的 release（标记为 "Latest"）拉，**不**从 main 拉。

---

## 贡献

想新增包、修错 URL、改翻译？完整流程、yml 模板、质量门槛都在 **[CONTRIBUTING.cn.md](CONTRIBUTING.cn.md)**。

提 PR 前快速自查：上游项目必须有 **1 个月以上维护** 且 **最近 1 个月内活跃开发**。详见 CONTRIBUTING.cn.md → "质量门槛"。

英文版 **[CONTRIBUTING.md](CONTRIBUTING.md)**。

### 快速 prompt

复制下面这段，把工具的 GitHub 地址（或者官网文档地址）贴到后面，交给你的 AI 助手。

```text
参考 https://github.com/x-cmd/install/blob/main/CONTRIBUTING.cn.md ，并向 x-cmd/install 仓库提交新软件：
```

---

## 仓库结构

```
x-cmd-install/
├── src/                # 包索引（每个包一个 yml）
├── .x-cmd/             # 每格式转换脚本（v1.yml2tsv.py, ...）
├── .github/workflows/  # release-today.yml + update-dev-release.yml
├── CONTRIBUTING.md     # 贡献指南（英文）
├── CONTRIBUTING.cn.md  # 贡献指南（中文）
├── LICENSE             # Apache 2.0
└── README.md           # 英文 README
```

`v0.1.0` 分支是旧状态的冻结快照（保留供历史回溯），不再更新。

---

## 格式版本

流水线输出**带版本的契约**——`v1.all.tsv` / `v1.all.tar.xz` 是 v1 的契约；`v2.all.tsv` / `v2.all.tar.xz` 是 v2 的。每个版本发布后独立冻结。

breaking change 不改老版本，而是发新版本（v2、v3、...）。老版本永远继续打包、不动，所以用老版本的 consumer 不会爆。本节讲这个流程。

整套流水线按 **多格式持续打包** 来设计：每个发布过的格式版本都会**永远**被每天重建并上传，新旧并存。新格式加进来；老格式再也不改。

### 什么时候必须升版本

| 改动 | 升版本？ |
|---|---|
| TSV 加列 | 升（新 major format） |
| 列改名 / 删列 | 升 |
| TSV 转义规则变 | 升 |
| 内嵌 `rule:` JSON 结构变 | 升 |
| `rule:` JSON 内加新的可选字段 | **不升**（format 内向后兼容） |
| 批量改 `binlist` / `desc.cn` 内容 | **不升**（只是数据） |
| 改 `src/` 下的 yml schema | 升（输入 schema 自己也是契约） |

### 怎么发布新格式（比如 `v2`）

1. **写 `.x-cmd/v2.yml2tsv.py`**——照 v1 的结构，新 schema。每个格式独立一个脚本。
2. **提 PR**。完事。workflow 每次跑都 glob `.x-cmd/v*.yml2tsv.py`，自动挑到 v2，跟 v1 的资产一起上传。
3. **更新本节 README**——让未来贡献者知道 v2 存在。

merge 之后，release 就有 `v1.all.tsv` + `v1.all.tar.xz` + `v2.all.tsv` + `v2.all.tar.xz`。用 v1 的 consumer 不受影响；想用 v2 的抓新资产。

### 永远不变的东西

- **`src/` 下 yml schema** —— 输入是独立的稳定契约；改的是输出格式。
- **release 模式** —— 每个 UTC 日一个不可变 release，命名 `v<YYYYMMDD>`，UTC 12:00 构建（= 北京时间 20:00）。每个 release 创建一次，永不修改。最近的 release 标记为 "Latest"。
- **`v0.1.0` branch** —— 历史快照，冻结。

### 老格式的命运

老格式版本**冻结，不补 patch**。如果 v1 输出有 bug，修在 v2 里——v1 保持原样。这正是版本边界存在的意义：让 consumer 有一个干净的、可选的升级路径，不会突然爆掉。

---

## FAQ

### 我想给 `x install` 或 `x eget` 贡献代码，去哪个仓库？

本仓库存的是**数据**——yml install 规则。`x install` / `x eget` 模块本身的代码在 [`x-cmd/x-cmd`](https://github.com/x-cmd/x-cmd)，PR 请提交到那里。

模块文档：
- `x install` → <https://x-cmd.com/mod/install>
- `x eget`  → <https://x-cmd.com/mod/eget>

### 怎么消费这份包索引？

从 GitHub Releases 拉最新 release 的资产：
```bash
curl -L -o all.tsv    https://github.com/x-cmd/install/releases/latest/download/v1.all.tsv
curl -L -o all.tar.xz https://github.com/x-cmd/install/releases/latest/download/v1.all.tar.xz
```
`all.tsv` 是索引；`all.tar.xz` 把索引 + 完整 `src/` yml 树打包在一起。

### 两个 release 通道有什么区别？

Actions tab 里两个按钮：

- **Release today** —— 每日 cron（UTC 12:00 = 北京时间 20:00）+ 手动；创建/替换 `v<YYYYMMDD>`（标 "Latest"）。数据完全一致的日子跳过（不打新 tag）。
- **Update dev release** —— 仅手动；替换 `dev` release 资产（标 "Pre-release"，不会覆盖 Latest）。

要稳定数据 → 用最新 `v<YYYYMMDD>`。要测下一个 build → 用 `dev`。

---

## 协议

Apache 2.0。详见 [LICENSE](LICENSE)。