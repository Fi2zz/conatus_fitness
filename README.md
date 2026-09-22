# Conatus Fitness

> **Demo**：本项目是基于 [Conatus](https://github.com/Fi2zz/conatus) Agent 框架构建的上层示例应用，用于演示框架在真实业务场景（健身训练伴侣）中的落地方式。

> 一款把 AI Agent 放在核心位置（而非当外挂功能）的健身训练伴侣 App。
> 目标：训练全程不用碰手机 —— AI 排计划、语音记录、音乐自动跟随、练后自动分析。

`Conatus`（拉丁语「努力、冲力」）既是产品名，也是本项目依赖的 Agent 框架名。

## 它解决什么问题

传统健身 App 的本质是「记录工具 + 模板库」：计划是通用模板，记录要组间解锁手机、切 App、点选输入，音乐要手动挑歌单。结果是训练节奏被切碎，数据记了一堆却得不到判断。

Conatus Fitness 把三件事交给 Agent 决策，用户只出嘴：

| 维度     | 传统健身 App | Conatus Fitness                    |
| -------- | ------------ | ---------------------------------- |
| 训练计划 | 模板套用     | Agent 基于个人画像与历史动态生成   |
| 训练记录 | 手动点选     | 一句话记录（"深蹲 100 公斤 5 次"） |
| 成果分析 | 图表罗列     | Agent 解读趋势 + 归因              |
| 训练建议 | 静态规则     | 综合负荷 / 恢复 / 偏好生成下次建议 |
| 音乐     | 手动选歌单   | Agent 按训练阶段实时决策           |
| 交互     | 触屏         | 语音为主 + 触屏辅助                |

## 核心价值

1. **训练不中断**：记录、确认、换歌都靠语音完成，双手和注意力留在训练上。
2. **建议来自你的数据**：计划与分析基于本人的训练日志、画像、伤病史推理，不是通用模板。
3. **音乐是决策系统**：按训练阶段（热身 / 主项 / 力竭 / 放松）的 BPM 曲线策展歌单，并随训练信号实时调整。
4. **安全是硬约束**：所有涉及身体负荷的输出必须过 `SafetyGuard` 纯规则校验（LLM 自评不作放行依据），伤病动作必被替换或拦截。
5. **本地优先、数据主权**：训练数据与事件日志落在本地 SQLite；密钥只进钥匙串 / keystore，不进日志与事件流；云端调用可关闭。

## 已实现能力

### 训练域

- **AI 训练计划**：输入目标 / 器械 / 每周频次 / 伤病史，Agent 输出结构化周计划（JSON Schema 约束 + 安全规则校验），可查看、复用。
- **训练记录**：按组记录重量 / 次数 / RPE，训练历史按会话聚合。
- **成果分析**：Agent 结合训练日志与统计工具（周期对比、进展、恢复信号）输出趋势解读。
- **训练建议**：给出下一场训练建议，经 `SafetyGuard` 规则链校验后展示。
- **伤病防护**：基于伤病档案与近期负荷做风险评估，输出风险报告。

### 音乐域

- **AI 策展歌单**：按训练阶段 BPM 曲线生成歌单，可视化曲线与逐曲 BPM。
- **网易云音乐源**：App 内网页授权登录 + 开放平台 RSA 签名调用；按 `playFlag` 预筛可播曲目，失败原因精确到曲。
- **播放**：队列、悬浮播放条（`Overlay`）、跨页面常驻。

### 基础设施

- **运行时模型接入**：`我的 → 模型接入` 可改 model / Base URL / API Key，即时生效无需重启；apiKey 走安全存储就地轮换，baseUrl / model 变更走服务重建。
- **本地数据**：SQLite 建表覆盖画像、训练日志、计划、Agent 记忆、歌单、事件日志（含死信表），事件溯源。

## 架构

```
Flutter UI（训练 / 音乐 / 我的）
        │
        ▼
Agent Coordinator + EventBus（双向广播，领域平级）
   ┌────────┬────────┬────────┐
   │ 训练域  │ 音乐域  │ 语音域  │
   └────────┴────────┴────────┘
        │
   SafetyGuard（纯规则安全层，独立于 LLM）
        │
   本地 SQLite + 事件日志 + 安全存储凭据
```

- **领域平级**：训练 / 音乐 / 语音三域 Agent 集群平级协同，无主从。
- **结构化输出优先**：所有 Agent 输出用 JSON Schema 约束，避免自由发挥导致结构漂移。
- **可中断**：长任务（Agent 推理、TTS 播报）支持取消，用户随时打断。
- **语音域为接口预留**：`VoiceIO`（ASR / TTS / 唤醒 / ducking）已定义基础设缝，引擎实现（Whisper.cpp / flutter_tts 等）按路线图在后续阶段注入。

详见 [architecture.md](docs/architecture.md)（技术方案）与 [PRD.md](docs/PRD.md)（产品定位与 MVP 边界）。

## 技术栈

- **客户端**：Flutter + Cupertino（iOS 风格），状态管理 Riverpod，路由走 `onGenerateRoute`
- **Agent 框架**：Conatus（git 依赖，原始仓库在 GitHub、不可达时自动回退 Gitee 镜像，伞包 + 成员包按子路径钉版本）
- **LLM**：兼容 OpenAI 协议的端点（火山方舟普通 / Agent Plan / Coding Plan 端点各自独立凭据）
- **存储**：sqflite（本地库）、shared_preferences（非密配置）、flutter_secure_storage（密钥）
- **音频**：just_audio（播放）、webview_flutter（授权登录）

## 快速开始

```bash
make deps          # 拉取依赖（原始仓库不可达时自动回退镜像）
make devices       # 查看可用设备
make run           # 运行到默认设备（DEVICE=<id> 指定设备）
make check         # 提交前：静态分析 + 测试
```

构建期配置由 `env.json` 注入（见 `Makefile` 的 `--dart-define-from-file`），全部键见下方[构建期环境变量](#构建期环境变量)表。**该文件不入库**，请自行从模板创建。

首次使用需在 `我的 → 模型接入` 填 Base URL 与 API Key，训练域与音乐域才会解锁（未配置时展示引导态）。

更多命令见 `make help`。

### 依赖来源：原始仓库优先，镜像自动兜底

Conatus 框架的原始仓库在 GitHub（[Fi2zz/conatus](https://github.com/Fi2zz/conatus)），国内直连时常不可达，拉依赖会卡住或失败；但若把依赖直接写成 Gitee 镜像地址，又会丢掉「代码实际出处」，镜像同步滞后时也不易察觉。

所以 `make deps` 取了个折中，而不是二选一：

- `pubspec.yaml` **始终写原始地址**，入库内容与网络环境无关；
- 拉依赖前先探测原始仓库的 git 端点：可达就直接用，不可达才写入一条**仓库级** git 规则（`url.<镜像>.insteadOf=<原始地址>`），由 git 在传输层把地址改写到 Gitee 镜像 —— 不改动任何入库文件，原始地址恢复可达后该规则会被自动清除；
- 镜像为导入式同步，两边 **commit SHA 完全一致**，因此 `ref` 不需要任何映射；反过来，若镜像历史分叉，pub 会在拉取阶段报「找不到该 ref」而失败，不会静默拿到错误版本。

`make upgrade` 同样走这个入口，实现见 [`tool/deps.sh`](tool/deps.sh)。

## 使用示例

> 以下为 App 内的实际操作路径（界面为 Cupertino 风格）。

### 1. 接入模型（必做第一步）

`我的 → 右上齿轮 → 模型接入`：

| 字段     | 填法                                                                                                             |
| -------- | ---------------------------------------------------------------------------------------------------------------- |
| Base URL | 普通方舟 Key 填 `https://ark.cn-beijing.volces.com/api/v3`；套餐 Key 填 `.../api/plan/v3` 或 `.../api/coding/v3` |
| 模型     | 如 `doubao-seed-2.0-mini`；留空用框架默认                                                                        |
| API Key  | 与端点配套的 Key（Plan 端点只认订阅后生成的专属 Key）                                                            |

点「测试连接」可先验证（服务端原文直接显示在界面上，不必翻终端），再点「保存」。保存即时生效：Base URL / 模型触发服务重建，API Key 由凭据服务就地轮换，无需重启。清空 API Key 再保存 = 删除本机密钥（回退到构建期注入值）。

### 2. 生成训练计划

`训练 → 右上 ＋`，填写画像后点「生成」：

| 字段     | 取值                         |
| -------- | ---------------------------- |
| 训练目标 | 必填，如「提升深蹲 1RM」     |
| 水平     | 初级 / 中级 / 高级           |
| 每周     | 2 / 3 / 4 / 5 次             |
| 周数     | 1 / 2 / 4                    |
| 器械     | 如「健身房」「哑铃」「徒手」 |
| 伤病史   | 如「膝盖旧伤；无」           |

生成链路：`injury_check` 先自检伤病冲突 → `validate_plan` 做结构校验 + `SafetyGuard` 终审（冲突动作被要求替换，负荷增幅越界被安全改写）→ 通过后落库。计划出现在训练页列表，点开可看分周 / 分动作详情。

### 3. 记录一次训练

`训练 → 右上 ▣` 进入记录页。**一次进入 = 一次训练课**（`session_id` 本次固定），连续记录共享：

- 动作名 + 重量(kg) + 次数；打开 RPE 开关后按 1–10 记录强度
- 点「记录这一组」：同动作组号自动递增（1、2、3…），保存后只清重量与次数，便于连续录入
- 日期可改，用于补记往日训练

历史：`训练 → 右上 ⌚`，按训练课聚合查看。

### 4. 练后分析与下次建议

- **成果分析**：`训练 → 成果分析 → 开始分析`。Agent 依次调用 `workout_log_query` 取数 → `progress_analysis` 算容量 / 峰值 / 渐进超负荷率 → `compare_periods` 做等长窗口对比 → `recovery_signal` 取恢复趋势，输出「事实 → 解读 → 下一步」文本。结论落 `agent_memory`，下次分析会带上上一次结论以保持口径一致。
- **训练建议**：`训练 → 训练建议`，拖滑块给出主观恢复评分（0 = 精疲力尽，10 = 状态拉满）并选择是否有疼痛，点「生成建议」。Agent 自动带上近 14 天训练摘要，输出 `increase_load / maintain / deload / rest` 四选一的建议，经 `SafetyGuard` 终审（如恢复评分过低时强制 rest/deload）。

### 5. 伤病防护评估

`训练 → 伤病防护 → 开始评估`（右上铅笔进入伤病史编辑，每行一条，写入画像 `injuries`）。Agent 读取画像与伤病史 → 查询近期负荷 → 自检动作冲突 → 输出风险报告（风险等级 / 风险部位 / 负荷分析 / 防护动作）。

### 6. 策展歌单并播放

1. **登录音源**：`音乐 → 右上「登录」`。App 内打开网易云官方授权网页，页面同时轮询票据，授权成功后自动返回并刷新登录态与会员态。
2. **生成歌单**：`音乐 → 右上 ⊕`，填训练类型（必填，如「下肢力量」）、时长（30 / 45 / 60 分）、氛围（可留空，如「炸裂」）。Agent 按「热身 → 主项 → 力竭 → 拉伸」四阶段 BPM 曲线选曲，`validate_playlist` 终审后落库。
3. **播放**：点歌单进详情页，看 BPM 曲线与分阶段曲目；点任意曲目即从那首入队播放（整张歌单为队列，播完自动续播）。悬浮播放条跨页面常驻。

取址逻辑：策展产出只有标题 / 艺人，故先按「标题 + 艺人」检索音源，按匹配度排序后**逐首尝试**（`playFlag=false` 的无版权曲目直接跳过，最多试 3 个可播候选）；码率按会员态选（会员 320kbps / 非会员 128kbps）。取不到地址时**停在当前曲目**并显示原因，再点即重试。

## API 调用说明

### 构建期环境变量

由 `env.json` 经 `--dart-define-from-file` 注入（见 `Makefile`），密钥不入库。

| 键                        | 用途                                     | 默认值                                          |
| ------------------------- | ---------------------------------------- | ----------------------------------------------- |
| `ARK_BASE_URL`            | LLM 端点                                 | `https://ark.cn-beijing.volces.com/api/plan/v3` |
| `ARK_MODEL`               | 模型名                                   | `doubao-seed-2.0-mini`                          |
| `ARK_API_KEY`             | 普通方舟 Key（`/api/v3`）                | 空                                              |
| `ARK_AGENT_PLAN_API_KEY`  | Agent Plan 专属 Key（`/api/plan/v3`）    | 空                                              |
| `ARK_CODING_PLAN_API_KEY` | Coding Plan 专属 Key（`/api/coding/v3`） | 空                                              |
| `NETEASE_APP_ID`          | 网易云开放平台应用 id（非密）            | 空                                              |
| `NETEASE_PRIVATE_KEY`     | 开放平台 PrivateKey（pkcs#8，签名用）    | 空                                              |
| `NETEASE_API_BASE_URL`    | 开放平台根地址                           | `https://openncm.music.163.com`                 |

配置优先级：**运行时 > 构建期注入**。API Key 只落钥匙串 / keystore，Base URL 与模型落 shared_preferences；构建期三个 Key 仅在安全存储为空时兜底，且不落盘。

### LLM 调用

- **端点与凭据键的对应**（`lib/core/config/llm_endpoints.dart`）：`/api/plan/` → `ARK_AGENT_PLAN_API_KEY`，`/api/coding/` → `ARK_CODING_PLAN_API_KEY`，其余 → `ARK_API_KEY`。Plan 端点只认订阅后生成的专属 Key，拿普通 Key 打会得到 `AuthenticationError`。
- **服务装配**（`lib/di/llm_providers.dart`）：`DoubaoProvider(baseUrl, model, credentials, credentialKey)` 包进 `FallbackLlm`，注册进 Conatus `Context` 的 `'llm'` 键；Agent 每次运行现取该服务，因此改配置不需要重建 Agent。
- **就绪判定**：`llmStatusProvider` 是唯一入口（`loading` / `ready` / `notConfigured`），训练域与音乐域未就绪时展示引导态。不要在别处直接读 `appConfigProvider` 判定就绪，否则没人触发服务注册。

### 网易云音乐开放平台

请求统一走 `lib/features/music/playback/netease/netease_transport.dart`：GET（匿名登录为 POST）+ 公共参数 + RSA 签名。

公共参数（query）：`appId`、`signType=RSA_SHA256`、`timestamp`、`device`（设备信息 JSON）、`bizContent`（业务参数 JSON）、`accessToken`（可选）、`sign`。

**签名**（`netease_signer.dart`）：待签串 = 剔除 `sign` 与空值 → 参数名 ASCII 升序 → `k=v` 以 `&` 连接；用应用私钥做 SHA256withRSA（PKCS#1 v1.5 填充），Base64 结果即 `sign`（入请求需 URL 编码）。本地排查可用 `NeteaseSigner.verify` 配公钥自检。

| 接口路径                                              | 方法 | 用途                                     | 令牌 |
| ----------------------------------------------------- | ---- | ---------------------------------------- | ---- |
| `/openapi/music/basic/oauth2/login/anonymous`         | POST | 取匿名令牌（只够拉起授权登录）           | —    |
| `/openapi/music/basic/user/oauth2/qrcodekey/get/v2`   | GET  | 取登录票据（`type:2`、`expiredKey:300`） | 匿名 |
| `/openapi/music/basic/oauth2/device/login/qrcode/get` | GET  | 轮询授权结果                             | 匿名 |
| `/openapi/music/basic/search/song/get/v3`             | GET  | 关键词检索                               | 用户 |
| `/openapi/music/basic/song/detail/get/v2`             | GET  | 取播放地址                               | 用户 |

- 轮询状态：`801` 等待 / `802` 待确认 / `803` 成功 / `800` 过期。
- 业务参数：检索 `keyword`、`limit`、`offset`、`qualityFlag=false`、`trialScene=cli`；取址 `songId`、`withUrl=true`、`bitrate`、`trialScene=cli`。
- 授权网页由票据拼出：`https://music.163.com/st/platform/scanlogin?codekey=<uniKey>&hdw_deviceid=…&hdw_device=…&hdw_brand=…&hdw_model=…&hdw_appid=<appId>&hitExp=1`。
- 响应约定：`code == 200` 成功；`code == 301` 表示令牌不被接受，转成 `NeteaseException(needsLogin: true)` 由 UI 引导登录；其余非 200 原样带出 `message`。

### Agent 与工具契约（内部 API）

一次 Agent 运行的装配契约见 `lib/di/agent_run.dart`：

```dart
final run = AgentRun.open(
  ctx,                    // 须已注册 'llm'
  name: 'planner',
  tools: toolRegistry,
  systemPrompt: prompt,
  session: Session(id: 'planner_$uuid'),
  maxSteps: 8,
  maxRetries: 2,
);
try {
  await run.loop.run(userBrief);   // 工具循环
} finally {
  run.dispose();                   // 回收本次运行注册的服务
}
```

返回统一为 `AgentOutcome<T>`：`Ok(value)` / `RetryableError(message)` / `FatalError(message, suggestion:)`。

自定义工具实现 `Tool` 契约（范例见 `lib/features/training/agents/injury_check_tool.dart`）：`name`、`description`（模型据此决定何时调用）、`params`（`ParamSpec.string` / `ParamSpec.integer`）、`call(ToolContext) → ToolResult.success/failure`；失败带 `ToolError(code, message)` 会触发 `reflectAndRetry` 反思重试。

| Agent             | 工具                                                                           | 步数 / 重试 | 产出落点                                   |
| ----------------- | ------------------------------------------------------------------------------ | ----------- | ------------------------------------------ |
| Planner           | `injury_check`、`validate_plan`                                                | 8 / 2       | `training_plans`                           |
| Analysis          | `workout_log_query`、`progress_analysis`、`compare_periods`、`recovery_signal` | 10 / 2      | `agent_memory`(training/analysis)          |
| Suggestion        | `validate_suggestion`                                                          | 6 / 2       | `agent_memory`(training/suggestion)        |
| Injury Prevention | `injury_profile`、`workout_log_query`、`injury_check`、`validate_risk_report`  | 10 / 2      | `agent_memory`(training/injury_prevention) |
| MusicCurator      | `music_history`、`validate_playlist`                                           | 6 / 2       | `playlists`                                |

工具参数：

| 工具                | 参数                                               |
| ------------------- | -------------------------------------------------- |
| `injury_check`      | `exercise`(string, 必填)                           |
| `workout_log_query` | `exercise`(string, 可选)、`days`(integer, 默认 30) |
| `progress_analysis` | `days`(integer, 默认 30)                           |
| `compare_periods`   | `days`(integer, 默认 14)                           |
| `recovery_signal`   | 无（当前无评分数据源，返回数据不足）               |
| `injury_profile`    | 无                                                 |
| `music_history`     | 无                                                 |
| `validate_*` 系列   | 对应业务对象的字段结构（即各自的输出 JSON Schema） |

**安全层**：`SafetyGuard<T>(rules: …).check(input)` 返回 `SafetyPassed` / `SafetyRewritten(rewritten, reason)` / `SafetyBlocked(reason)`。规则是**纯代码硬规则**，与 LLM 解耦；LLM 自评的 `safety_flag` 不具备放行效力。改写与拦截均落 `event_log` 可追溯。

### 数据访问 API

DAO 是 `sqflite` 的薄封装，位于各特性的 `data/` 目录：

| DAO              | 方法                                                                                                                |
| ---------------- | ------------------------------------------------------------------------------------------------------------------- |
| `WorkoutLogsDao` | `save(WorkoutSetLog)`、`nextSetNumber(sessionId, exercise)`、`listAll({limit=500})`、`listSince(since, {exercise})` |
| `PlansDao`       | `save(plan, {source, safetyStatus})`、`findById(id)`                                                                |
| `AgentMemoryDao` | `save({domain, kind, content})`、`listLatest({domain, kind, limit=20})`                                             |
| `PlaylistsDao`   | `save(MusicPlaylist)`、`findById(id)`                                                                               |
| `ProfileDao`     | `load()`、`save(UserProfile)`                                                                                       |
| `EventLogDao`    | `record(eventId, sourceAgent, payload)`                                                                             |

### 音源端口（扩展新音源）

播放器只依赖 `lib/features/music/playback/source/music_source.dart` 的接口，鉴权 / 签名 / 接口细节都留在实现里：

```dart
abstract interface class MusicSource {
  String get id;
  Future<List<TrackRef>> search(String keyword, {int limit});
  Future<Uri?> streamUrl(TrackRef track); // 无版权 / 不可播时返回 null
}
```

新增音源只需实现该接口并替换 `trackResolverProvider` 的装配，播放器与 UI 无需改动。

## 目录结构

```
lib/
  core/        # 安全校验、事件总线、语音接口、日志、配置
  di/          # Riverpod 装配：模型服务、凭据、数据库、事件总线
  data/        # SQLite 建表与 DAO、安全存储凭据
  features/
    training/  # 训练域：计划 / 记录 / 分析 / 建议 / 伤病防护
    music/     # 音乐域：策展 / 播放 / 网易云音源
    settings/  # 模型接入设置
    shell/     # 三 Tab 壳
test/          # 单元与 Widget 测试（安全规则、编解码、播放、凭据等）
docs/          # PRD、技术架构、运行时模型配置
```

## 状态

训练域与音乐域主链路（计划 → 记录 → 分析 → 建议 / 策展 → 播放）已落地；语音域为接口预留，按架构路线图在后续阶段接入 ASR / TTS。所有训练建议附免责声明，不构成医疗建议。
