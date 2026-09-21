import '../domain/track_ref.dart';

/// 候选按匹配度降序排列，供播放时依次尝试（首选不可播就换下一个版本）。
///
/// 策展产出只有标题 / 艺人（见 `PlaylistTrack`），且写法常带后缀，如
/// 「晴天 (原唱 周杰伦)」，故先归一化再按「标题精确 > 标题包含 > 艺人吻合」
/// 打分；同分保持服务端原序 —— 检索词本身就是标题 + 艺人，服务端首位即它的
/// 相关性判断。
List<TrackRef> rankCandidates(
  List<TrackRef> candidates, {
  required String title,
  String? artist,
}) {
  final target = _normalize(title);
  final targetArtist = _normalize(artist ?? '');
  final scored = <(int, TrackRef)>[
    for (final candidate in candidates)
      (_score(candidate, target, targetArtist), candidate),
  ];
  // List.sort 不稳定，故用下标兜底保持同分原序。
  final order = List<int>.generate(scored.length, (index) => index)
    ..sort((a, b) {
      final byScore = scored[b].$1.compareTo(scored[a].$1);
      return byScore != 0 ? byScore : a.compareTo(b);
    });
  return [for (final index in order) scored[index].$2];
}

/// 归一化：去括号内容、去标点与空白、转小写。
String _normalize(String text) => text
    .replaceAll(RegExp(r'[（(\[].*?[）)\]]'), '')
    .replaceAll(RegExp(r'[\s\p{P}]', unicode: true), '')
    .toLowerCase();

int _score(TrackRef candidate, String target, String targetArtist) {
  final title = _normalize(candidate.title);
  final artist = _normalize(candidate.artist ?? '');
  var score = 0;
  if (title == target) {
    score += 4;
  } else if (title.contains(target) || target.contains(title)) {
    score += 2;
  }
  if (targetArtist.isNotEmpty &&
      (artist.contains(targetArtist) || targetArtist.contains(artist))) {
    score += 1;
  }
  return score;
}
