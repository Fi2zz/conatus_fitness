# Flutter 健身 App AI Agent 完整设计方案

**版本**：v1.1（工程审查修订版）
**框架**：Conatus
**文档类型**：技术设计方案
**适用场景**：健身训练 App，AI 驱动训练计划 / 成果分析 / 训练建议 / 音乐播放 / FM 主播 / 语音交互

## 目录

1. 项目概述
2. 设计原则
3. 系统总体架构
4. Conatus 框架扩展
5. 训练域 Agent 集群
6. 音乐域 Agent 集群
7. 语音域 Agent 集群
8. Voice I/O 基础设施层
9. 事件总线（EventBus）
10. 数据与记忆架构
11. 工具层设计
12. 播放器与音频架构
13. Prompt 工程
14. 隐私与安全
15. 性能与延迟预算
16. 技术选型汇总
17. 典型端到端场景
18. 实施路线图
19. 风险与对策
20. 附录

## 1. 项目概述

### 1.1 产品定位

一款深度融合 AI Agent 能力的健身训练伴侣 App。核心特色：

- **三大 AI 训练能力**：AI 创建训练计划、AI 分析训练成果、AI 给出下一次健身建议
- **AI 驱动的音乐与 FM**：不是被动播放器，而是能主动决策、实时调整、生成主播内容的智能音频系统
- **全语音交互**：健身时双手被占用，语音成为主交互通道，支持 ASR 输入与 TTS 输出
- **本地优先**：训练数据、语音识别默认本地处理，隐私可控

### 1.2 目标用户

- 有规律健身习惯、追求科学训练的中高级训练者
- 训练时习惯听音乐/FM 的用户
- 希望获得个性化 AI 指导但不想频繁操作手机的用户

### 1.3 核心价值主张

| 维度     | 传统健身 App | 本产品                         |
| -------- | ------------ | ------------------------------ |
| 训练计划 | 模板化       | AI 基于个人数据动态生成        |
| 成果分析 | 图表展示     | AI 解读趋势 + 归因             |
| 训练建议 | 静态规则     | Multi-Agent 综合负荷/恢复/偏好 |
| 音乐     | 手动选歌单   | Agent 实时决策 + 双向联动      |
| FM       | 真人电台     | AI 主播，个性化人格            |
| 交互     | 触屏         | 语音为主 + 触屏辅助            |

## 2. 设计原则

1. **领域平级**：训练域、音乐域、语音域三个 Agent 集群平级，通过 EventBus 协同，无主从关系。
2. **基础设施共享**：LLM、ASR、TTS、Memory、EventBus 作为 Conatus 基础设施，所有 Agent 共享。
3. **结构化输出优先**：所有 Agent 输出使用 JSON Schema 约束，避免 LLM 自由发挥导致的结构问题。
4. **本地数据主权**：训练数据、语音识别默认本地处理，云端调用需显式授权。
5. **低延迟优先**：实时场景（DJ、语音对话）使用本地模型 + 规则，复杂推理才调用云端。
6. **隐私可感知**：录音有明确指示，用户可查看/删除所有语音记录。
7. **可中断**：所有长任务（TTS 播报、Agent 推理、对话）支持 CancellationToken，用户随时打断。
8. **安全优先**：涉及身体负荷的建议，安全约束优先于用户请求。

## 3. 系统总体架构

### 3.1 分层视图

```
┌────────────────────────────────────────────────────────────────────────┐
│                           Flutter App 层                                │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐  │
│  │ 训练计划  │ │ 成果分析  │ │ 建议 UI  │ │ 播放器 UI │ │ 语音交互 UI   │  │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘ └──────┬───────┘  │
│       └────────────┴────────────┴────────────┴──────────────┘          │
│                                 │                                       │
│              ┌──────────────────┴──────────────────┐                    │
│              │   Agent Coordinator (Conatus)        │                    │
│              │   + EventBus（双向广播）              │                    │
│              └──┬────────────┬────────────┬─────────┘                    │
│                 │            │            │                            │
│        ┌────────┘            │            └────────┐                    │
│        ▼                     ▼                     ▼                    │
│  ┌───────────┐        ┌───────────┐        ┌──────────────┐            │
│  │ 训练域     │        │ 音乐域     │        │ 语音域        │            │
│  │ Agent 集群 │ ◄──►   │ Agent 集群 │ ◄──►   │ Agent 集群    │            │
│  └─────┬─────┘ EventBus└─────┬─────┘ EventBus└──────┬───────┘            │
│        │                    │                      │                    │
│        └────────────────────┼──────────────────────┘                    │
│                             ▼                                           │
│         ┌────────────────────────────────────────────┐                  │
│         │        Voice I/O Layer（基础设施层）        │                  │
│         │  ┌──────────┐  ┌──────────┐  ┌──────────┐ │                  │
│         │  │ ASR 引擎  │  │ TTS 引擎  │  │ VAD/唤醒 │ │                  │
│         │  └──────────┘  └──────────┘  └──────────┘ │                  │
│         └────────────────────────────────────────────┘                  │
│                             │                                           │
│         ┌───────────────────┴────────────────────┐                      │
│         │        Tools & Data Layer              │                      │
│         └────────────────────────────────────────┘                      │
└────────────────────────────────────────────────────────────────────────┘
                           │
                           ▼
       ┌──────────────────────────────────────────────┐
       │      Persistent Memory（分层记忆）             │
       │  训练记忆 | 音乐记忆 | 语音记忆 | 跨域关联     │
       └──────────────────────────────────────────────┘
```

### 3.2 Agent 集群总览

| 域         | Agent              | 类型          | 核心职责         |
| ---------- | ------------------ | ------------- | ---------------- |
| **训练域** | Planner Agent      | Planner       | 生成训练计划     |
|            | Analysis Agent     | ReAct         | 分析训练成果     |
|            | Suggestion Agent   | Multi-Agent   | 综合生成下次建议 |
| **音乐域** | MusicCurator Agent | Planner       | 长期策展歌单     |
|            | DJ Agent           | Reactive      | 实时调整音乐     |
|            | FM Host Agent      | Planner + TTS | 生成主播内容     |
| **语音域** | VoiceIntentAgent   | 轻量 ReAct    | 意图路由         |
|            | VoiceDialogAgent   | Planner       | 多轮对话         |
|            | VoiceFeedbackAgent | 特征分析      | 副语言信息提取   |

## 4. Conatus 框架扩展

### 4.1 新增基础设施接口

```dart
// 语音基础设施
abstract class ConatusVoiceProvider {
  VoiceIO get voiceIO;
  AsrEngine get asrEngine;
  TtsEngine get ttsEngine;
}

// 事件总线
abstract class AgentEventBus {
  void emit<T>(T event);
  Stream<T> on<T>();
  void subscribe<T>(void Function(T) handler);
  void unsubscribe<T>(void Function(T) handler);
}
```

### 4.2 新增 Agent 类型

为避免分类维度混乱，Agent 按**两个正交维度**描述：

**维度一：推理范式**（继承自 Conatus 基类）

| 范式        | 说明                              | 使用 Agent                       |
| ----------- | --------------------------------- | -------------------------------- |
| Planner     | 一次规划、结构化输出              | Planner、MusicCurator、FM Host   |
| ReAct       | 推理-行动循环，多步工具调用       | Analysis、VoiceIntent、各 Expert |
| Multi-Agent | 编排多个子 Agent                  | Suggestion                       |
| Reactive    | 低频 ReAct + 高频事件响应混合模式 | DJ                               |

**维度二：实时性**（框架新增基类）

| 基类            | 说明                               | 使用场景     |
| --------------- | ---------------------------------- | ------------ |
| `ReactiveAgent` | 事件驱动、亚秒级响应、本地规则优先 | DJ Agent     |
| `VoiceAgent`    | 内置 ASR/TTS 能力的 Agent 基类     | 语音域 Agent |

**说明**：VoiceFeedbackAgent 属于「特征分析」即本地模型推理，无 LLM，归为 ReAct 的退化形态（单次推理），继承 `VoiceAgent`。

### 4.3 新增工具类型

| 工具                     | 用途                       |
| ------------------------ | -------------------------- |
| `ListenTool`             | Agent 开启一段语音监听     |
| `SpeakTool`              | Agent 主动播报             |
| `SpeakAndListenTool`     | 播报后立即监听（对话模式） |
| `DetectVoiceEmotionTool` | 从音频特征提取副语言信息   |
| `StreamFMTool`           | 返回持续音频流             |
| `MixAudioTool`           | 操作音频队列               |

### 4.4 新增事件类型

```dart
// 训练事件
sealed class TrainingEvent {
  SetCompleted(setNumber, rpe, weight, reps);
  RestStarted(duration, intensity);
  RestEnded();
  WorkoutStarted(planId, focus);
  WorkoutEnded(totalVolume, duration);
  FatigueDetected(level);
  PersonalRecord(lift, weight);
  PlateauDetected(exercise);
  PersonalRecordAttempt(lift, weight);
}

// 音乐事件
sealed class MusicEvent {
  TrackSkipped(trackId, context);
  TrackRepeated(trackId);
  MoodFeedback(trackId, rating);
  EnergyTrend(rising|falling);
}

// 语音事件
sealed class VoiceEvent {
  WakeWordDetected(phrase);
  SpeechStarted();
  SpeechEnded();
  AsrPartial(text);
  AsrFinal(text);
  IntentRecognized(intent);
  TtsStarted(handle);
  TtsCompleted(handle);
  TtsInterrupted(handle);
  VoiceEmotionDetected(feedback);
}
```

### 4.5 Agent 能力矩阵

| Agent                | ASR  | TTS  | EventBus 订阅 | LLM 位置                      |
| -------------------- | ---- | ---- | ------------- | ----------------------------- |
| Planner（训练计划）  | 低   | 低   | 中            | 云端                          |
| Analysis（成果分析） | 中   | 中   | 中            | 云端                          |
| Suggestion（建议）   | 中   | 高   | 高            | 云端                          |
| MusicCurator         | 低   | 低   | 中            | 云端                          |
| DJ Agent             | 低   | 中   | 高            | 规则路径无 LLM / LLM 路径云端 |
| FM Host              | 低   | 极高 | 高            | 云端                          |
| VoiceIntent          | 极高 | 低   | 高            | 本地                          |
| VoiceDialog          | 高   | 高   | 高            | 混合                          |
| VoiceFeedback        | 极高 | 无   | 中            | 本地                          |

## 5. 训练域 Agent 集群

### 5.1 Planner Agent（AI 创建训练计划）

**类型**：Planner Agent

**输入**：用户画像（年龄、体重、目标、器械、伤病史）、历史训练频率、偏好运动类型。

**工作流程**：

1. 接收用户输入，生成训练计划框架；
2. 调用 `ExerciseDatabaseTool` 查询匹配动作；
3. 输出严格 JSON Schema。

**输出结构**：

```json
{
  "weeks": [
    {
      "week_number": 1,
      "sessions": [
        {
          "day": "Monday",
          "focus": "下肢力量",
          "exercises": [
            {
              "name": "深蹲",
              "sets": 5,
              "reps": "5",
              "rest_seconds": 180,
              "target_rpe": 8,
              "safety_note": null
            }
          ]
        }
      ]
    }
  ],
  "safety_notes": "..."
}
```

**关键设计**：

- 强制 JSON Schema 校验，每一周为独立数组元素，禁止合并；
- 输出后自动重试机制（校验失败时重新生成）；
- 伤病史相关动作必须替换或加注 safety_note。

### 5.2 Analysis Agent（AI 分析训练成果）

**类型**：ReAct Agent

**输入**：训练日志（重量、组数、次数、RPE）、身体数据、训练频率。

**工具集**：

| 工具                   | 功能                         |
| ---------------------- | ---------------------------- |
| `WorkoutLogQueryTool`  | 按动作/时间段查询记录        |
| `ProgressAnalysisTool` | 计算容量、强度、渐进超负荷率 |
| `ComparePeriodsTool`   | 对比两个时间段指标           |
| `RecoverySignalTool`   | 获取主观恢复评分趋势         |

**输出原则**：

- 区分"事实陈述"与"推断判断"；
- 数据不足时明确说明，不编造趋势；
- 记忆复用：检索语义相似的历史分析，保持一致性。

### 5.3 Suggestion Agent（AI 给出下次建议）

**类型**：Multi-Agent

**编排结构**：

```
MultiAgent Coordinator
├── TrainingLoadExpert (ReAct)
│   └── 评估负荷：加量/减量/维持
├── RecoveryExpert (ReAct)
│   └── 基于 RPE、睡眠、疲劳判断恢复
├── PreferenceExpert (ReAct)
│   └── 读取偏好（器械、音乐氛围、时间）
└── Synthesizer (Planner)
    └── 综合输出建议 + 音乐情绪标签
```

**输出结构**：

```json
{
  "suggestion_type": "increase_load | maintain | deload | rest",
  "reasoning": "...",
  "next_session_focus": "下肢力量",
  "recommended_music_mood": "high_energy",
  "safety_flag": false
}
```

**安全约束**：若 `recovery_score < 2`（0-10 分制）或用户报告疼痛，suggestion_type 强制为 rest/deload。

**输出管线**：Synthesizer 输出 → `SafetyGuard` 独立硬规则校验（见 14.3.1）→ 触达用户。LLM 自评的 `safety_flag` 不具备放行效力。

## 6. 音乐域 Agent 集群

### 6.1 MusicCurator Agent（长期策展）

**类型**：Planner Agent + Vector Memory

**职责**：为每次训练、每个阶段生成专属音乐内容库。

**工具集**：

| 工具                        | 功能                   |
| --------------------------- | ---------------------- |
| `SearchMusicCatalogTool`    | 从音乐库检索           |
| `GetUserMusicHistoryTool`   | 读取跳过/循环/收藏行为 |
| `AnalyzeAudioTool`          | 音频特征分析           |
| `WorkoutIntensityCurveTool` | 获取训练强度曲线       |
| `SavePlaylistTool`          | 持久化歌单             |

**输出**：带 BPM 曲线的歌单（热身→主项→力竭→拉伸）。

### 6.2 DJ Agent（实时决策）

**类型**：Reactive Agent（低延迟事件响应）

**职责**：训练中基于实时信号动态调整音乐。

**触发信号与决策**：

| 信号                  | 决策                           |
| --------------------- | ------------------------------ |
| 进入力竭组（RPE ≥ 9） | 切换高 BPM 曲目，避免曲目结尾  |
| 组间休息超时 +30%     | 切换激励语音/换歌              |
| 心率恢复慢            | 降低 BPM                       |
| 用户跳过某曲          | 记录负反馈，同风格降权         |
| 用户循环某曲          | 记录强正反馈，加入"杀手锏"歌单 |

**性能约束（双路径）**：

| 路径         | 触发条件                                   | 延迟预算 | 说明                         |
| ------------ | ------------------------------------------ | -------- | ---------------------------- |
| 本地规则路径 | 预定义信号（力竭组、跳歌、循环、组间超时） | < 200ms  | 纯规则 + 本地 embedding 检索 |
| LLM 路径     | 用户明确语义诉求（"来点更炸的"）           | < 2s     | 云端 LLM，期间播放不打断     |

- 候选曲目预取到本地缓冲；
- LLM 路径失败/超时 → 自动降级为本地规则路径；
- 后台运行时仅保证本地规则路径可用（见 12.5）。

### 6.3 FM Host Agent（内容生成）

**类型**：Planner Agent + TTS 工具链

**职责**：模拟电台主播，生成实时语音内容。

**内容类型**：

1. 训练解说
2. 实时激励
3. 知识穿插
4. 成果播报
5. 过渡串词

**工具集**：

| 工具                       | 功能                         |
| -------------------------- | ---------------------------- |
| `GenerateHostScriptTool`   | 生成主播文案                 |
| `SynthesizeSpeechTool`     | TTS 合成                     |
| `GetWorkoutContextTool`    | 拉取训练上下文               |
| `ScheduleAudioSegmentTool` | 向 AudioArbiter 提交播报意图 |

**人格演化**：Host Agent 记录用户对话题的反应，形成个性化人格，存入 Summary Memory。

### 6.4 音乐版权方案

音乐是商用落地的硬约束，分阶段解决：

| 阶段   | 方案                       | 说明                                                                 |
| ------ | -------------------------- | -------------------------------------------------------------------- |
| MVP    | 免版税音乐库（CC0/买断制） | 接入 Artlist/Epidemic Sound 类授权库或自建买断曲库，无版税风险       |
| 成长期 | 对接用户已有音乐账号       | 通过 Apple Music API（MusicKit）播放用户自己的曲库，版权由平台侧解决 |
| 规模化 | 商务授权                   | 与唱片公司/版权代理直接签约                                          |

**红线**：未经授权的流媒体抓包/爬取曲目一律禁止。Apple Music API 限制：不支持音频特征（BPM）直接获取，BPM/能量分析需基于自有授权曲库或第三方元数据服务。

## 7. 语音域 Agent 集群

### 7.1 VoiceIntentAgent（意图路由）

**类型**：轻量 ReAct + 意图分类器

**输入**：ASR 文本 + 当前上下文

**输出**：

```dart
sealed class VoiceIntent {
  LogSetIntent(exercise, weight, reps);
  AdjustPlanIntent(action, params);
  MusicControlIntent(action, params);
  QueryIntent(question);
  FeedbackIntent(rating, target);
  ChatIntent(message);
  UnknownIntent(rawText);
}
```

**关键设计**：上下文感知——同样一句"换一首"，训练中 = 换音乐；FM 播报中 = 跳过主播片段。

### 7.2 VoiceDialogAgent（对话管理）

**类型**：Planner Agent + ConversationMemory

**约束**：

- 对话时长受限（2-3 轮内解决）；
- 可随时被用户打断；
- 识别不确定时主动澄清。

**状态机**：

```
Idle → Listening → Understanding → Clarifying(可选) → Confirming → Executing → Idle
                                          ↓
                                    用户打断 → Idle
```

### 7.3 VoiceFeedbackAgent（副语言捕捉）

**类型**：音频特征分析（本地模型）

**输入**：ASR 文本 + 音频特征（语速、音高、能量、停顿）

**输出**：

```dart
class VoiceFeedback {
  String? sentiment;        // positive / negative / neutral
  double? fatigueLevel;     // 0-1
  double? motivationLevel;  // 0-1
  bool? isStruggling;       // 是否挣扎
  double? confidence;
}
```

**用途**：用户说"还行"但语速慢、音高低 → 判定疲劳 → 广播给 DJ（切换舒缓）和 RecoveryExpert（下次减量）。

## 8. Voice I/O 基础设施层

### 8.1 核心能力

| 能力       | 说明               | 选型                            |
| ---------- | ------------------ | ------------------------------- |
| VAD        | 判断是否在说话     | Silero VAD / WebRTC VAD（本地） |
| 唤醒词     | "Hey Coach" 唤醒   | Porcupine（本地）               |
| ASR        | 语音转文字         | 见 8.2                          |
| TTS        | 文字转语音         | 见 8.3                          |
| 说话人识别 | 区分用户 vs 噪音   | 声纹 embedding                  |
| 音频路由   | 与音乐混音/ducking | AudioQueueManager               |

### 8.2 ASR 引擎选型

| 方案                        | 优点               | 缺点             | 适用     |
| --------------------------- | ------------------ | ---------------- | -------- |
| Whisper.cpp（本地）         | 完全离线、准确率高 | 首次加载慢       | 主力     |
| Apple/Android 系统 ASR      | 零成本             | 隐私、可定制性差 | 备用     |
| 云端（Azure/讯飞/Deepgram） | 准确率最高         | 需网络、延迟     | 联网增强 |

**决策**：默认 Whisper.cpp base 模型本地运行（~150MB），复杂语义调用云端。

### 8.3 TTS 引擎选型

| 方案              | 优点           | 缺点         | 适用         |
| ----------------- | -------------- | ------------ | ------------ |
| flutter_tts       | 零成本、离线   | 机械         | 快速播报     |
| Piper TTS（本地） | 离线、自然     | 模型大       | 主力离线     |
| ElevenLabs/Azure  | 最自然、可定制 | 需网络、成本 | FM Host 主播 |

**决策**：

- 训练指令/数据播报 → 本地（flutter_tts / Piper）
- FM Host 主播 → 云端（ElevenLabs / Azure）
- 实时激励 → 预合成缓存片段

### 8.4 统一 API

```dart
abstract class VoiceIO {
  // ASR
  Stream<AsrResult> listen({AsrMode mode});
  Future<void> stopListening();
  bool get isListening;

  // TTS
  Future<TtsHandle> speak(String text, {TtsStyle style});
  Future<void> stopSpeaking();

  // VAD / 唤醒
  Stream<WakeEvent> get onWakeWord;

  // 音频路由
  void setDucking(bool enabled);
  void setOutputChannel(OutputChannel channel);
}
```

### 8.5 交互模式

| 模式      | 触发        | 行为             | 场景     |
| --------- | ----------- | ---------------- | -------- |
| Passive   | 默认        | 只监听唤醒词     | 训练中   |
| Active    | 唤醒词/按钮 | 持续监听         | 主动查询 |
| Dictation | 长按/短语   | 长语音输入       | 复杂诉求 |
| Ambient   | 训练中自动  | 只提取副语言信息 | 情绪捕捉 |
| Silent    | 用户选择    | 关闭麦克风       | 隐私敏感 |

**默认**：训练中为 Passive + Ambient。

### 8.6 唤醒词与快捷短语

- **主唤醒词**："Hey Coach" / "嘿，教练"
- **免唤醒快捷短语**（Ambient 模式识别）：
  - "停" / "停一下" → 暂停
  - "加一组" → 记录额外组
  - "太重了" → 减重建议
  - "破纪录了" → PR 流程
  - "换歌" → 音乐控制

### 8.7 流式 ASR 与意图识别的交互

为压缩端到端延迟，ASR 与意图识别不是严格的串行关系：

1. **Partial 预分类**：`AsrPartial` 事件到达时，VoiceIntentAgent 用本地规则分类器做**预分类**（高置信度的快捷短语，如"换歌""停"，可直接命中）；预分类结果仅作预热，不执行动作。
2. **Final 定夺**：VAD 判定语音结束 → Whisper 出 `AsrFinal` → 完整意图分类。若与预分类一致，直接执行（节省 200-400ms）；不一致则以 Final 为准。
3. **早判中止**：partial 阶段若检测到明确中止意图（"算了""停"），立即中断当前 TTS/对话流程，不等 Final。
4. **并行上下文拉取**：partial 预分类的同时并行拉取训练上下文（当前动作、组数、RPE），决策前汇合。

**约束**：预分类置信度 < 0.8 时不得预热任何有副作用的动作（如写入训练记录）。

## 9. 事件总线（EventBus）

### 9.1 设计目标

- 训练域、音乐域、语音域**去中心化响应**同一事件；
- 事件类型强类型化；
- 支持一对多广播；
- 事件可携带上下文；
- 高频事件下不丢失、不阻塞、可排查。

### 9.1.1 背压（Backpressure）策略

高频事件（如 `SetCompleted`、`FatigueDetected`）会同时扇出给多个 Agent，必须定义处理不及时的行为：

| 策略        | 适用事件                                 | 行为                                                      |
| ----------- | ---------------------------------------- | --------------------------------------------------------- |
| `latest`    | `AsrPartial`、`EnergyTrend` 等状态流事件 | 只保留最新值，丢弃过期事件                                |
| `buffer(N)` | `SetCompleted`、`RestStarted` 等业务事件 | 每订阅者独立队列（容量 N=32），溢出时丢弃最旧并记警告日志 |
| `blocking`  | `PersonalRecordAttempt` 等关键事件       | 不允许丢弃，生产端等待消费                                |

### 9.1.2 事件优先级

事件按优先级投递，同级 FIFO：

```
P0 安全类    : FatigueDetected(高), SafetyAlert
P1 用户指令类: AsrFinal, IntentRecognized, WakeWordDetected
P2 训练状态类: SetCompleted, RestStarted/Ended, PersonalRecordAttempt
P3 内容类    : TrackSkipped, MoodFeedback, AsrPartial
```

`FatigueDetected` 携带 `level` 字段，`level >= 0.8` 时升级为 P0。

### 9.1.3 错误处理与死信

- 订阅者处理异常不阻塞其他订阅者（每订阅者独立隔离执行）；
- 单事件连续处理失败 3 次 → 进入**死信队列**（内存 + 落盘 `event_dead_letter` 表），开发/诊断界面可查看；
- 关键事件（P0/P1）失败时向 UI 层上报，必要时提示用户。

### 9.1.4 事件溯源与调试

- 所有事件附带 `eventId`（UUID）、`timestamp`、`sourceAgent`、`traceId`；
- 训练会话期间事件全量写入 `event_log` 表（训练结束 7 天后自动清理）；
- 支持按 `traceId` 回放单次训练的事件序列，用于跨域联动问题的排查。

### 9.2 跨域协作示例

**场景：用户在深蹲 PR 尝试时**

```
1. WorkoutLogTool 检测到 PR 尝试
   ↓ 发出 PersonalRecordAttempt 事件
2. DJ Agent 接收：
   - 暂停常规歌单
   - 切换到 "PR Anthem" 歌单
3. FM Host Agent 接收：
   - 生成实时播报："这是你的 PR 尝试..."
   - TTS 合成并插入队列
4. 用户成功
   ↓ PersonalRecord 事件
5. 两个 Agent 都接收：
   - DJ: 播放庆祝曲目
   - Host: 实时生成祝贺词
```

**关键点**：不是训练 Agent 单向"通知"音乐 Agent，而是双方通过 EventBus 各自响应同一事件。

### 9.3 事件流示例

```
TrainingEvent.SetCompleted
  ├─→ Analysis Agent（写入日志）
  ├─→ DJ Agent（判断是否调整音乐）
  ├─→ FM Host Agent（可能播报）
  └─→ VoiceFeedbackAgent（记录上下文）

VoiceEvent.VoiceEmotionDetected
  ├─→ RecoveryExpert（影响下次建议）
  ├─→ DJ Agent（调整音乐）
  └─→ FM Host Agent（调整语气）
```

## 10. 数据与记忆架构

### 10.1 本地优先策略

核心训练数据存储在本地 SQLite，AI Agent 与 App 共享同一数据库。

| 表                  | 用途                            |
| ------------------- | ------------------------------- |
| `users_profile`     | 用户画像、目标、器械条件        |
| `workout_logs`      | 每次训练的动作/组/次数/重量/RPE |
| `training_plans`    | AI 生成的计划（含版本标记）     |
| `agent_memory`      | Conatus 对话/分析记忆           |
| `music_preferences` | 音乐偏好记录                    |
| `voice_history`     | 语音识别记录（可删除）          |
| `playlists`         | 生成的歌单                      |
| `host_persona`      | FM 主播人格记忆                 |
| `event_log`         | 事件溯源日志（7 天自动清理）    |
| `event_dead_letter` | EventBus 死信队列               |

### 10.2 记忆分层

| 类型               | 存储                       | 用途             | 淘汰策略                                   |
| ------------------ | -------------------------- | ---------------- | ------------------------------------------ |
| **Working Memory** | 滑动窗口（最近 20 条消息） | 单次会话上下文   | 会话结束即弃，摘要写入 Summary             |
| **Summary Memory** | 训练历史摘要               | 跨会话长期上下文 | 每域上限 50 条，超出时按时间合并最旧条目   |
| **Vector Memory**  | 语义嵌入                   | 相似场景检索     | LRU + 90 天未命中自动清理，容量上限 10k 条 |

#### 10.2.1 Embedding 模型选型

| 方案                   | 体积  | 说明                                       |
| ---------------------- | ----- | ------------------------------------------ |
| MiniLM-L6（ONNX 量化） | ~25MB | **默认**：本地运行，中英文可用，端上 <50ms |
| 云端 embedding API     | 0     | 可选增强，联网时使用                       |

**决策**：默认本地 MiniLM-L6 量化版。曲目/训练情境 embedding 维度 384，检索用余弦相似度最近邻。

#### 10.2.2 向量存储选型

移动端使用 `sqlite-vec`（SQLite 扩展，零额外依赖，复用现有本地库）；不引入 ObjectBox（其向量索引能力对移动端过重）。

#### 10.2.3 Context 拼装预算

单次 LLM 调用的记忆注入遵循 token 预算：Working Memory ≤ 2k tokens，Summary ≤ 1k tokens，Vector 检索 Top-5 ≤ 500 tokens，超出截断。

### 10.3 三域记忆细化

**训练记忆**：

- 训练历史摘要（"过去 4 周下肢容量增长 12%"）
- 语义嵌入的历史建议
- 用户反馈的正负样本

**音乐记忆**：

- 行为记忆（跳过/循环/完成率，按训练阶段索引）
- 偏好记忆（评分、收藏、曲风偏好向量）
- 情境记忆（"在深蹲 PR 时这首效果最好"）

**语音记忆**：

- 语音识别记录（用户可控删除）
- 副语言反馈历史
- 对话历史

### 10.4 偏好学习机制

**隐式反馈**：

- 跳歌 = 负样本（同曲风、同 BPM 降权）
- 循环 = 强正样本
- 力竭组没跳歌 = 弱正样本

**显式反馈**：

- 播放器"适合训练"快速评分
- 训练后弹窗："今天哪首歌最带动你？"

**向量化存储**：曲目 embedding = `(曲风, BPM, 能量, 情绪)`，训练情境 embedding = `(训练阶段, 强度, 疲劳度)`，检索即最近邻。

## 11. 工具层设计

### 11.0 工具规范

**命名约定**：统一 `PascalCase` + `Tool` 后缀（如 `WorkoutLogQueryTool`）。全文以此为准。

**错误契约**：每个工具必须定义：

```dart
abstract class ConatusTool<I, O> {
  String get name;
  JsonSchema get inputSchema;    // 输入参数 Schema
  JsonSchema get outputSchema;   // 返回值 Schema
  Duration get timeout;          // 超时（默认 5s）

  Future<ToolResult<O>> call(I input);
}

sealed class ToolResult<O> {
  Ok(O value);                          // 成功
  RetryableError(message);              // 可重试（网络抖动等），Agent 可自动重试 ≤ 2 次
  FatalError(message, suggestion);      // 不可重试，Agent 应降级或告知用户
}
```

- 工具超时未返回按 `RetryableError` 处理；
- Agent 收到 `FatalError` 时不得静默吞掉，必须降级或经 TTS/UI 告知用户；
- 音频类工具（11.4）不直接操作播放器，统一向 `AudioArbiter` 提交意图（见 12.1）。

### 11.1 训练工具

| 工具                   | 功能                   | 实现     |
| ---------------------- | ---------------------- | -------- |
| `ExerciseDatabaseTool` | 查询动作库             | SQLite   |
| `WorkoutLogQueryTool`  | 查询训练记录           | SQLite   |
| `WorkoutLogWriteTool`  | 写入训练记录           | SQLite   |
| `ProgressAnalysisTool` | 计算容量/强度/超负荷率 | Dart     |
| `RecoverySignalTool`   | 获取恢复评分           | 日志查询 |
| `ComparePeriodsTool`   | 对比时间段             | 统计计算 |

### 11.2 音乐工具

| 工具                        | 功能             |
| --------------------------- | ---------------- |
| `SearchMusicCatalogTool`    | 音乐库检索       |
| `SearchTrackTool`           | 曲目搜索         |
| `StreamFMTool`              | FM 流接入        |
| `AnalyzeAudioTool`          | BPM/能量分析     |
| `MoodMappingTool`           | 情绪标签映射     |
| `SavePlaylistTool`          | 歌单持久化       |
| `GetUserMusicHistoryTool`   | 音乐历史         |
| `WorkoutIntensityCurveTool` | 训练强度曲线查询 |

### 11.3 语音工具

| 工具                     | 功能         |
| ------------------------ | ------------ |
| `ListenTool`             | 开启语音监听 |
| `SpeakTool`              | 主动播报     |
| `SpeakAndListenTool`     | 播报+监听    |
| `DetectVoiceEmotionTool` | 副语言提取   |
| `SynthesizeSpeechTool`   | TTS 合成     |

### 11.4 音频路由工具

本组工具均为 `AudioArbiter` 的意图提交接口（见 12.1），不直接操作播放器。

| 工具                       | 功能                  |
| -------------------------- | --------------------- |
| `MixAudioTool`             | 提交混音队列操作意图  |
| `SetDuckingTool`           | 提交 ducking 控制意图 |
| `ScheduleAudioSegmentTool` | 提交音频片段插入意图  |

## 12. 播放器与音频架构

### 12.1 AudioArbiter（音频仲裁器）

**问题**：DJ Agent、FM Host Agent、VoiceDialogAgent 都会产生音频输出。若各自直接操作播放队列，会出现声音打架（主播被切歌打断、语音与音乐不闪避等）。

**设计**：`AudioArbiter` 是唯一音频调度入口。Agent 不直接操作播放器，而是提交**音频意图（AudioIntent）**，由 Arbiter 统一仲裁。

```dart
sealed class AudioIntent {
  PlayMusicIntent(trackId, fadeIn);        // 音乐
  SwitchTrackIntent(trackId, crossfade);   // 切歌
  SpeakIntent(text, priority, style);      // TTS 播报
  InterruptIntent(reason);                 // 打断当前播报
}

// 优先级（高 → 低），高优先级意图可抢占低优先级
enum AudioPriority {
  userCommand,   // 用户语音指令的即时反馈（"已记录""已暂停"）
  safetyAlert,   // 安全相关播报（姿态警告、强制休息）
  hostSegment,   // FM 主播片段
  musicSwitch,   // DJ 切歌
}
```

**仲裁规则**：

1. 任一 `SpeakIntent` 播放期间，音乐自动 ducking 至 30%；
2. `userCommand`/`safetyAlert` 可打断 `hostSegment`（主播片段支持断点续播或直接丢弃，由 Host Agent 决策）；
3. `musicSwitch` 永不打断正在播放的语音，排队至语音结束后执行；
4. 同一优先级按提交时间 FIFO；
5. 训练中（非组间休息）只允许 `userCommand`/`safetyAlert`，长内容自动延迟到下一个 `RestStarted` 事件。

### 12.2 混音队列结构

```
AudioQueue:
  ├── MusicTrack A (0:00 - 3:45)
  ├── HostVoiceSegment (3:45 - 3:52)  ← 音乐 ducking
  ├── MusicTrack B (3:52 - 7:20)
  ├── MusicTrack C (7:20 - ...)       ← DJ 可随时插入/替换
  └── ...
```

### 12.3 关键能力

| 能力         | 实现                                     |
| ------------ | ---------------------------------------- |
| Ducking      | Arbiter 统一控制，语音播放时音乐降至 30% |
| 交叉淡入淡出 | 曲目切换 2 秒过渡                        |
| 动态插入     | DJ Agent 经 Arbiter 提交，不直接操作队列 |
| 预缓冲       | 候选曲目提前 30 秒缓冲                   |
| FM 流接入    | 真实 FM 电台流 + AI 主播叠加             |

### 12.4 音频引擎选型

**关键约束**：`just_audio` 仅支持单播放器实例串联播放（ConcatenatingAudioSource），**不原生支持多轨实时混音与精准 ducking**。混音能力需要独立的语音轨与音乐轨并行输出。

| 层级         | 方案                                                                      |
| ------------ | ------------------------------------------------------------------------- |
| 音乐轨       | `just_audio`（歌单、淡入淡出、预缓冲）                                    |
| 语音轨       | 独立 `AudioPlayer` 实例 / `flutter_soloud`                                |
| 混音/Ducking | iOS：`AVAudioEngine` 混音节点；Android：`Oboe`/双 `AudioTrack` + 音量包络 |
| 仲裁         | 自定义 `AudioArbiter`（纯 Dart，位于引擎之上）                            |
| 后台服务     | `audio_service`                                                           |
| 锁屏控制     | `just_audio_background`                                                   |
| TTS          | `flutter_tts` / `piper_tts`                                               |

**降级方案（MVP）**：Phase 3-4 可先以「双 `just_audio` 实例 + 手动音量包络」实现 ducking，待 Phase 6 再下沉到原生混音引擎。

### 12.5 后台运行与 Agent 生命周期

- **iOS**：`audio_service` 保活音频会话期间，Dart 侧代码可持续运行；但 LLM 网络请求不受 audio background mode 保护，需用 `background_fetch`/静默推送兜底。
- **Android**：前台服务（Foreground Service）持有音频播放，Agent 事件循环随进程存活。
- **DJ Agent 后台响应**：`SetCompleted` 等事件经 EventBus 送达时，DJ 的**本地规则路径**（无 LLM）必须可在后台完成；LLM 路径在网络受限时可降级为规则决策。
- **锁屏限制**：iOS 锁屏后云端 TTS（FM Host）可能延迟，FM 长播报需提前预生成并缓存到本地队列。

## 13. Prompt 工程

### 13.1 训练计划生成 Prompt

```
你是{{coach_certification}}认证体能教练。根据以下用户信息生成 {{weeks}} 周训练计划。

用户信息：
- 目标：{{goal}}
- 水平：{{fitness_level}}
- 可用天数：{{days_per_week}}
- 器械条件：{{equipment}}
- 伤病史：{{injuries}}

约束：
1. 每周为独立 JSON 对象，不得合并周次
2. 每个 session 包含动作、组数、次数范围、休息秒数、RPE 目标
3. 伤病史相关动作必须替换或加注 safety_note
4. 输出必须可通过 JSON.parse()

输出 Schema：...
```

### 13.2 成果分析 Prompt 要点

- 区分"观察"与"推断"
- 数据不足时说"数据不足"，不编造趋势
- 记忆复用：检索历史分析保持一致性

### 13.3 建议生成 System Prompt

```
你是用户的专属健身顾问。基于以下信息生成下一次训练建议：

- 训练历史：{{workout_history}}
- 恢复状态：{{recovery_signals}}
- 用户偏好：{{preferences}}

约束：
1. 若 recovery_score < 2 或用户报告疼痛，建议类型必须为 rest/deload
2. 区分观察与推断
3. 语气应促进用户维持训练行为，而非制造焦虑
4. 输出必须包含 reasoning 字段

输出 JSON：{ suggestion_type, reasoning, next_session_focus, recommended_music_mood, safety_flag }
```

### 13.4 DJ Agent System Prompt

```
你是训练场景的实时 DJ。你的决策必须：
1. 本地规则路径在 200ms 内完成；LLM 路径在 2s 内完成（超时自动降级为规则路径）
2. 优先考虑训练节奏连续性，避免在组中切歌
3. 只在组间休息或检测到明确信号时调整
4. 每个决策附带简短 reason，写入记忆

可用即时信号：{{recent_training_events}}
当前播放：{{current_track}}
用户偏好摘要：{{preference_summary}}

输出：{ action: switch|keep|insert_voice, track_id?, reason }
```

### 13.5 FM Host Agent System Prompt

```
你是用户专属的健身电台主播，风格：{{host_persona}}。
基于当前训练上下文，生成一段不超过 15 秒的播报。

上下文：
- 当前训练：{{workout_focus}}
- 最近成就：{{recent_prs}}
- 用户偏好话题：{{preferred_topics}}
- 当前情绪信号：{{mood_signal}}

约束：
1. 不制造焦虑，不贬低用户
2. 数据必须真实，不得编造
3. 若用户状态差，以共情为主
4. 口播风格：{{tone}}
```

### 13.6 VoiceDialogAgent System Prompt

```
你是健身 App 的语音助手。用户正在训练，双手被占用。

约束：
1. 回复必须简短——单次不超过 20 字
2. 不打断训练节奏——复杂信息拆分到组间休息播报
3. 识别不确定时主动澄清，不猜测
4. 用户说"停"/"算了"立即中止当前动作
5. 检测到用户喘气/语速慢，优先确认状态而非执行指令

当前上下文：{{workout_context}}
用户最近一次识别：{{last_asr}}
对话历史：{{conversation_history}}

输出格式：{ reply, action?, needs_clarification? }
```

### 13.7 VoiceFeedbackAgent Prompt

```
分析以下语音特征，判断用户状态：

音频特征：
- 语速：{{speech_rate}} 字/秒
- 平均音高：{{pitch_hz}}
- 能量：{{energy_db}}
- 停顿次数：{{pause_count}}
- 文本内容：{{transcript}}

输出 JSON：
{
  "sentiment": "positive|negative|neutral",
  "fatigue_level": 0.0-1.0,
  "motivation_level": 0.0-1.0,
  "is_struggling": true|false,
  "confidence": 0.0-1.0
}

注意：只基于可观测特征推断，不确定时 confidence 低于 0.5。
```

## 14. 隐私与安全

### 14.1 语音隐私

1. **本地优先**：ASR 默认本地（Whisper.cpp），音频不出设备；
2. **明确指示**：录音时 UI 有红点/呼吸灯；
3. **一键关闭**：设置中可完全关闭麦克风；
4. **数据可控**：用户可查看/删除所有语音识别记录；
5. **云端最小化**：只有显式选择"云端增强"才上传，且只上传需识别片段。

#### 14.1.1 语音数据生命周期

| 数据类型         | 保存位置           | 保留策略                                                       |
| ---------------- | ------------------ | -------------------------------------------------------------- |
| 原始音频         | 内存               | 识别完成即销毁，**不落盘**                                     |
| ASR 文本记录     | `voice_history` 表 | 用户可查看/单条删除/一键清空；默认保留 30 天                   |
| 副语言特征       | 本地               | 仅存特征值（语速/音高/能量），视为敏感数据，随语音记录一并删除 |
| 云端增强上传片段 | 服务端             | 仅用于当次识别，服务端不持久化（需在服务协议中声明）           |

### 14.2 训练数据隐私

- 本地 SQLite 存储，不强制云端同步；
- 云端 LLM 调用时，用户数据脱敏后传输；
- 用户可选择完全本地模式（牺牲部分 AI 能力）。

### 14.3 建议安全约束

- `recovery_score < 2`（0-10 分制，来自 RecoverySignalTool 的主观恢复评分）或报告疼痛 → 强制 rest/deload；
- 伤病史动作替换或加注 safety_note；
- 涉及负荷建议必须有 reasoning 字段可追溯。

#### 14.3.1 SafetyGuard（独立安全校验层）

**问题**：Suggestion Agent 的 `safety_flag` 由 LLM 自评生成，属于自己审自己，不能作为唯一防线。

**设计**：`SafetyGuard` 是独立于 LLM 的**纯规则校验层**（无模型、硬编码规则），所有涉及身体负荷的输出（训练计划、下次建议、负荷调整）必须经过 SafetyGuard 校验后才能触达用户。

**硬规则**：

| 规则                                | 动作                                         |
| ----------------------------------- | -------------------------------------------- |
| `recovery_score < 2` 或用户报告疼痛 | `suggestion_type` 强制改写为 `rest`/`deload` |
| 单次负荷增幅 > 10%                  | 截断至 10% 并加注 reasoning                  |
| 伤病史相关动作出现且未替换          | 拦截，要求 Planner 重新生成                  |
| RPE 目标 > 9 且连续 > 3 天          | 强制插入恢复日                               |

- SafetyGuard 的每次改写/拦截写入 `event_log`，可追溯；
- LLM 输出的 `safety_flag` 仅作为参考信号，不具备放行/拦截效力。

## 15. 性能与延迟预算

### 15.1 语音交互延迟

延迟预算基于**串行路径**核算（不含并行优化），并标注可并行环节：

| 环节        | 目标延迟                             | 实现              | 可并行性                     |
| ----------- | ------------------------------------ | ----------------- | ---------------------------- |
| VAD 检测    | < 100ms                              | 本地轻量模型      | —                            |
| 唤醒词      | < 200ms                              | Porcupine 本地    | —                            |
| ASR（短句） | < 500ms                              | Whisper.cpp base  | 流式输出，与意图识别部分重叠 |
| 意图识别    | < 200ms                              | 本地分类器+规则   | 与上下文拉取并行             |
| 上下文拉取  | < 150ms                              | SQLite/内存缓存   | 与意图识别并行               |
| Agent 决策  | < 500ms                              | 轻量模型          | —                            |
| TTS 合成    | < 300ms                              | 本地 Piper/预合成 | 高频回复预合成可降至 < 50ms  |
| **端到端**  | **< 2s**（目标），**< 2.5s**（上限） |                   | 预合成 TTS 命中时可达 < 1.5s |

**优化手段**：

- 流式 ASR：VAD 检测到语音结束即出最终文本，partial 结果提前触发意图预分类（见 8.7）；
- 预测性 TTS（常见回复预合成）；
- 意图识别与上下文拉取并行，决策前汇合。

### 15.2 DJ 决策延迟

- 本地规则路径：< 200ms（占绝大多数决策）；
- LLM 路径：< 2s，超时/失败自动降级为规则路径；
- 候选曲目预取到本地缓冲。

### 15.3 Agent 推理延迟

| Agent                       | 目标延迟 | LLM 位置         |
| --------------------------- | -------- | ---------------- |
| DJ Agent（规则路径）        | < 200ms  | 无 LLM           |
| DJ Agent（LLM 路径）        | < 2s     | 云端             |
| VoiceIntent                 | < 300ms  | 本地             |
| VoiceFeedback               | < 200ms  | 本地             |
| VoiceDialog                 | < 1s     | 混合             |
| FM Host                     | < 2s     | 云端（可预生成） |
| Planner/Analysis/Suggestion | < 5s     | 云端             |

## 16. 技术选型汇总

### 16.1 Flutter 端

| 能力         | 包/方案                                                                                                           |
| ------------ | ----------------------------------------------------------------------------------------------------------------- |
| 状态管理     | Riverpod / Bloc                                                                                                   |
| 本地数据库   | `sqflite` / `drift`                                                                                               |
| 向量存储     | `sqlite-vec`                                                                                                      |
| Embedding    | MiniLM-L6（ONNX 量化，本地）                                                                                      |
| 录音         | `record` / `flutter_sound`                                                                                        |
| VAD          | `vad` / Silero ONNX                                                                                               |
| 唤醒词       | `porcupine_flutter`                                                                                               |
| ASR（本地）  | `whisper_ggml` / whisper.cpp FFI                                                                                  |
| ASR（云端）  | `azure_speech` / Whisper API                                                                                      |
| TTS（本地）  | `flutter_tts` / `piper_tts`                                                                                       |
| TTS（云端）  | ElevenLabs API / Azure Neural                                                                                     |
| 音乐播放     | `just_audio`                                                                                                      |
| 混音/Ducking | MVP：双 `just_audio` 实例 + 音量包络；完整：原生混音引擎（iOS AVAudioEngine / Android Oboe），或 `flutter_soloud` |
| 音频仲裁     | 自定义 `AudioArbiter`（纯 Dart）                                                                                  |
| 后台播放     | `audio_service`                                                                                                   |
| 锁屏控制     | `just_audio_background`                                                                                           |
| 音频特征     | `fftea` / 原生 FFI                                                                                                |
| 安全存储     | `flutter_secure_storage`                                                                                          |

### 16.2 服务端（可选）

| 能力       | 方案                    |
| ---------- | ----------------------- |
| ASR 增强   | 自托管 Whisper large-v3 |
| TTS 增强   | 自托管 XTTS / CosyVoice |
| 声纹识别   | 自训练 embedding        |
| 情绪识别   | emotion2vec             |
| LLM        | GPT-4 / Claude / Gemini |
| 向量数据库 | Qdrant / Pinecone       |

## 17. 典型端到端场景

### 17.1 场景 A：完整训练流程（全程语音）

```
[T-5min] MusicCurator Agent 生成今日歌单
[T-0]    FM Host 播报开场白（云端 TTS）
         ↓
[训练中]
├─ 用户："Hey Coach，今天练什么？"
│  → ASR(本地) → Intent(Query) → Dialog → TTS(本地) "上肢，卧推为主"
│
├─ 用户："深蹲 100 公斤 5 次"
│  → ASR → Intent(LogSet) → WorkoutLogTool 写入
│  → TTS "已记录"（预合成，<100ms）
│
├─ [进入力竭组]
│  → VoiceFeedbackAgent 检测呼吸急促
│  → EventBus 广播 FatigueSignal
│  → DJ Agent 切换高 BPM 曲目
│  → FM Host 播报激励（云端 TTS）
│
├─ 用户："太重了"
│  → ASR → Intent(Feedback) → RecoveryExpert 记录
│  → TTS "下一组减 5 公斤，注意姿势"
│
└─ 用户："换首歌"
   → ASR → Intent(MusicControl) → DJ Agent 执行

[训练结束]
├─ FM Host 总结播报（云端 TTS）
├─ VoiceDialogAgent："今天感觉怎么样？"
├─ 用户："腿有点酸"
│  → ASR → Intent(Feedback) → 写入记忆
│  → 影响下次建议
└─ 生成成果分析 + 下次建议
```

### 17.2 场景 B：PR 时刻跨域联动

```
1. WorkoutLogTool 检测 PR 尝试
   ↓ PersonalRecordAttempt 事件
2. DJ Agent：切换到 "PR Anthem" 歌单
3. FM Host：生成播报 + TTS 合成
4. 用户成功 → PersonalRecord 事件
5. DJ：播放庆祝曲目
6. Host：实时祝贺 + 记录到记忆
```

### 17.3 场景 C：组间问答

```
用户（喘气）："呼……下一组多少来着？"

1. ASR：识别文本 + VAD 检测呼吸急促
2. VoiceIntentAgent：QueryIntent + 语境（深蹲）
3. VoiceDialogAgent：拉取训练状态
4. TTS：播报"下一组 100 公斤，目标 5 次，已完成 2 组"
5. VoiceFeedbackAgent：检测疲劳度上升 → FatigueSignal
6. DJ Agent：下一首 BPM 降低 10
7. RecoveryExpert：记录疲劳信号，影响下次建议

一次交互，触发三域联动。
```

### 17.4 场景 D：有氧闲聊

```
用户："Hey Coach，给我讲点有意思的。"

1. 唤醒词触发（本地 Porcupine）
2. VoiceIntentAgent：ChatIntent
3. VoiceDialogAgent：调用 FM Host 即兴聊天
4. FM Host：生成趣闻 + TTS
5. 音频路由：音乐 ducking，主播声音混入
6. 用户："哈哈，再来一个"
7. VoiceFeedbackAgent：positive → 强化类似话题
```

## 18. 实施路线图

### Phase 1：训练域基础

- Planner Agent + 训练计划生成
- SQLite 存储
- 基础触屏 UI

### Phase 2：训练域完整

- Analysis Agent + 成果分析
- Suggestion Agent + Multi-Agent 建议
- 训练历史可视化

### Phase 3：音乐域基础

- MusicCurator Agent + 静态歌单
- 基础播放器（just_audio）
- 偏好记忆

### Phase 4：EventBus + 实时音乐

- EventBus 实现
- DJ Agent（规则先行，LLM 后置）
- 双向联动
- TTS 集成（flutter_tts + Piper）
- FM Host 基础播报

### Phase 5：ASR + 语音交互

- ASR 集成（Whisper.cpp）
- VoiceIntentAgent
- VoiceDialogAgent
- 唤醒词（Porcupine）

### Phase 6：语音智能化

- VoiceFeedbackAgent + 副语言分析
- 跨域协同
- 混音队列 + ducking

### Phase 7：优化与打磨

- 云端 TTS/ASR 增强
- 主播人格演化
- 延迟优化
- 隐私控制 UI

**关键里程碑**：Phase 5 完成时，用户可实现"全程不碰手机完成一次训练"。

## 19. 风险与对策

| 风险                        | 影响             | 对策                             |
| --------------------------- | ---------------- | -------------------------------- |
| LLM 输出结构不稳定          | 训练计划无法解析 | JSON Schema 校验 + 自动重试      |
| ASR 嘈杂环境准确率低        | 语音交互失败     | VAD 增强 + 上下文纠错 + 云端兜底 |
| 端到端延迟超 2.5s           | 用户重复说话     | 流式 ASR + 预合成 TTS            |
| TTS 打断训练节奏            | 体验差           | 只在组间休息播报长内容           |
| 语音隐私担忧                | 用户关闭麦克风   | 本地优先 + 明确指示 + 一键关闭   |
| 音乐版权                    | 法律风险         | 见 6.4 音乐版权方案              |
| FM 主播内容不当             | 品牌风险         | Prompt 约束 + 敏感词过滤         |
| 建议导致受伤                | 安全风险         | 安全约束优先 + 免责声明          |
| 电池消耗（持续监听）        | 续航差           | Passive 模式低功耗 + 智能唤醒    |
| 模型体积大（Whisper/Piper） | 安装包大         | 按需下载 + 量化模型              |

## 20. 附录

### 20.1 术语表

| 术语           | 说明                                     |
| -------------- | ---------------------------------------- |
| Agent          | 具备推理和工具调用能力的 AI 智能体       |
| Conatus        | 本项目使用的 Agent 框架                  |
| EventBus       | 事件总线，用于跨域 Agent 通信            |
| ASR            | Automatic Speech Recognition，语音识别   |
| TTS            | Text-to-Speech，语音合成                 |
| VAD            | Voice Activity Detection，语音活动检测   |
| RPE            | Rating of Perceived Exertion，主观疲劳度 |
| PR             | Personal Record，个人纪录                |
| Ducking        | 音频闪避，语音播放时降低背景音乐音量     |
| Reactive Agent | 低频 ReAct + 高频事件响应混合模式        |
| Multi-Agent    | 多 Agent 协作模式                        |

### 20.2 架构决策记录（ADR）摘要

| 编号   | 决策                       | 理由                                                 |
| ------ | -------------------------- | ---------------------------------------------------- |
| ADR-01 | 音乐域独立为 Agent 集群    | 音乐是核心能力，不是附属模块                         |
| ADR-02 | EventBus 去中心化响应      | 避免训练域主导音乐域                                 |
| ADR-03 | Voice I/O 独立成层         | 三域共享，避免私有化                                 |
| ADR-04 | ASR 默认本地               | 隐私 + 离线可用                                      |
| ADR-05 | TTS 分层策略               | 延迟 vs 自然度的平衡                                 |
| ADR-06 | 音乐记忆分三层             | 支持长期策展 + 实时决策                              |
| ADR-07 | 副语言信息作为决策输入     | 捕捉用户隐性状态                                     |
| ADR-08 | 结构化输出强制 Schema      | 避免 LLM 结构问题                                    |
| ADR-09 | AudioArbiter 统一音频仲裁  | 多 Agent 并发音频输出，必须单一调度入口避免声音打架  |
| ADR-10 | SafetyGuard 独立硬规则校验 | LLM 自评不能作为安全防线，负荷建议必须经纯规则层校验 |
| ADR-11 | EventBus 背压与死信机制    | 高频事件下保证不丢失、可排查                         |
| ADR-12 | 向量存储用 sqlite-vec      | 零额外依赖，复用本地 SQLite，避免引入 ObjectBox      |
| ADR-13 | DJ 双路径决策              | 规则路径保延迟，LLM 路径保语义理解，超时自动降级     |
| ADR-14 | 音乐版权分阶段方案         | MVP 免版税曲库 → MusicKit 用户曲库 → 商务授权        |

### 20.3 版本历史

| 版本 | 变更                                                                                                                                                                                                                                                                                            |
| ---- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| v0.1 | 初版：训练域三大 Agent + 音乐作为辅助                                                                                                                                                                                                                                                           |
| v0.2 | 音乐升级为 AI 驱动核心域，新增音乐域 Agent 集群                                                                                                                                                                                                                                                 |
| v0.3 | 新增 ASR/TTS，语音升级为独立域                                                                                                                                                                                                                                                                  |
| v1.0 | 完整整合，三域平级，Voice I/O 基础设施层                                                                                                                                                                                                                                                        |
| v1.1 | 工程审查修订：新增 AudioArbiter、SafetyGuard；EventBus 补背压/优先级/死信/溯源；延迟预算修正（端到端 ≤2.5s、DJ 双路径）；记忆层补 embedding 选型（sqlite-vec + MiniLM）与淘汰策略；音频引擎选型修正；工具命名统一并补错误契约；新增音乐版权分阶段方案、语音数据生命周期、流式 ASR 预分类（8.7） |

### 20.4 参考与致谢

- Conatus 框架文档
- Spinoza《伦理学》中 "conatus" 概念（Agent 设计哲学来源）
- 千帆社区 Prompt 优化实践
- Gym Tracker 本地优先设计参考

**文档结束**

---

**核心总结**：本方案以 Conatus 框架为基础，构建了训练域、音乐域、语音域三个平级的 Agent 集群，通过 EventBus 实现去中心化的跨域协同，通过 Voice I/O 基础设施层统一 ASR/TTS 能力，通过分层记忆实现个性化。核心设计原则是**领域平级、基础设施共享、本地优先、低延迟、隐私可控**。Phase 5 完成时，用户可实现"全程不碰手机完成一次训练"——这是产品的核心差异化时刻。
