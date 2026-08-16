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
我想给 x-cmd install 索引新增一个包。

工具名:        <name>
上游仓库:      https://github.com/<owner/repo>

动手之前先做:
  1. 完整读 CONTRIBUTING.cn.md —— 它是唯一权威。
  2. 完整读 README.md —— 了解仓库上下文和格式版本协议。
  3. 翻几个 src/<某个分类>/ 下的现有 yml，学习本仓风格和惯例。

然后:
  4. 在 src/ 下选合适的分类。
  5. 写 src/<category>/<name>.yml，至少包含:
       - lang
       - homepage
       - desc.cn / desc.en（各一行）
       - rule 里 /eget 指向 <owner/repo>
         （顺便补上你能在项目文档里找到的 apt/brew/cargo/pip 规则）
  6. 本地校验:
       x ws lint src/<category>/<name>.yml
       x ws check
       x eget resolve <owner/repo>
  7. 新开一个分支，commit + push，然后提 PR，标题写
     `add <name>`。
  8. 停下来，等我 review diff 后再 merge。

质量门槛（来自 CONTRIBUTING.cn.md）：上游项目必须有 1 个月以上维护
且最近 1 个月内有活跃开发。不满足的话在 PR 描述里写明破例理由。
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

上游项目符合以下**任一条件**的提交会被**非常慎重考虑**（可能拒绝）：

- 维护时间**不足 1 个月**
- 最近 1 个月内**无活跃开发**（commit、release、有意义的 issue / PR 活动）

提交前自查：

- GitHub Insights → Contributors（commit 历史）
- Releases tab（最近 release 日期）
- 最近 issue / PR 活动（维护者还在响应吗？）

如果你认为值得破例（安全关键工具、solo 维护者短期静默），在 PR 描述里说明。

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