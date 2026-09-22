import 'package:conatus/conatus.dart';

/// 训练计划输出契约（架构 5.1）。
///
/// 用 [ParamSpec] 声明结构，由框架编译成 JSON Schema，随 validate_plan
/// 工具作为原生 function calling 参数下发，因此不再写进系统提示词。
List<ParamSpec> planOutputParams() => <ParamSpec>[
      ParamSpec.array(
        'weeks',
        description: '周次列表，每周一个独立对象',
        required: true,
        items: ParamSpec.object(
          'week',
          properties: <String, ParamSpec>{
            'week_number': ParamSpec.integer(
              'week_number',
              description: '周序号',
              required: true,
            ),
            'sessions': ParamSpec.array(
              'sessions',
              description: '本周训练日',
              required: true,
              items: ParamSpec.object(
                'session',
                properties: <String, ParamSpec>{
                  'day': ParamSpec.string(
                    'day',
                    description: '星期几，如 Monday',
                    required: true,
                  ),
                  'focus': ParamSpec.string('focus', description: '当日训练重点'),
                  'exercises': ParamSpec.array(
                    'exercises',
                    description: '当日动作清单',
                    required: true,
                    items: ParamSpec.object(
                      'exercise',
                      properties: <String, ParamSpec>{
                        'name': ParamSpec.string(
                          'name',
                          description: '动作名',
                          required: true,
                        ),
                        'sets': ParamSpec.integer(
                          'sets',
                          description: '组数',
                          required: true,
                        ),
                        'reps': ParamSpec.string(
                          'reps',
                          description: '次数范围，如 "5" 或 "8-12"',
                          required: true,
                        ),
                        'rest_seconds': ParamSpec.integer(
                          'rest_seconds',
                          description: '组间休息秒数',
                          required: true,
                        ),
                        'target_rpe': ParamSpec.number(
                          'target_rpe',
                          description: '目标 RPE，1-10',
                          required: true,
                        ),
                        'safety_note': ParamSpec.string(
                          'safety_note',
                          description: '与伤病冲突时的替换或保护说明',
                        ),
                      },
                    ),
                  ),
                },
              ),
            ),
          },
        ),
      ),
      ParamSpec.string('safety_notes', description: '整体安全说明'),
    ];