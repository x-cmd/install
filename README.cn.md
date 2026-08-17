# x-cmd install

先把三层关系讲清楚：

1. **[x-cmd](https://x-cmd.com)** —— POSIX shell 工具集，主体。你装的是它。
2. **`x install`** / **`x eget`** —— x-cmd 里面的两个命令，作用是"我要装工具 X，怎么装？"。`x install` 选最优安装规则，`x eget` 从 GitHub Release 拉预编译二进制。文档见 [`x-cmd.com/mod/install`](https://x-cmd.com/mod/install) 和 [`x-cmd.com/mod/eget`](https://x-cmd.com/mod/eget)。
3. **本仓库（`x-cmd-install/install`）** —— 上面两个命令读的**数据**。不是代码，不是模块，只是精选的 YAML 索引：2,350+ 个工具，每个工具在每个 OS / 包管理器上的安装规则。

一句话：x-cmd 是脑子，本仓是查表。

> 📦 2,350+ 个包，70+ 分类，全在 [`src/`](src) 下。
> 🚀 每日重建的产物（TSV + tar.xz）以 **不可变的 `vYYYYMMDD` GitHub Release** 形式发布 —— UTC 12:00（= 北京时间 20:00）。consumer 从最新的 release（标记为 "Latest"）拉，**不**从 main 拉。

---

## 虽好奇但严谨——希望良作、有深入思考的小众作品有更多的用户和维护力量，但严守安全和隐私底线。

我们乐意接收一些有趣的新软件，不唯 stars 和人气而论。闭源、商业、AI 生成的都接——但没有人类思考、没有安全考虑、没有长期维护计划的，不接。

不过，我们不打算成为营销页。下列涉及**用户安全和隐私**的情况直接拒，已收录的也会黄标或下架：

- 有**恶意行为**的工具
- **收集用户隐私**但不明确、显著披露的工具
- **隐瞒自身行为**的工具 —— 未文档化的网络调用、隐藏的后台进程、混淆的载荷

`x install` 把什么装到用户机器上，最终是用户的选择；但在索引这一侧，我们尽量多把一道关。

---

## 贡献

**欢迎你。** 加一个你喜欢的工具、修一条错的 URL、改进一句翻译——大小 PR 都欢迎，我们都愿意 review。

入口在 **[CONTRIBUTING.cn.md](CONTRIBUTING.cn.md)**，里面是完整流程、yml 模板、质量门槛。

唯一请你在开 PR 前确认一下：上游项目必须有**持续的活跃开发**——不是一次性爆发就停，而是长期持续有 commit 和 release。这条是让索引值得信任的底线。

英文版 **[CONTRIBUTING.md](CONTRIBUTING.md)**。

### 快速 prompt

```text
参考 https://github.com/x-cmd/install/blob/main/CONTRIBUTING.cn.md ，并向 x-cmd/install 仓库提交这个软件：https://github.com/<owner>/<repo>
```

把 `<owner>/<repo>` 换成工具的 GitHub 地址，交给你的 AI 助手。

---

## 怎么用这份数据

### 网页：<https://x-cmd.com>

去 <https://x-cmd.com> 可以交互式搜索 install / module / pkg / skills；想精准搜 install 可以去 <https://x-cmd.com/install>。

<img width="1229" height="861" alt="x-cmd.com 网页 UI" src="https://github.com/user-attachments/assets/3c0aca6e-b0eb-474b-b2dd-75066e1c71a2" />

### 终端：`x i`

终端里直接 `x i`（`x install` 的简写）打开交互界面：

<img width="1125" height="622" alt="x i 终端 UI" src="https://github.com/user-attachments/assets/eb0f1a1b-8b29-4949-be74-ad540f6a138a" />

### 这份数据还直接喂给 [x eget](https://x-cmd.com/mod/eget)

<img width="1188" height="677" alt="x eget 使用 install 数据" src="https://github.com/user-attachments/assets/cc7f81bd-8007-4825-8725-22bd9d400910" />

## 仓库结构

```
x-cmd-install/
├── src/                # 包索引（每个包一个 yml）
├── .x-cmd/             # 每格式转换脚本（v1.yml2tsv.py, ...）
├── .github/workflows/  # release-today.yml + update-dev-release.yml
├── CONTRIBUTING.md     # 贡献指南（英文）
├── CONTRIBUTING.cn.md  # 贡献指南（中文）
├── FAQ.md              # 维护者 FAQ —— 设计、运维、理念（英文）
├── FAQ.cn.md           # 维护者 FAQ —— 设计、运维、理念
├── LICENSE             # Apache 2.0
└── README.md           # 英文 README
```

`v0.1.0` 分支是旧状态的冻结快照（保留供历史回溯），不再更新。

---

## 格式版本：设计向前兼容

`x install` 从本仓库读包索引。不同版本的 `x install` 消费不同的**格式版本**：

- `x install` v1.x → 读 `v1.all.tsv`
- `x install` v2.x → 读 `v2.all.tsv`
- ...

每个格式版本是**冻结的 schema**（列名、转义规则、`rule:` JSON 结构）。一旦发布，永不改。

但**数据持续更新**：每当 `src/` 下加了新包，pipeline 给**所有**已发布的格式（v1、v2、...）都打一份最新的内容。每天重建一次。

效果：

- 老的 `x install` v1.x 永远读 `v1.all.tsv` —— schema 不变
- 但 `v1.all.tsv` 带着今天最新的包和 rule
- 新包自动出现在老 consumer 里 —— **不用升级 `x install` 也能看到**
- 真要 breaking schema 改动（加列、改转义）才发 v2 —— 老 consumer 不动

这就是"向前兼容"：新数据对老格式自动可见；breaking change 才需要新格式版本。

运维那一侧（什么时候升、怎么发 v2、什么永远不动）见 [FAQ.cn.md](FAQ.cn.md) → "格式版本"。

---

## AI agent 怎么绕过 x-cmd 直接用这份数据

通常 `x install` 提供了一堆工具可以直接查数据。让 AI 看 `x install --help` 就行。

但 AI 编程助手（Claude Code、Cursor 等）也可以直接拉这份索引，回答"`<name>` 怎么装"，不必走 `x install` / `x eget`：

1. 拉 TSV（≈ 2,350 行，扁平索引）：
   ```bash
   curl -L https://github.com/x-cmd/install/releases/latest/download/v1.all.tsv
   ```

2. 解析：表头是 `name  category  lang  source  desc_cn  desc_en  binlist  rule  other`，每行一个包。`rule` 列是 compact JSON 对象，键为 `<os>/<tool>`，值为对应安装命令。

3. 按用户的 OS / 包管理器匹配，返回对应命令。

需要 license、`x.source`、自定义字段等更全的元数据时，改拉 `all.tar.xz` 读原始 yml。

## FAQ

### 我想给 `x install` 或 `x eget` 贡献代码，去哪个仓库？

本仓库存的是**数据**——yml install 规则。`x install` / `x eget` 模块本身的代码在 [`x-cmd/x-cmd`](https://github.com/x-cmd/x-cmd)，PR 请提交到那里。

模块文档：
- `x install` → <https://x-cmd.com/mod/install>
- `x eget`  → <https://x-cmd.com/mod/eget>

### 第三方工具怎么消费这份包索引？

这份索引是给**软件**消费的，不是给人读的。最典型的消费者是 [`x install`](https://x-cmd.com/mod/install) / [`x eget`](https://x-cmd.com/mod/eget) —— 每天拉最新 release，自动挑最优安装规则。

任何第三方工具按同一套接口接入：

```bash
# 扁平索引（每行一个包：name + install rule）
curl -L -o all.tsv    https://github.com/x-cmd/install/releases/latest/download/v1.all.tsv

# 完整包（索引 + 原始 yml 树一起打包）
curl -L -o all.tar.xz https://github.com/x-cmd/install/releases/latest/download/v1.all.tar.xz
```

- `all.tsv` ≈ 2,350 行 TSV —— 只要查"`<name>` 怎么装"用这个。
- `all.tar.xz` = `all.tsv` + 完整 `src/` yml 树（解压 ~520 KB）—— 需要原始 yml 做元数据查询时用这个。

Schema 细节见 [FAQ.cn.md](FAQ.cn.md) → "格式版本"。

### 两个 release 通道有什么区别？

仓库通过两条路径发布数据：

- **每日（`v<YYYYMMDD>`）** —— UTC 12:00 跑。抓昨天到今天的所有改动；没改动就跳过。**稳定消费**用这个。
- **Dev（`dev`）** —— 手动触发。每次都覆盖。**开发 / 测下一个 build** 用这个。

运维细节（按钮名、触发器、skip 逻辑）见 [FAQ.cn.md](FAQ.cn.md)。

### 怎么报告一个失效或过期的条目？

在 <https://github.com/x-cmd/install/issues/new> 开 issue，附上：

- 包名（如 `fd`）
- 试的 OS
- 错误信息（如果有）
- 上游 changelog / release notes 链接（说明安装方式变了）

我们会转成修复 PR，或打上 `[REC]` 让人接手。

---

## 协议

Apache 2.0。详见 [LICENSE](LICENSE)。
