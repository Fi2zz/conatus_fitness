import 'package:conatus/conatus.dart';

import '../domain/training_suggestion.dart';

/// 训练建议输出契约（架构 5.3）。
///
/// 用 [ParamSpec] 声明结构，由框架编译成 JSON Schema，随 validate_suggestion
/// 工具作为原生 function calling 参数下发，因此不再写进系统提示词。
List<ParamSpec> suggestionOutputParams() => <ParamSpec>[
      ParamSpec.enumeration(
        'suggestion_type',
        TrainingSuggestion.types,
        description: '下一次训练方向',
        required: true,
      ),
      ParamSpec.string(
        'reasoning',
        description: '基于数据的推理过程，可追溯',
        required: true,
      ),
      ParamSpec.string('next_session_focus', description: '下次训练重点，如 下肢力量'),
      ParamSpec.string(
        'recommended_music_mood',
        description: '推荐训练音乐氛围',
      ),
      ParamSpec.boolean('safety_flag', description: '是否触发安全提示'),
    ];