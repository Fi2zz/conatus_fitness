import 'package:flutter_test/flutter_test.dart';

import 'package:conatus_fitness/core/safety/safety_guard.dart';
import 'package:conatus_fitness/features/music/agents/playlist_safety_rules.dart';
import 'package:conatus_fitness/features/music/domain/music_playlist.dart';

MusicPlaylist _fixture() => MusicPlaylist(
  name: '测试歌单',
  notes: '',
  sections: [
    _section('warmup', const [100, 110]),
    _section('main', const [140, 160]),
    _section('fatigue', const [160, 175]),
    _section('stretch', const [80, 90]),
  ],
);

PlaylistSection _section(String stage, List<int> bpms) => PlaylistSection(
  stage: stage,
  mood: '',
  tracks: [
    for (final bpm in bpms)
      PlaylistTrack(title: '曲目 $bpm', bpm: bpm, energy: 0.7),
  ],
);

void main() {
  final rules = playlistSafetyRules();

  SafetyVerdict check(MusicPlaylist playlist) =>
      SafetyGuard<MusicPlaylist>(rules: rules).check(playlist);

  test('合法歌单 → 全部规则通过', () {
    expect(check(_fixture()), isA<SafetyPassed>());
  });

  test('缺失阶段 → 拦截', () {
    final broken = _fixture();
    broken.sections.removeLast();
    final verdict = check(broken);
    expect(verdict, isA<SafetyBlocked>());
    expect((verdict as SafetyBlocked).reason, contains('拉伸'));
  });

  test('阶段顺序颠倒 → 拦截', () {
    final broken = _fixture();
    final stretch = broken.sections.removeLast();
    broken.sections.insert(0, stretch);
    expect(check(broken), isA<SafetyBlocked>());
  });

  test('BPM 超阶段区间 → 拦截', () {
    final broken = _fixture();
    broken.sections[1] = _section('main', const [140, 175]);
    final verdict = check(broken);
    expect(verdict, isA<SafetyBlocked>());
    expect((verdict as SafetyBlocked).reason, contains('主项'));
  });

  test('每阶段曲目数不足 → 拦截', () {
    final broken = _fixture();
    broken.sections[3] = _section('stretch', const [80]);
    final verdict = check(broken);
    expect(verdict, isA<SafetyBlocked>());
    expect((verdict as SafetyBlocked).reason, contains('拉伸'));
  });

  test('每阶段曲目数超限 → 拦截', () {
    final broken = _fixture();
    broken.sections[0] = _section(
      'warmup',
      const [100, 105, 110, 115, 120, 125, 130],
    );
    final verdict = check(broken);
    expect(verdict, isA<SafetyBlocked>());
    expect((verdict as SafetyBlocked).reason, contains('热身'));
  });
}
