# x-cmd install

为 [`x install`](https://x-cmd.com) 和 `x eget` 提供数据的精选软件包索引。每个条目是一个小的 YAML 文件，声明某个工具在主流 OS / 包管理器上的安装规则。

> 📦 浏览 [`src/`](src) 下 70+ 分类、2,350+ 个包
> 🚀 每日重建的产物（TSV + tar.xz）发布到 [`v1.0.0`](../../releases/tag/v1.0.0) GitHub Release —— consumer 从那里拉，**不**从 main 拉

---

## 如何新增一个包

1. **选分类**：在 `src/` 下找合适的目录（分类习惯看每个子目录里现有 yml —— 它们就是模板）。
2. **创建 `src/<category>/<your-tool>.yml`**，最小示例：

   ```yaml
   lang: Rust
   homepage: https://github.com/owner/repo
   license: MIT

   desc:
     cn: 一行中文描述
     en: One-line English description

   rule:
     /eget:
       cmd: x eget owner/repo
       reference: https://github.com/owner/repo
     darwin/brew:
       cmd: brew install repo
       reference: https://formulae.brew.sh/formula/repo
     /cargo:
       cmd: cargo install repo
       reference: https://crates.io/crates/repo
       dsnap: repo

   binlist:
     - repo
   ```

3. **本地校验**：

   ```bash
   x ws lint src/<category>/<your-tool>.yml   # schema + URL 检查
   x ws check                                  # 命名冲突扫描
   x eget resolve owner/repo                   # 验证 /eget 规则
   ```

4. **提 PR**。CI 跑同样 lint；规则坏了或字段缺失会在 review 里被标出。

完整字段（多规则语法、语言包管理器 `dsnap`、可选 `binlist` 等）看 `src/<category>/` 下现有的 yml —— 每种支持的写法都有示例。

---

## 质量门槛

包索引的价值取决于它列出的包的质量。我们对这份索引有严格要求，上游项目符合以下**任一条件**的提交会被**非常慎重考虑**（甚至拒绝）：

- 维护时间**不足 1 个月**
- 最近 1 个月内**无活跃开发**（commit、release、有意义的 issue / PR 活动）

提交前自查：

- **commit 历史** —— GitHub Insights → Contributors
- **release 节奏** —— Releases tab 上最近的 release 日期
- **issue / PR 响应** —— 维护者还在回应吗？

理由：死掉的、被遗弃的、从未正式发布的项目会让索引腐烂，浪费用户的安装时间，还带来安全风险。一个成熟的安装条目，应该远远活过它的第一次 commit。

如果你认为某条提交值得破例（比如安全关键工具、solo 维护者短期静默），请在 PR 描述里说明为什么应该收录，即使触发了上面的 flag。

---

## 仓库结构

```
x-cmd-install/
├── src/                # 包索引（每个包一个 yml）
├── docs/               # schema + 分类参考
├── .github/workflows/  # build-data.yml —— 每日重建
├── LICENSE             # Apache 2.0
└── README.md           # 英文 README
```

`v0.1.0` 分支是旧状态的冻结快照（保留供历史回溯），不再更新。

---

## 格式版本

`all.tsv` / `all.tar.xz` 是和 consumer 的**契约**。改它们——加列、删列、改列名、改转义规则、改内嵌 `rule:` JSON 结构——就是 breaking change。本节讲处理这种变更的协议。

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

1. **写 `.x-cmd/v2.yml2tsv.py`**——照 v1 的结构，新 schema。每个格式独立一个脚本，workflow 按文件名挑。
2. **改 `.format-versions-supported`**——在末尾加 `2`。文件现在内容是：
   ```
   1
   2
   ```
   意思是：v1 永远打包；从这个 commit 起，v2 也开始打包。
3. **改 `.format-version`**——设为 `2`。这是"当前 / 最新"的格式。
4. **提 PR**。workflow 重建两种格式，上传到同一个 release `x-cmd install data`（tag `data`）。
5. **更新 README**——在本节记下新格式，让未来贡献者知道。

merge 之后，release 就有 `v1.all.tsv` + `v1.all.tar.xz` + `v2.all.tsv` + `v2.all.tar.xz`。用 v1 的 consumer 不受影响；想用 v2 的抓新资产。

### 永远不变的东西

- **`src/` 下 yml schema** —— 输入是独立的稳定契约；改的是输出格式。
- **release 名 + tag** —— `x-cmd install data` on tag `data`。tag 创建一次再也不动。
- **`v0.1.0` branch** —— 历史快照，冻结。

### 老格式的命运

老格式版本**冻结，不补 patch**。如果 v1 输出有 bug，修在 v2 里——v1 保持原样。这正是版本边界存在的意义：让 consumer 有一个干净的、可选的升级路径，不会突然爆掉。

---

## 协议

Apache 2.0。详见 [LICENSE](LICENSE)。