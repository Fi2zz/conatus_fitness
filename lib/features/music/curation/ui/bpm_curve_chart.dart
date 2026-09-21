import 'package:flutter/cupertino.dart';

import '../../domain/music_playlist.dart';
import 'bpm_curve_painter.dart';

/// BPM 曲线卡片：四阶段平均 BPM 折线 + 阶段标签（架构 6.1）。
class BpmCurveChart extends StatelessWidget {
  const BpmCurveChart({super.key, required this.sections});

  final List<PlaylistSection> sections;

  @override
  Widget build(BuildContext context) {
    final bpms = <int>[
      for (final section in sections)
        section.tracks.isEmpty
            ? 0
            : section.tracks.fold<int>(0, (sum, track) => sum + track.bpm) ~/
                section.tracks.length,
    ];
    final labels = <String>[
      for (final section in sections)
        stageLabels[section.stage] ?? section.stage,
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: CupertinoColors.tertiarySystemGroupedBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BPM 曲线',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 96,
            width: double.infinity,
            child: CustomPaint(painter: BpmCurvePainter(bpms)),
          ),
          Row(
            children: [
              for (final label in labels)
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
