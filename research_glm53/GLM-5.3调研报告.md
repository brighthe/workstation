# GLM-5.3 API 定价与关键规格调研报告（2026-08 上线）

> 调研日期：2026-08（报告生成于本次会话）
> 调研方法：使用 web_search 执行了用户指定的 5 组必查查询 + 约 33 组补充查询（共约 38 次）。
> **重要限制声明**：本会话沙箱禁止一切 HTTPS 出站（直连与本地代理 7892/7897 均 SSL 握手失败，HTTP 可通但所有目标站点均 301 到 HTTPS），因此**无法打开任何页面正文**（bigmodel.cn/pricing、docs 等均只能确认"被搜索引擎收录"，读不到价格表原文）。本报告所有结论基于**搜索引擎返回的标题/URL 级证据**交叉比对。凡未能核实的具体数字，一律标注"❓未找到/无法核实"，未做任何编造。

## 0. 时间线与关键事实速览（媒体多源证实）

- 2026-06-16：GLM-5.2 发布（llm-stats 页标 "Released on Jun 16, 2026"）。
- 2026-08-03：GLM-5.3「闪现」约一小时，官方 SDK 已更新模型名（新浪财经标题）。
- 2026-08-19：GLM-5.3 API 正式上线（腾讯新闻、界面、财联社、九方、品玩等多源同日报道）。
- 权重开源：媒体报道"下周五开源"，搜狐具体写 **8 月 25 日开源**（见 §4 矛盾标注）。
- 官方研究页：智谱研究院《GLM-5.3：前沿编程能力与涌现的网络安全能力》（zhipuai.cn/zh/research/162）。

## 1. 每百万 tokens 价格（美元 / 人民币 / 缓存命中）

### 1.1 美元价格（多源标题交叉证实）

| 项目 | 价格（USD / 1M tokens） | 来源类型 | 证据 |
|---|---|---|---|
| 输入（Input / Prompt） | **$1.4** | 官方口径媒体转述 | VentureBeat 标题即 "GLM-5.3 hits the API at **$1.4/$4.4** per million tokens"；知乎文标题 "**$1.4** 低价背后…" |
| 输出（Output / Completion） | **$4.4** | 官方口径媒体转述 | Cocoloop 中文标题 "百万 token 输出 **4.4 美元**"；同一篇被译为西/葡/印尼/法/韩等多语言版本，均为 "4.4 dollars per million output tokens"（西语标题 "a 4,4 dólares por millón de tokens de salida"） |
| 缓存命中（Cache hit） | ❓未找到官方数字 | — | 未能读取 docs.z.ai/guides/overview/pricing 与 bigmodel.cn/pricing 正文；WaveSpeed 有 "GLM 5.3 Pricing: API Cost and Agent Economics" 专文但无法打开核实 |

> 用户背景中给出的 "$1.4 输入 / $4.4 输出" 与本轮搜索到的多个媒体标题**完全一致，无矛盾**。

### 1.2 人民币价格

- ❓**未找到**官方人民币价格数字。官方人民币价目表应在 bigmodel.cn/pricing（已确认被收录，正文不可读）；阿里云 Model Studio 也上架了 ZHIPU/GLM-5.3（人民币计费页 help.aliyun.com/zh/model-studio/glm-5-3-by-zhipu，正文不可读）。

### 1.3 子型号（turbo 等）

- ❓**未找到 "GLM-5.3-Turbo"** 或官方子型号的任何信息。搜索"GLM-5.3 turbo"仅返回主模型相关页面。
- ⚠️ 第三方聚合站出现 "GLM-5.3 (max)" 标签（traktoken.com/models/glm-5-3 标题 "GLM-5.3 (max) — API 价格与性价比"；Artificial Analysis "GLM-5.3 (max)…"），疑似聚合站自设变体/输出档位标签，**无法核实为官方子型号**。

## 2. 与上一代价格对比（GLM-4.6 / 5.1 / 5.2）

- ✅ **与 GLM-5.2 完全同价**：搜狐标题直接写明 "定价与前代 **GLM-5.2 保持一致**"；腾讯新闻标题 "**一分没涨**"；ChainThink/TheBlockBeats "**API 单价没涨**"；aitop100 "**价格不变**"；韩国 AI타임스 "**가격 동결**"（价格冻结）。多语言多源一致，无矛盾。
- ⚠️ 与 GLM-4.6/5.1 的纵向对比：2026 年 4 月媒体曾报道"智谱今年**三度提价、再涨 10%**"（南方都市报、搜狐、网易、今日头条，多源），说明 4.6→5.x 之间有过多次涨价；此后 5.1→5.2→5.3 价格冻结。**各代具体单价数字未在标题级证据中取得，无法列出精确对比表**。
- ⚠️ 渠道价可能低于官方价：券商纪要标题提示 "GLM-5.2 渠道降价分析：**OpenRouter 大幅降价系第三方渠道行为**"（发现报告）——第三方聚合渠道价格 ≠ 官方价格，注意区分。

## 3. 上下文长度 / 输出上限 / 思考模式

| 项目 | 结论 | 证据与核实状态 |
|---|---|---|
| 思考模式 | ✅ **强制思考，无法关闭**。媒体报道一致：腾讯新闻标题 "**思考关不掉了**"；七牛新闻 "**强制推理模式**"；日媒 innovatopia "**常時推論に一本化**"（统一为常时推理）；Cursor 社区帖 "**GLM-5.3 cannot be implemented reasoning_effort**"（reasoning_effort 参数未实现）；知乎文 "**未设推理档位**" → 即官方未提供"不思考/思考档位"开关 | 多源一致 |
| 思考 token 计费 | ⚠️ 知乎实操文标题："$1.4 低价背后，未设推理档位导致**费用暴涨 35 倍**的隐藏陷阱" —— 媒体观点：强制思考导致输出（含思考）token 量大，实际账单可能远超表面单价 | 单一媒体观点，需自行验证 |
| 上下文长度 | ❓GLM-5.3 官方数字未能在标题级证实。参考：GLM-5.2 官方为 **100 万 token 上下文**（Cocoloop 2026-06 标题 "智谱开源 GLM-5.2，上下文 100 万 token"）；用户提到的"128K"在本轮搜索中**无任何标题证实**，两者存在矛盾/不确定性 | 标注矛盾：128K（用户背景）vs 1M（GLM-5.2 官方）vs GLM-5.3 未确认 |
| 输出上限（max output） | ❓未找到官方数字（docs.bigmodel.cn / docs.z.ai 正文不可读） | — |

## 4. 能力定位（编程 / 推理 / Agent / 安全）

- **编程**：✅ 媒体普遍称编程能力较前代提升 **50%**（七牛新闻、kamacoder 标题均含"编程涨 50%"）；**Terminal-Bench 从 4.6 跃升至 28.3**（SegmentFault 实测标题）；"擅长复杂编码"（凤凰网科技）；定位为"开源系写代码 AI"（台媒 pcrookie）。
- **推理/综合智能**：✅ **Artificial Analysis 综合智能指数 60 分，并列开源第一、追平 Kimi K3，进入全球前沿模型区间**（证券日报、品玩、ChainThink、TheBlockBeats、edgen、Gate 新闻等多源）；"参数原封不动（743B 基座），分数追平闭源旗舰"（知乎）。
- **后训练驱动**：✅ 能力跃升来自后训练而非换底座（webpronews "Sharp Gains … Through Post-Training Alone"；aitop100 "不换底座，靠后训练把编程能力拉满"；唐杰谈后训练 Scaling）。
- **安全（网络安全）**：✅ 官方研究页主题即"**前沿编程能力与涌现的网络安全能力**"；媒体称"安全能力意外爆发"（kamacoder）、"网络安全能力超预期"（至顶网）；The Register 标题转述智谱宣称新模型**漏洞挖掘能力优于 Anthropic、OpenAI**；"防御性网络安全"（凤凰/ifeng、runtimewire）；SCMP "Mythos-level edge in cyber defence"。⚠️ 均为厂商口径/媒体转述，非独立评测。
- **Agent/工具调用**：✅ Terminal-Bench（终端 Agent）大幅跃升（SegmentFault）；"擅长…**长程任务**"（凤凰网科技）；36氪"模型+HARNESS 迭代强化 AGENT 能力"；yun88 有"GLM-5.3 做 Agent：工具调用与多步任务实测"专文（正文不可读）。
- **开源/商业化**：✅ 7430 亿参数（DoNews 标题）；权重开源计划：iThome/chinaz/aastocks/sohu 均称"权重下周五/8月25日开源"。
  - ⚠️ 矛盾标注：8 月上旬 36氪曾发"因为 AI 新版本太强，强到智谱**暂时不敢开源**了"——与 8/19 官宣"下周五开源"存在时间线反差（应为"闪现"后一度犹豫、最终决定开源）；且"8月25日（周二）"与"下周五"表述有 3 天出入，以官方公告为准。

## 5. API 兼容性（OpenAI 兼容 / 国内外同一套 / 域名）

- ✅ 生态兼容证据（均为第三方接入事实，间接证明 OpenAI 兼容格式被广泛采用）：OpenRouter 上架 **z-ai/glm-5.3**（model id 带日期后缀 "z-ai/glm-5.3-20260816"，来自 benchable / openrouter.wk-xj 标题）；Vercel AI Gateway 接入 GLM-5.3（changelog + 模型页）；阿里云 Model Studio 提供 **ZHIPU/GLM-5.3**；LiteLLM PR "add Z.AI (Zhipu AI) as built-in provider"；jambonz、Roo Code 均有"使用 Z AI"教程。
- ❓**官方域名声明未能在本环境读取正文核实**：官方文档站为 docs.bigmodel.cn（国内）与 docs.z.ai（海外），开放平台为 bigmodel.cn / Z.ai（z.ai）；国内 API 入口历史上为 open.bigmodel.cn（v4 风格路径）、海外为 api.z.ai，**是否同一套 API 与确切 base_url 请以官方文档为准**——本轮仅有"ZHIPU/GLM-5.3 - Alibaba Cloud"与 docs.z.ai 标题级佐证，无法确证。
- 官方模型文档页（收录确认）：docs.bigmodel.cn/cn/guide/models/text/glm-5.3、docs.z.ai/guides/llm/glm-5.3、docs.z.ai/guides/overview/pricing。

## 6. 免费额度 / 试用政策

- ⚠️ Z.ai 侧：土耳其论坛标题 "GLM 5.3 **Her gün ücretsiz 3 milyon token**"（每天免费 300 万 token）——媒体/论坛口径，**非官方公告**，具体适用对象（App/API/订阅）未核实。
- ⚠️ 国内 bigmodel 侧：yun88 有"**GLM-5.3 免费额度有多少？**新用户试用与正式采购"专文（具体数字不可读）；"智谱 AI 免费领取 7 天 Coding Plan 体验卡，送 GLM 5.3 与 **2000 积分**"（aimao.today）；"智谱 GLM5.3 免费用！ZCode 平台零门槛体验"（今日头条）；"智谱 GLM Coding Plan 订阅重启：积分制透明化与限时折扣并行，限时最高 7 折"（x-techcom/smahz）。
- ❓**官方免费 token 数量**未找到（需登录 bigmodel.cn 或阅读官方文档核实）。

## 7. 来源清单（官方 / 媒体分类）

**官方/半官方（收录确认，正文本环境不可读）**
- 定价页：https://bigmodel.cn/pricing （智谱官方定价，最重要，未读到正文）
- 模型文档：https://docs.bigmodel.cn/cn/guide/models/text/glm-5.3
- 海外文档：https://docs.z.ai/guides/llm/glm-5.3 ；定价：https://docs.z.ai/guides/overview/pricing
- 官方研究：https://www.zhipuai.cn/zh/research/162 （GLM-5.3：前沿编程能力与涌现的网络安全能力）
- 阿里云镜像（人民币计费参考）：https://www.alibabacloud.com/help/zh/model-studio/glm-5-3-by-zhipu

**媒体/第三方（标题级证实）**
- VentureBeat（价格标题）：https://venturebeat.com/technology/glm-5-3-hits-the-api-at-1-4-4-4-per-million-tokens
- 腾讯新闻（一分没涨/思考关不掉）：https://news.qq.com/rain/a/20260819A0CRBG00
- Cocoloop（4.4 美元输出，多语言）：https://news.cocoloop.cn/2026/08/glm-53-api-live-aa-index/
- kamacoder（编程涨50%/安全爆发/选型）：https://notes.kamacoder.com/llm/news/glm-5-3.html
- traktoken（价格性价比）：https://www.traktoken.com/models/glm-5-3 ；lmmarketcap：https://lmmarketcap.com/zh/model/z-ai-glm-5-3
- 搜狐（定价与 5.2 一致/8-25 开源）：https://www.sohu.com/a/1064853194_122350775
- 证券日报（AA 60 分）：http://www.zqrb.cn/tmt/tmthangye/2026-08-19/A1787103008485.html
- SegmentFault（Terminal-Bench 4.6→28.3）：https://segmentfault.com/a/1190000048177639
- 七牛新闻（编程 +50%/强制推理）：https://news.qiniu.com/archives/1787109869202
- The Register（漏洞挖掘宣称）：https://www.theregister.com/security/2026/08/17/chinese-ai-company-zhipu-claims-its-new-model-is-a-better-bug-finder-than-anthropic-openai/5288203
- 知乎（35 倍费用陷阱/参数原封不动/AA 60）：https://zhuanlan.zhihu.com/p/2073726543885514246 、https://zhuanlan.zhihu.com/p/2073456844568277183 、https://zhuanlan.zhihu.com/p/2073356152197457044
- OpenRouter：https://openrouter.ai/z-ai/glm-5.3 ；Vercel：https://vercel.com/ai-gateway/models/glm-5.3
- 新浪财经（8/3 闪现）：https://finance.sina.com.cn/roll/2026-08-03/doc-inikzzhi5896563.shtml
- 36氪（暂不敢开源，8 月上旬）：https://www.36kr.com/p/3945790191179400
- 南方都市报（2026 年内三度提价 +10%）：https://m.mp.oeeee.com/oe/BAAFRD0000202604081553098.html
- 智谱 GLM-5.2 开源/1M 上下文（6 月，Cocoloop）：https://news.cocoloop.cn/2026/06/glm-5-2-open-source-1m-context/
- 免费额度相关：yun88 https://www.yun88.com/news/12279.html 、aimao https://www.aimao.today/1021.html 、R10（3M/天，土耳其）https://www.r10.net/yapay-zeka/4856909-glm-5-3-her-gun-ucretsiz-3-milyon-token.html

## 8. 结论摘要（可信度分级）

1. **价格**：$1.4 输入 / $4.4 输出（每百万 tokens）——多源标题级证实 ✅；与 GLM-5.2 同价、"一分没涨" ✅；人民币价格、缓存命中折扣 ❓未找到。
2. **思考模式**：强制思考、无档位、关不掉 ✅（多源一致）。
3. **上下文/输出上限**：GLM-5.3 官方数字未证实 ❓；GLM-5.2 为 1M 上下文 ⚠️；"128K"无证据 ❓。
4. **能力**：编程 +50%、Terminal-Bench 4.6→28.3、AA 指数 60 分并列开源第一（追平 Kimi K3）、网络安全能力"涌现/超预期"（厂商口径）✅/⚠️。
5. **兼容性**：OpenAI 兼容生态被 OpenRouter/Vercel/阿里云/LiteLLM 等第三方广泛接入 ✅；官方域名与国内外是否同 API ❓待官方文档确认。
6. **免费额度**：Z.ai 每日 3M token（论坛口径）、国内 7 天 Coding Plan 体验卡/2000 积分（媒体）⚠️；官方 token 数 ❓。

**建议**：以上数字如需用于采购决策，请务必登录 https://bigmodel.cn/pricing 与 https://docs.z.ai/guides/overview/pricing 人工核对正文（本环境无法访问 HTTPS）。
