# FAQ

> 用户向 FAQ（去哪贡献 / 怎么消费 / 两个 release 区别）见 [README.md](README.md) → "FAQ"。
>
> 本文档面向**维护者**——设计理由、运维细节、理念。消费者通常不用看。

---

## 格式版本

> 设计理由（每个 `x install` 版本绑一种格式、所有格式每天用最新数据重建）见 [README.md](README.md) → "格式版本"。本节是**运维**那一侧。

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

原则：会让 consumer 不得不重新解析的就是 bump；只加数据的不算。

### 怎么发新格式（比如 `v2`）

1. **写 `.x-cmd/v2.yml2tsv.py`** —— 照 v1 的结构，新 schema。每个格式独立一个脚本。
2. **提 PR**。完事。workflow 每次跑都 glob `.x-cmd/v*.yml2tsv.py`，自动挑到 `v2`，跟 v1 的资产一起上传。
3. **更新 README "格式版本" 节** —— 让未来贡献者知道 `v2` 存在。

merge 之后 release 就有 `v1.all.tsv` + `v1.all.tar.xz` + `v2.all.tsv` + `v2.all.tar.xz`。v1 consumer 不受影响；v2 consumer 抓新资产。

### 永远不变的东西

- **`src/` 下 yml schema** —— 输入是独立的稳定契约；改的是输出格式。
- **release 模式** —— 每个 UTC 日一个不可变 release，命名 `v<YYYYMMDD>`，UTC 12:00 构建（= 北京时间 20:00）。
- **`v0.1.0` branch** —— 历史快照，冻结。

### 老格式的命运

老格式版本**冻结，不补 patch**。如果 v1 输出有 bug，修在 v2 里 —— v1 保持原样。这正是版本边界存在的意义：让 consumer 有一个干净的、可选的升级路径，不会突然爆掉。

---

## Design

### 为什么是两个 workflow（release-today + update-dev-release），不是一个？

试过单 workflow + 条件分支，一个按钮里挑 daily 还是 dev。但这把"发今日快照"和"刷 dev release"两个完全不同的意图混在一个按钮里，Actions tab 一眼看不出哪个是哪个。拆开后：每个意图有自己的按钮、历史、失败面。

### 为什么 `v1.yml2tsv.py` 输出按 `(category, name)` 排序？

`as_completed()` 按完成顺序返回 future，同样输入两次 build 会得到字节不同的 TSV（行序随机）。这会让每日"未变更就跳过"检测永远命中"differs"→ 永远上传。排序后输出字节稳定，`diff` 才抓得到真实变化。

### 为什么格式版本冻结，不补 patch？

格式版本是跟 consumer（`x install` / `x eget`）的**契约**。改 v1 的输出修 bug 会打爆所有已经解析 v1 输出的 consumer。版本边界的存在意义：consumer 要么永远停在 v1，要么升级到 v2。冻结就冻结——合法的 bug 修复也放进下一个版本。

### 为什么每个 UTC 日一个不可变 release（`v<YYYYMMDD>`）、12:00 UTC？

- **每天一个** —— 人类可读的 tag（`v20260817`）同时是 release 指针；`git clone --branch v20260817 --depth=1` 拿到那天的快照。
- **不可变** —— 每天的数据就是当天的数据；如果新 commit 误推了脏输出，修就用新 release（`v20260817a`），不要原地编辑。
- **12:00 UTC = 20:00 北京时间** —— 非西方工作时间，流量低，给晚到的 PR 时间落入当天的 build。
- **未变更就跳过** —— workflow 比对 `v<YESTERDAY>` 的 `v1.all.tsv` 和今天的 build，全一致就不打新 tag。避免 tag 列表被空副本塞满。

### 为什么 `dev` 是替换式 pre-release？

`dev` 是给开发用的移动靶——开发者想拿 main 之上的新 build 就跑一下 `Update dev release`。它不能抢每日 release 的 "Latest"，所以标 Pre-release。资产可覆盖——`dev` 的 consumer 本来就要重新拉。

### 为什么 `release-data` 是 composite action 而不是内联 workflow 步骤？

build + upload 逻辑被 daily 和 dev 两个 workflow 共享。内联会复制 ~50 行；composite action（`.github/actions/release-data/action.yml`）让它只活在一个地方，加新 release 通道（比如 `rc`）也只是 workflow 里调一行。yml 脚本放 `.x-cmd/` 也是同个理由。

---

## Operations

### 怎么手动触发每个 workflow？

| 意图 | workflow | 按钮 | 行为 |
|---|---|---|---|
| 重打今日 daily release | `release-today.yml` | "Release today" | 创建/替换 `v<TODAY>`（与昨天完全一致则跳过） |
| 刷新 dev release | `update-dev-release.yml` | "Update dev release" | 覆盖 `dev` 资产 |

都自动触发的话：`release-today` 由 cron 12:00 UTC 触发；`update-dev-release` 仅手动。

### skip-if-unchanged 检测具体怎么走？

`release-today.yml` 把 `if_changed_since: v<YESTERDAY>` 传给 `release-data`。action：
1. build 所有 `v*.all.tsv`
2. `gh release download v<YESTERDAY> --pattern "v*.all.tsv"` 拉到 /tmp
3. `diff -q` 今天的每个 `v<N>.all.tsv` 和参考
4. **全部**一致（或参考不存在）→ `exit 0`，upload 步骤跳过，不打新 tag
5. 任何一个不同（或新增了格式）→ 上传今天的完整集

参考不存在视为"changed"——首次运行、或 cron 断了一段时间，都应该产 release。

### 每日 cron 挂了怎么办？

cron 是 `0 12 * * *`。失败在 Actions 里显示红 run。常见原因：
- `yq` 下载 URL 变了 → 改 `release-data/action.yml` 里的 `wget` URL
- 新 yml 文件语法错 → 修 yml，手动重跑 `release-today`
- release-data action 有 bug → 修完 push，手动重跑

失败的 run **不会**留下半成品 release —— softprops upload 是最后一步，挂了就没东西要清。

### 怎么发新格式版本（`v2`）？

看 README → "格式版本 → 怎么发布新格式"。摘要：落 `.x-cmd/v2.yml2tsv.py`，改 `.format-versions-supported`（这个文件后来删了，现在 workflow 自动 glob `v*.yml2tsv.py`），改 `.format-version` 为 `2`，提 PR。下次跑 workflow 自动挑到 `v2`，不用其它配置。

### `x-cmd-install/x-cmd-install`（mneme）这个仓库是干嘛的？

本项目的**内部归档**——设计草稿、运营笔记、vendor 源码、eget 算法草稿。不对外。本仓做对外公开的工作；内部 / 战略思考留在 mneme。边界防止内部 R&D 泄漏到面向消费者的产物里。

### 为什么 PR 上还没加 CI lint？

计划在 [issue #2](https://github.com/x-cmd/install/issues/2)（`Add eget rule linting for /eget entries in src/ yml`）。先搁置——现在 PR 都是人工 review，量也撑得住。等贡献量大了再加 CI 任务。

---

## Philosophy

### 为什么不用 stars（或其它人气指标）过滤？

我个人手审过 2000+ 条 install，规律很清楚：很多最好的工具 star 很少。要么是小众 / 基础设施（没人想到去 star），要么是埋头干活的维护者不营销自己。

举个真实例子：[`ProtonMail/gosop`](https://github.com/ProtonMail/gosop) —— 一个专业的 Go SMTP/IMAP 代理。当初次我引入时，如果没记错是 28 个 stars。今天大概是 50。按任何 stars 过滤都会被筛掉；按维护信号（持续开发、维护者响应、名实相符）轻松通过。

所以本索引不按 stars 过滤。stars 衡量的是营销覆盖和已有受众，不是工具好不好用。按 stars 过滤的索引会偏向"已经火"的工具，错过真正用得上的。我们按"有没有用"策展，不按"火不火"策展。50 star 但用心良作的工具，比 10k star 的套壳工具更受欢迎。

---

### 为什么这仓有 78 个 `[REC]` issue？

是从 `x-cmd/x-cmd` 一批搬过来的——x-cmd monorepo 里 `[REC]` label 历史上是"install recipe request"（每个工具一条 issue）。早就该拆：install 元数据是 data 不是模块代码，公开仓才是该待的地方。迁移用 `gh issue transfer`，状态保留（open + closed 都搬了）。

### 为什么 release 名这么朴素（`v20260816` 而不是 `v20260816 — x-cmd install data`）？

tag 和 release 名现在 1:1。原因是 `— x-cmd install data` 后缀冗余——本仓每个 release 都是 x-cmd install data。砍掉后 Releases 页好扫（一眼能从标题里拣出日期），也避免项目改名后忘了更新后缀导致漂移。

### 为什么本仓是纯 metadata？

`x install` / `x eget` 本身的**代码**在 [`x-cmd/x-cmd`](https://github.com/x-cmd/x-cmd)。install 索引是**数据**——一个包一个 yml。数据和代码分开：
- 社区 PR 只需对照清楚的 schema（yml）审，不用 rebuild x-cmd
- 每日 rebuild 改 2,350+ yml 不碰模块
- consumer 直接拉数据，不用 clone 整个模块

### 为什么没有 PR / issue 模板？

模板会偏向模板作者的"好贡献"想象。对一个"大部分 PR 都是给工具 X 加一条 yml"的索引来说，模板加摩擦但不加信号。PR 标题约定（`add <name>`、`fix broken homepage for <pkg>`）写进 CONTRIBUTING.md 就够了。