import 'package:conatus/conatus.dart';

import '../../domain/music_playlist.dart';

/// 歌单输出契约（架构 6.1）。
///
/// 用 [ParamSpec] 声明结构，由框架编译成 JSON Schema，随 validate_playlist
/// 工具作为原生 function calling 参数下发，因此不再写进系统提示词。
List<ParamSpec> playlistOutputParams() => <ParamSpec>[
  ParamSpec.string('name', description: '歌单名', required: true),
  ParamSpec.string('notes', description: '整体策展思路'),
  ParamSpec.array(
    'sections',
    description: '训练阶段，顺序固定 warmup → main → fatigue → stretch',
    required: true,
    items: ParamSpec.object(
      'section',
      properties: <String, ParamSpec>{
        'stage': ParamSpec.enumeration(
          'stage',
          playlistStages,
          description: '阶段标识',
          required: true,
        ),
        'mood': ParamSpec.string('mood', description: '阶段氛围'),
        'tracks': ParamSpec.array(
          'tracks',
          description: '每阶段 2-6 首',
          required: true,
          items: ParamSpec.object(
            'track',
            properties: <String, ParamSpec>{
              'title': ParamSpec.string(
                'title',
                description: '曲名',
                required: true,
              ),
              'artist': ParamSpec.string('artist', description: '艺人'),
              'bpm': ParamSpec.integer(
                'bpm',
                description: '曲目 BPM',
                required: true,
              ),
              'energy': ParamSpec.number(
                'energy',
                description: '能量值 0.0-1.0',
                required: true,
              ),
              'reason': ParamSpec.string('reason', description: '选曲理由'),
            },
          ),
        ),
      },
    ),
  ),
];
