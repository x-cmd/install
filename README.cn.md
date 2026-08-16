# x-cmd install

为 [`x install`](https://x-cmd.com) 和 `x eget` 提供数据的精选软件包索引。每个条目是一个小的 YAML 文件，声明某个工具在主流 OS / 包管理器上的安装规则。

> 📦 浏览 [`src/`](src) 下 70+ 分类、2,350+ 个包
> 🚀 每日重建的产物（TSV + tar.xz）以 **不可变的 `vYYYYMMDD` GitHub Release** 形式发布 —— 每天 UTC 12:00（= 北京时间 20:00）一个。consumer 从最新的 release（标记为 "Latest"）拉，**不**从 main 拉。
> 🧪 **`dev` release** 在每次手动触发 "Release dev data" workflow 时覆盖更新 —— 测试用的移动靶。标记为 "Pre-release"，不会抢每日 `Latest`。
>
> Actions tab 里两个按钮：
> - **Release today** —— 每日 cron + 手动；创建/替换 `v<YYYYMMDD>`（标 Latest）。
> - **Update dev release** —— 仅手动；替换 `dev` release 资产（Pre-release）。

---

## 贡献

想新增包、修错 URL、改翻译？完整流程、yml 模板、质量门槛、PR 流程都在 **[CONTRIBUTING.cn.md](CONTRIBUTING.cn.md)**。

提 PR 前快速自查：上游项目必须有 **1 个月以上维护** 且 **最近 1 个月内活跃开发**。详见 CONTRIBUTING.cn.md → "质量门槛"。

英文版 **[CONTRIBUTING.md](CONTRIBUTING.md)**。

### 快速 prompt

复制这段、填好 `<name>` 和 `<owner/repo>`、贴给你的 AI 编程助手 —— 它会替你把整套贡献跑完。

```text
我想给 x-cmd install 索引新增一个包。

工具名:        <name>
上游仓库:      https://github.com/<owner/repo>

请:
1. **动手之前**：**完整**读 CONTRIBUTING.cn.md 和 README.md —— 它
   们是本仓库的唯一权威。不要跳过阅读；质量门槛、PR 标题约定、
   格式版本规则由 reviewer 强制执行。
2. 在 src/ 下选合适的分类（参考附近文件夹里的现有 yml 当模板，
   风格对齐）。
3. 写 src/<category>/<name>.yml，至少包含：
     - lang
     - homepage
     - desc.cn / desc.en（各一行）
     - rule 里 /eget 指向 <owner/repo>
       （顺便补上你能在项目文档里找到的 apt/brew/cargo/pip 规则）
4. 本地校验:
     x ws lint src/<category>/<name>.yml
     x ws check
     x eget resolve <owner/repo>
5. 新开一个分支，commit + push，然后提 PR，标题写
   `add <name>`。
6. 停下来等我 review diff 后再 merge。

注意：上游项目必须有 1 个月以上维护 且 最近 1 个月内有活跃开发。
不满足的话在 PR 描述里写明破例理由。
```

---

## 仓库结构

```
x-cmd-install/
├── src/                # 包索引（每个包一个 yml）
├── .x-cmd/             # 每格式转换脚本（v1.yml2tsv.py, ...）
├── .github/workflows/  # build-data.yml —— 每日重建
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
- **`dev` release** —— 一个持续存在的 release，资产在每次手动触发 workflow 时被替换。标记为 "Pre-release"，不会覆盖 Latest。
- **`v0.1.0` branch** —— 历史快照，冻结。

### 老格式的命运

老格式版本**冻结，不补 patch**。如果 v1 输出有 bug，修在 v2 里——v1 保持原样。这正是版本边界存在的意义：让 consumer 有一个干净的、可选的升级路径，不会突然爆掉。

---

## FAQ

### 我想给 `x install` 贡献代码，去哪个仓库？

本仓库存的是**数据**——每个包的 yml install 规则。`x install` 模块本身的代码在 [`x-cmd/x-cmd`](https://github.com/x-cmd/x-cmd)，PR 请提交到那里。

模块文档：<https://x-cmd.com/mod/install>。

### 怎么消费这份包索引？

从 GitHub Releases 拉最新 release 的资产：
```bash
curl -L -o all.tsv   https://github.com/x-cmd/install/releases/latest/download/v1.all.tsv
curl -L -o all.tar.xz https://github.com/x-cmd/install/releases/latest/download/v1.all.tar.xz
```
`all.tsv` 是索引；`all.tar.xz` 把索引 + 完整 `src/` yml 树打包在一起。

### `v<YYYYMMDD>` 和 `dev` 两个 release 有什么区别？

- `v<YYYYMMDD>` —— 每日不可变快照，标 "Latest"。UTC 12:00（北京时间 20:00）+ 手动触发创建；数据完全一致的日子跳过（不打新 tag）。
- `dev` —— 替换式 Pre-release，每次跑 "Update dev release" workflow 都会覆盖。

要稳定数据 → 用最新 `v<YYYYMMDD>`。要测下一个 build → 用 `dev`。

---

## 协议

Apache 2.0。详见 [LICENSE](LICENSE)。