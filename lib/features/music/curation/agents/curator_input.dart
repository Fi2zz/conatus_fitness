/// MusicCurator Agent 输入（架构 6.1）：训练情境 + 氛围诉求。
class CuratorInput {
  const CuratorInput({
    required this.focus,
    required this.minutes,
    required this.vibe,
  });

  final String focus;
  final int minutes;
  final String vibe;
}
