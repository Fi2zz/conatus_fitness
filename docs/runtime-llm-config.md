# 运行时 LLM 配置方案（Model / BaseURL / API Key）

> 状态：**已实施**（2026-09-21）。前置：Conatus 框架 git 依赖 `02bbd0a`。
> 关联：[architecture.md](./architecture.md) 14.2（隐私）、16.2（服务端可选）。

## 1. 背景与目标

原状：`AppConfig` 是编译期常量（`--dart-define` 注入），LLM 在 App 启动期一次性注册进 Conatus Context。产品要求可在设置页修改 **model / baseUrl / apiKey**。

目标：

1. 三个配置项都可在运行中修改并**即时生效**，无需重启；
2. apiKey 只落安全存储，不进日志 / 事件 / SQLite；
3. 修改配置不引入崩溃，不无条件重建 HTTP client，不打断已展示页面。

## 2. 核心结论：三项配置的变更路径不同

| 配置项              | 框架实现                                       | 变更方式                                | 需要重建？         |
| ------------------- | ---------------------------------------------- | --------------------------------------- | ------------------ |
| `apiKey`            | `apiKey` 非 final + `credentials.changes` 订阅 | `Credentials.update()`                  | **否**，就地轮换   |
| `baseUrl` / `model` | `final`                                        | 换 `DoubaoProvider` 实例 → ctx 重新注册 | 是（重建安全兜底） |

`appConfigDefaultsProvider.llmApiKey` 是**编译期回退值**：仅当安全存储里没有该键时兜底，且不落盘。

**ADR 提案**（待并入 architecture.md 20.2）

| 编号   | 决策                                           | 理由                                                         |
| ------ | ---------------------------------------------- | ------------------------------------------------------------ |
| ADR-15 | apiKey 走 `Credentials` 服务，不进持久化配置   | 零重建即可轮换；密钥有独立生命周期（轮换 / 过期 / 来源可换） |
| ADR-16 | baseUrl / model 走 Riverpod → ctx 重新注册     | 框架限制（`final`），且这是重建安全路径的唯一入口            |
| ADR-17 | Conatus Context 是**分发通道**，不是配置事实源 | 事实源唯一化：UI 状态由 Riverpod 持有，避免两处真相          |

## 3. 目标架构（已落地）

```
设置页（我的 → 模型接入）
  ├─ model / baseUrl ──► AppConfigNotifier（shared_preferences）
  │                        └─► llmServiceProvider（select: baseUrl, model）
  │                              └─► provideLlm(ctx) ──► ctx 'llm'
  └─ apiKey ───────────► Credentials.update('ARK_API_KEY', v)
                           └─► credentials.changes ──► DoubaoProvider.apiKey（就地）

AgentRun.open(ctx) ──► provideAgentLoop ──► 每次运行现取 ctx 'llm'
```

要点：

- 改 apiKey：`DoubaoProvider.apiKey` 被订阅更新，**client 不重建**，页面不刷新；
- 改 model / baseUrl：`llmServiceProvider` 重建 → 旧实例 `close()` → 新实例注册；Agent 的 gate 只盯状态枚举，故**不重建 Agent**，下次运行自动用新实例。

## 4. 落地文件

| 文件                                          | 职责                                                                   |
| --------------------------------------------- | ---------------------------------------------------------------------- |
| `core/config/app_config.dart`                 | 编译期默认值 + 回退密钥（`llmConfigured` 已移除，判定归 DI）           |
| `di/app_providers.dart`                       | 编译期默认、`shared_preferences`、框架 Context、事件总线、DB           |
| `di/app_config_notifier.dart`                 | `AppConfigNotifier`（AsyncNotifier）：读盘 / 保存 baseUrl + model      |
| `di/credentials_providers.dart`               | `credentialsProvider`（安全存储）、`apiKeyReadyProvider`、`kArkApiKey` |
| `di/llm_providers.dart`                       | `llmServiceProvider`（注册 'llm'）、`llmStatusProvider`、`LlmStatus`   |
| `data/secure_credentials.dart`                | `SecureStorageCredentials`：可写、可读盘、推变更流                     |
| `features/settings/ui/llm_settings_page.dart` | 设置页（+ `settings_text_field.dart`）                                 |
| `main.dart`                                   | 只注入 `appConfigDefaultsProvider`，运行时值以落盘为准                 |

依赖：`shared_preferences ^2.5`（非密配置）、`flutter_secure_storage ^11.0`（密钥）。**必须 11.x**：9.x 的 Apple 端只有 podspec，`pub get` 会生成 `ios/Podfile` 并改写 `ios/Flutter/*.xcconfig` 的 include，违背「iOS 强制 SPM、禁止 CocoaPods」；11.x 拆出带 `Package.swift` 的 `flutter_secure_storage_darwin` 后不再生成任何 CocoaPods 脚手架。

## 5. 状态机

`LlmStatus`（`di/llm_providers.dart`）是 UI 引导态与 Agent 装配的**唯一判定入口**：

| 状态            | 判定                        | UI                                       |
| --------------- | --------------------------- | ---------------------------------------- |
| `loading`       | 配置或凭据仍在读盘          | 转圈（与内容加载同形，避免启动闪引导态） |
| `ready`         | baseUrl 非空 且 密钥可用    | 正常内容                                 |
| `notConfigured` | 读盘完成但缺 baseUrl 或密钥 | 引导态（指向设置页）                     |

`llmStatusProvider` 经 `llmServiceProvider` 取值，因此它也是「确保服务注册进 Context」的入口 —— 不要在别处直接读 `appConfigProvider` 判定就绪，否则没人触发注册。

## 6. 实现中的三个非显然点

1. **不能用 `provideCredentials`**：它丢弃 `provide` 返回的 `Disposer`，provider 重建时会撞 `StateError`。`credentialsProvider` 改为自己 `provide` + 保留撤销句柄（等价于它的 `provide + onDispose(close)`）。
2. **就绪订阅用 `Notifier` 而非 `StreamProvider`**：`StreamProvider` 在重建时重新订阅，每次重建都退回 `AsyncLoading`，判定方拿不到稳定值（实测表现为永远 loading）。`ApiKeyReadyNotifier` 手动订阅 `credentials.changes` 并在 `onDispose` 取消。
3. **测试必须装插件替身**：`SharedPreferences.setMockInitialValues` + `FlutterSecureStorage.setMockInitialValues`，否则启动期两个读盘调用在测试环境永不返回（`pumpAndSettle` 直接超时）。

## 7. 边界与风险

| 风险                | 表现                                                  | 对策                                                                |
| ------------------- | ----------------------------------------------------- | ------------------------------------------------------------------- |
| 改 model 时正在生成 | 旧 client `close()` → 在飞请求失败为 `RetryableError` | 可接受（换配置即弃旧请求）；要「跑完再换」需把 close 延后到容器销毁 |
| 清空密钥            | 快照无法表达「移除」                                  | 写空值 → 推一条空值记录 → 就绪判定转为 false（已测）                |
| `AppConfig` 无 `==` | 改无关字段也重建 client                               | `llmServiceProvider` 用 `select` 收窄到 (baseUrl, model)            |
| 密钥泄漏            | 明文进日志 / 事件 / DB                                | 只用 `Credential.masked`；`event_log` 不写 key；仅安全存储落盘      |
| 读盘失败            | 启动阻塞                                              | `AppConfigNotifier` 失败退回编译期默认值；密钥缺失按未配置处理      |

## 8. 实施与验证

| 步骤                                    | 状态 | 验证                                                                                                    |
| --------------------------------------- | ---- | ------------------------------------------------------------------------------------------------------- |
| 1. gate 改状态枚举（零行为变化）        | 完成 | analyze + 测试                                                                                          |
| 2. 凭据通道（安全存储 + 回退值）        | 完成 | `llm_config_test.dart`：轮换就地生效、清空回落、重建不抛                                                |
| 3. 配置动态化（AsyncNotifier + 持久化） | 完成 | `app_config_persist_test.dart`：写盘后新容器读回；`llm_config_test.dart`：重建换实例且 ctx 服务同步替换 |
| 4. 设置页 + 入口 + 路由                 | 完成 | 我的页右上齿轮 → `/settings/llm`；保存即写盘 + 更新凭据                                                 |

`flutter analyze` 零问题，`flutter test` 87 项全绿。

## 9. 未决 / 后续

1. **模型分级**（Planner 用强模型、Analysis 用便宜模型）：`provideAgentLoop` 硬编码 `ctx.require<LlmProvider>('llm')`（`conatus_agent/lib/src/agent_provider.dart:33`），要做分级需让 `AgentRun` 支持 llm 覆盖（或注册多键 + 传预构造的 `agent:`），属另一量级改动。
2. 设置页的「测试连接」按钮（需真调一次 LLM，含错误态 UI）尚未做。
3. 首个消费方出现时再补：ASR / TTS 的密钥也走同一凭据服务（`SecureStorageCredentials` 已是通用键值存储）。
