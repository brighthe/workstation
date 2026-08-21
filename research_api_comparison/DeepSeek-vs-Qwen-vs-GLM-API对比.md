# DeepSeek vs 千问(Qwen) vs 智谱(GLM) API 对比调研（2026-08）

> 调研日期：2026-08-21
> 方法：三个并行子代理分别深挖官方价格页（部分经 Wayback Machine 存档核对原文），交叉比对媒体多源。
> **重要限制**：本环境 HTTPS 出站被沙箱阻断，官方页面正文大多无法直连；DeepSeek 价格经媒体转述/《财经》实测核算（多源一致），千问价格直接来自阿里云官方帮助页存档（2026-08-06），智谱价格经多语言媒体标题交叉证实。凡未能核实的数字已标注。**采购前请登录各平台官方定价页人工核对。**

---

## 0. 一句话结论

- **DeepSeek**：2026-08-17 起**大幅涨价 + 首创峰谷分时定价**（峰时最高涨 1100%），价格优势大幅收窄；但仍是最便宜的**旗舰**（V4-Pro 谷时 4.5/13.5 元）。
- **千问 Qwen**：价格**最便宜**（qwen3.5-flash 输入仅 0.2 元/百万），思考/非思考可切换，上下文 1M，**实测性价比之王**；旗舰 qwen3.7-max 输入 12 元/输出 36 元，与 DeepSeek V4-Pro 相当。
- **智谱 GLM**：GLM-5.3 与上代**同价**（$1.4/$4.4，约 10/31 元），编程能力 +50%、Agent 能力暴涨（Terminal-Bench 4.6→28.3），但**强制思考、无法关闭**，实际账单可能远超表面单价（思考 token 计入输出）。

---

## 1. 每百万 tokens 价格对比（人民币，中国区）

### 1.1 DeepSeek（2026-08-17 起，峰谷两档；旧价为 08-17 前统一价）

| 模型 | 档位 | 输入 | 输出 | 缓存命中 |
|---|---|---|---|---|
| deepseek-v4-flash | 旧价 | 1 元 | 2 元 | 0.02 元 |
| deepseek-v4-flash | 谷时 | 1.5 元 | 4.5 元 | 0.05 元 |
| deepseek-v4-flash | 峰时 | 3 元 | 9 元 | 0.10 元 |
| deepseek-v4-pro | 旧价 | 3 元 | 6 元 | 0.025 元 |
| deepseek-v4-pro | 谷时 | 4.5 元 | 13.5 元 | 0.15 元 |
| deepseek-v4-pro | 峰时 | 9 元 | 27 元 | 0.30 元 |

- **峰时段**：北京时间每天 09:00–12:00、14:00–18:00（共 7 小时）；其余 17 小时为谷时，谷价 = 峰价一半。官方未说明跨时段请求按发起还是完成时间计费。
- **最大涨幅 1100%**：V4-Pro 缓存命中价 0.025 → 峰时 0.30 元（12 倍）——媒体"涨 11 倍/12 倍"均指此项；实际账单涨幅约 2–6 倍（《财经》实测 1 亿 token 任务：V4-Pro 账单 17.5 → 谷时 50.1 / 峰时 102.2 元；V4-Flash 6.4 → 13.1 / 25.7 元）。
- **草案价矛盾**：6-29 官方预告稿（峰时 Flash 2/4 元、Pro 6/12 元）被 8-13 最终方案（3/9、9/27）取代，以 8-13 公告为准。
- deepseek-chat / deepseek-reasoner 旧别名已于 2026-07-24 停用，现用 deepseek-v4-flash（=原 chat，非思考）/ deepseek-v4-flash+thinking（=原 reasoner，**并非 Pro**）/ deepseek-v4-pro。
- 另有 2026-08-21 上线的多模态实验版 deepseek-v4-flash-vision-exp，价格与 V4-Flash 一致。

### 1.2 千问 Qwen（阿里云百炼，华北2北京，官方价格页 2026-08-06 存档）

| 模型 | 输入档位 | 输入价 | 输出价 | 备注 |
|---|---|---|---|---|
| qwen3.5-flash | 0<Token≤128K | **0.2 元** | 2 元 | Batch 半价 |
| qwen3.5-flash | 128K–256K | 0.8 元 | 8 元 | |
| qwen3.5-flash | 256K–1M | 1.2 元 | 12 元 | |
| qwen3.5-plus | 0<Token≤128K | **0.8 元** | 4.8 元 | Batch 半价；缓存命中 0.08 元（10%） |
| qwen3.5-plus | 128K–256K | 2 元 | 12 元 | |
| qwen3.5-plus | 256K–1M | 4 元 | 24 元 | |
| qwen3.7-max（旗舰） | — | **12 元** | **36 元** | 与 V4-Pro 峰时同档 |

- **注意：百炼官方价格页没有 `qwen3.5-max` / `qwen3.5-max-preview` 条目**——Qwen3.5-Max-Preview（2026-03-20 发布）只在 chat.qwen（千问 APP）上线；百炼的 Max 系列是 qwen3.7-max / qwen3.8-max（均 12/36 元）。查价格时别找 qwen3.5-max。
- 多模态 omni 系列（每百万 token）：qwen3.5-omni-plus 文本/图/视频输入 7 元、音频输入 53 元、文本输出 40 元、多模态输出 213 元；qwen3.5-omni-flash 对应 2.2 / 18 / 13.3 / 72 元。
- 上下文缓存规则（官方）：**显式缓存**创建按输入单价 **125%**、命中按 **10%**；**隐式缓存**命中按 **20%**。
- 思考/非思考模式**同价**（DeepSeek 思考模式也同价，智谱则强制思考）。
- 免费额度：每模型 100 万 Token（90 天有效，仅中国大陆版，自动发放）。
- 媒体"每百万 Token 低至 0.8 元"= qwen3.5-plus 最低档**输入价**；"0.2 元"= qwen3.5-flash 输入价。均为最低档输入价，勿按此估算总成本。

### 1.3 智谱 GLM（bigmodel.cn / Z.ai，官方 $ 计价）

| 模型 | 输入 | 输出 | 备注 |
|---|---|---|---|
| GLM-5.3 | **$1.4**（约 10 元） | **$4.4**（约 31 元） | 与 GLM-5.2 **同价**（"一分没涨"） |

- 人民币价与缓存折扣：官方页不可直读，未找到精确数字；阿里云百炼亦有 ZHIPU/GLM-5.3（人民币计费）。
- **强制思考、无档位开关**（reasoning_effort 未实现）→ 思考 token 全部计入输出，有媒体实测"未设推理档位导致费用暴涨 35 倍"的隐藏陷阱（需自行验证）。

### 1.4 横向速览（128K 内最低档输入 / 输出，元/百万）

| 模型 | 输入 | 输出 |
|---|---|---|
| qwen3.5-flash | 0.2 | 2 |
| qwen3.5-plus | 0.8 | 4.8 |
| deepseek-v4-flash（谷时） | 1.5 | 4.5 |
| deepseek-v4-flash（峰时） | 3 | 9 |
| GLM-5.3 | ≈10 | ≈31 |
| deepseek-v4-pro（谷时） | 4.5 | 13.5 |
| qwen3.7-max / deepseek-v4-pro（峰时） | 9–12 | 27–36 |

---

## 2. 上下文 / 输出 / 思考模式

| 项目 | DeepSeek V4 | 千问 Qwen3.5 | 智谱 GLM-5.3 |
|---|---|---|---|
| 上下文 | **1M**（官方） | **1M**（plus 官方，flash 支持到 1M） | 5.2 为 1M；5.3 官方数字未确认 |
| 最大输出 | 384K（转述官方页） | plus 65,536（64K）；思维链 81,920 | 未找到 |
| 思考模式 | flash 可选（thinking 参数）；与不思考同价 | **可选**（思考/非思考同价） | **强制思考，无法关闭** |
| 主要规格 | flash: MoE 284B/激活13B；pro: 1.6T/激活49B | 397B-A17B 等开源系 | 743B（后训练驱动，参数未涨） |
| 速率限制 | 账号级并发：flash **2,500** / pro **500**（无公开 RPM/TPM 表；多 key 共享） | flash RPM 30,000 / TPM 10M；plus RPM 30,000 / TPM 5M（华北2） | 未找到 |
| token 换算 | 1 中文字符 ≈ 0.6 token；1 英文字符 ≈ 0.3 token | 官方 DashScope 计价同 token 体系 | — |
| 协议 | OpenAI / Anthropic / Responses | OpenAI 兼容（compatible-mode）+ Anthropic + Responses | OpenAI 兼容生态 |

---

## 3. 能力定位（2026-08 媒体/评测口径）

| 维度 | DeepSeek V4 | 千问 Qwen3.5 | 智谱 GLM-5.3 |
|---|---|---|---|
| 综合智能 | AA 指数进入全球前沿区间（60 分区段） | Qwen3.5-Max-Preview 曾登顶国际竞技场；Qwen3.7-Max Code Arena 第 4、Elo 1541 | **AA 综合指数 60 分，并列开源第一、追平 Kimi K3** |
| 编程 | 强（V4 定位 Agentic Coding） | 强（Qwen3.7-Max 编码评测强） | **编程较前代 +50%**；Terminal-Bench 4.6→28.3 |
| Agent/工具调用 | 百万上下文为 Agent 底座 | Qwen-Agent 生态（Function Calling / MCP / Code Interpreter） | 长程任务强；36氪"模型+HARNESS 迭代强化 AGENT 能力" |
| 安全/网安 | — | — | 厂商宣称漏洞挖掘优于 Anthropic/OpenAI（**厂商口径**，需验证） |
| 中文 | V4 中文能力测评重回国内第一（媒体） | 中文强项 | 中文强项 |

---

## 4. 开源与生态

| 项目 | DeepSeek | 千问 Qwen | 智谱 GLM |
|---|---|---|---|
| 权重 | V4 开源（MIT，2026-04-24 起） | Qwen3.5 开源（Apache-2.0 系，含 397B/122B/35B 等） | GLM-5 曾开源（MIT）；**GLM-5.3 计划 8/25 开源**（36氪 8 月上旬曾报"强到不敢开源"，时间线有反差，以官方公告为准） |
| API 兼容 | OpenAI / Anthropic / Responses | OpenAI 兼容（dashscope.aliyuncs.com/compatible-mode/v1）+ Anthropic + Responses | OpenAI 兼容生态广泛接入（OpenRouter / Vercel / LiteLLM / 阿里云） |
| 免费额度 | 5M（活动期，媒体口径） | **每模型 100 万 Token / 90 天**（官方） | Z.ai 侧每日免费 300 万（论坛口径）；国内 7 天体验卡 + 积分 |

---

## 5. 与你的工作流（DSH / OpenCode）的适配

- **DSH（DeepSeek Harness）**：目前只路由 DeepSeek 官方 API（你的文档边界）。社区已有 OpenAI 兼容接入插件（如 `@morlay/dsh-llm-openai-compatible`、`dsh-model-controls` 等），**理论上可把 qwen/glm 接进 DSH**，属社区方案、未实测。
- **OpenCode**：模型中立，provider 配置即可接入三家；智谱官方有 [OpenCode 接入 GLM Coding Plan 教程](https://docs.bigmodel.cn/cn/coding-plan/tool/opencode)，阿里云也有 Coding Plan（支持千问 3.5/GLM 等，Lite 停售后 Pro 版约 118 元/月档位）。
- **对日常 agent 使用的直接含义**：
  - DeepSeek 涨价后，**错峰（17:00–次日 09:00、12:00–14:00）使用 V4-Flash 谷价 1.5/4.5 元**是当前最省的主流选择之一；已有 DSH 社区插件（`dsh-tidewatch`、`dsh-token-stats`）针对峰谷计价做定时与用量统计。
  - 若追求极致便宜 + 可切换思考：**qwen3.5-flash / qwen3.5-plus** 是明显更低价位。
  - 若追求编程/Agent 上限且能接受强制思考成本：**GLM-5.3**（注意账单陷阱）。

---

## 6. 来源清单

**DeepSeek**（官方口径转述/实测）：[官方定价文档](https://api-docs.deepseek.com/zh-cn/quick_start/pricing/)｜[《财经》实测（1100% 出处）](http://yuanchuang.caijing.com.cn/2026/0818/5177810.shtml)｜[新浪财经：8-13 公告](https://cj.sina.com.cn/articles/view/1702925432/6580947801901a4hg)｜[网易 8-6 旧价引用](http://m.163.com/dy/article/L3LRAD8H05569L3G.html)｜[ofox 迁移指南](http://ofox.ai/zh/blog/deepseek-chat-reasoner-retire-migrate-v4-2026/)｜[ofox 新价快照](http://ofox.ai/zh/blog/deepseek-api-price-increase-new-rates-peak-hours-cache-cost-2026/)

**千问**（官方存档核对）：[模型调用价格页](https://www.alibabacloud.com/help/zh/model-studio/model-pricing)｜[新人免费额度](https://help.aliyun.com/zh/model-studio/new-free-quota)｜[上下文缓存](https://help.aliyun.com/zh/model-studio/context-cache)｜[qwen3.5-plus 详情](https://help.aliyun.com/zh/model-studio/qwen3-5-plus)｜[限流](https://help.aliyun.com/zh/model-studio/rate-limit)

**智谱**：[bigmodel.cn/pricing](https://bigmodel.cn/pricing)｜[VentureBeat 价格](https://venturebeat.com/technology/glm-5-3-hits-the-api-at-1-4-4-4-per-million-tokens)｜[腾讯：一分没涨/思考关不掉](https://news.qq.com/rain/a/20260819A0CRBG00)｜[docs.z.ai GLM-5.3](https://docs.z.ai/guides/llm/glm-5.3)｜[kamacoder 选型](https://notes.kamacoder.com/llm/news/glm-5-3.html)｜[SegmentFault Terminal-Bench 实测](https://segmentfault.com/a/1190000048177639)

---

*本报告由三个并行子代理调研汇总，完整分报告：DeepSeek 峰谷定价报告、Qwen 官方价格报告、[GLM-5.3 调研报告](../research_glm53/GLM-5.3调研报告.md)。*
