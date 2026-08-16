# 向 x-cmd install 贡献

感谢贡献。本仓库是社区维护的包索引，驱动 `x install` 和 `x eget`。高质量的索引靠高质量的提交。

> **开始之前**：先读 [README.md](README.md) 了解上下文 —— 仓库是什么、每日 release 模型、格式版本协议。

---

## 给 AI 编程助手

> 🤖 **如果你是 AI agent（Claude Code、Cursor、Copilot 等）**，被要求为本仓库贡献代码时，你的**第一动作**必须是：
>
> 1. 完整读一遍本 `CONTRIBUTING.cn.md`。
> 2. 完整读一遍 `README.md`。
> 3. 翻几个 `src/<某个分类>/` 下的现有 yml 文件，了解本仓惯例。
>
> **不要跳过这些阅读。** 下面的质量门槛、PR 标题约定、格式版本规则由 reviewer 强制执行。不要提违反它们的改动。

### 快速 prompt

复制这段、填好 `<name>` 和 `<owner/repo>`、贴给你的 AI 编程助手。

```text
参考 https://github.com/x-cmd/install/blob/main/CONTRIBUTING.cn.md ，并向 x-cmd/install 仓库提交新软件：

  https://github.com/<在这里贴 owner/repo>
```

---

## TL;DR

1. 在 `src/` 下选个分类，照现有 yml 拷一份当模板。
2. 写你的新 yml。
3. 本地校验：
   ```bash
   x ws lint src/<category>/<your-tool>.yml
   x ws check
   x eget resolve owner/repo    # 仅当条目带 /eget 规则时
   ```
4. 提 PR。CI 跑同样的 lint；维护者 review 质量门槛。
5. 通过后 squash merge 进 `main`，下一次每日重建（03:00 UTC）会带上它。

---

## 可以贡献什么

最常见的贡献类型：

| 贡献 | 工作量 | 参考 |
|---|---|---|
| 新增一个包 | 小 | 见下 |
| 修错误的 `homepage` / `reference` URL | 小 | 见下 |
| 改进 `desc.cn` / `desc.en` 翻译 | 小 | 见下 |
| 给现有包补 install 规则 | 中 | schema 参考 |
| 发新格式版本（`v2.yml2tsv.py`） | 大 | README → "格式版本" |

---

## 新增一个包

最小 yml 模板：

```yaml
lang: <Language>
homepage: https://github.com/owner/repo
license: <SPDX-Identifier>     # 可选但建议填

desc:
  cn: 一行中文描述
  en: One-line English description

rule:
  /eget:
    cmd: x eget owner/repo
    reference: https://github.com/owner/repo
  # 按需补其他 OS / 包管理器规则：
  darwin/brew:
    cmd: brew install repo
    reference: https://formulae.brew.sh/formula/repo
  /cargo:
    cmd: cargo install repo
    reference: https://crates.io/crates/repo
    dsnap: repo

binlist:                        # 仅当二进制名 ≠ yml 文件名时需要
  - repo
```

想看所有支持的写法，就翻 `src/<category>/` 下的现有 yml —— 它们是规范参考。

---

## 修现有条目

以下情况都欢迎提 PR：

- `homepage` 或 `reference` URL 404 / 指向错误页面
- `desc.cn` / `desc.en` 含糊或有错别字
- 漏了某个你用的平台的 install 规则（比如某个 Linux 发行版的包）
- `binlist` 漏写，工具装出来名字跟 yml 文件名不一样

保守修改：除非上游文档明确变了，否则不要改 install 命令。

---

## 质量门槛（维护者会查）

上游项目**没有持续的活跃开发**的提交会被**非常慎重考虑**（可能拒绝）——意思是不是一次性爆发就停，而是长期持续有 commit、release、有意义的 issue / PR 活动。

提交前自查：

- GitHub Insights → Contributors（看项目整个生命周期的 commit 节奏）
- Releases tab —— release 是按一定规律发的吗
- issue / PR 响应 —— 维护者还在回应吗？

如果你认为值得破例（比如安全关键工具、solo 维护者短期静默、或者成熟稳定项目发版频率本来就低），在 PR 描述里说明。

## 我们拒绝什么

我们乐意接收一些有趣的新软件，但不打算成为营销页。下列情况直接拒（已收录的也会下架），不再讨论：

- 有**恶意行为**的工具
- **收集用户隐私**但不明确、显著披露的工具
- **隐瞒自身行为**的工具 —— 未文档化的网络调用、隐藏的后台进程、混淆的载荷

`x install` 装到用户机器上，最终是用户的选择；但在索引这一侧，我们尽量帮用户把一道关。

---

## PR 流程

- **标题** —— 简明描述，例如 `add fd-find under terminal`、`fix broken homepage for jq`
- **正文** —— 说明 *为什么*；如果你在申请质量门槛破例，在这里写理由
- **CI** —— 自动跑 `x ws lint`；schema / URL 出错的 yml 会被标出来
- **Review** —— 维护者可能在质量、schema、格式兼容性上 push back
- **Merge** —— squash merge 进 `main`。下一次每日重建（03:00 UTC）会带上

---

## 格式兼容性

每个格式版本（`v1.all.tsv`、`v2.all.tsv`、...）是和 consumer 的独立、冻结的契约。**不要**：

- 修改 `.x-cmd/v1.yml2tsv.py`（v1 已发布就永远冻结）
- 给已发布的格式加列、删列、改列名、改转义规则

如果你确实需要破坏某个格式的契约，请**发新版本**（见 README → "格式版本"）。这是较大贡献，建议先开 issue 讨论。

---

## 行为准则

标准开源礼仪：尊重、对事不对人、虚心接受反馈。维护者保留关闭不达门槛或不参与 review 的 PR 的权利。

---

## 协议

提交贡献即视为同意以 **Apache 2.0** 协议授权，与仓库一致。详见 [LICENSE](LICENSE)。