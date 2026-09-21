/// LLM 端点与凭据键的对应关系。
///
/// 火山方舟的 Plan 端点只认**订阅后生成的专属 Key**（与普通方舟 Key 不同值，
/// 见 `conatus_providers` 的 `provider_defaults`），故凭据键按端点选：
/// 拿普通 Key 打 Plan 端点就是 `AuthenticationError`。
library;

/// 普通方舟端点与 Key。
const plainArkEndpoint = 'https://ark.cn-beijing.volces.com/api/v3';
const arkApiKeyName = 'ARK_API_KEY';

/// Agent Plan（豆包 Agent 套餐）端点与专属 Key。
const agentPlanEndpoint = 'https://ark.cn-beijing.volces.com/api/plan/v3';
const agentPlanApiKeyName = 'ARK_AGENT_PLAN_API_KEY';

/// Coding Plan（代码套餐）端点与专属 Key。
const codingPlanEndpoint = 'https://ark.cn-beijing.volces.com/api/coding/v3';
const codingPlanApiKeyName = 'ARK_CODING_PLAN_API_KEY';

/// 端点 → 凭据键；非方舟端点（DeepSeek 等）按普通 Key 处理。
String llmCredentialKey(String baseUrl) {
  if (baseUrl.contains('/api/plan/')) return agentPlanApiKeyName;
  if (baseUrl.contains('/api/coding/')) return codingPlanApiKeyName;
  return arkApiKeyName;
}
