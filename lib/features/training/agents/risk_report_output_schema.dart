import 'package:conatus/conatus.dart';

import '../domain/injury_risk_report.dart';

/// 伤病风险报告输出契约（架构 13.x）。
///
/// 用 [ParamSpec] 声明结构，由框架编译成 JSON Schema，随 validate_risk_report
/// 工具作为原生 function calling 参数下发，因此不再写进系统提示词。
List<ParamSpec> riskReportOutputParams() => <ParamSpec>[
  ParamSpec.array(
    'risk_areas',
    description: '存在风险的部位；无风险时为合法空数组',
    required: true,
    items: ParamSpec.string('area', description: '部位，如 膝'),
  ),
  ParamSpec.enumeration(
    'risk_level',
    InjuryRiskReport.levels,
    description: '整体风险等级',
    required: true,
  ),
  ParamSpec.string(
    'load_analysis',
    description: '伤病部位近期负荷与刺激分析',
    required: true,
  ),
  ParamSpec.array(
    'preventive_actions',
    description: '具体预防动作，不能为空',
    required: true,
    items: ParamSpec.string('action', description: '预防动作'),
  ),
  ParamSpec.array(
    'conflicting_exercises',
    description: '与伤病冲突且出现在近期日志中的动作',
    items: ParamSpec.string('exercise', description: '冲突动作'),
  ),
  ParamSpec.array(
    'safe_alternatives',
    description: '安全替代动作',
    items: ParamSpec.string('alternative', description: '替代动作'),
  ),
];
