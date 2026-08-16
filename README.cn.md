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

## 协议

Apache 2.0。详见 [LICENSE](LICENSE)。