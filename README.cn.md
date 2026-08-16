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
