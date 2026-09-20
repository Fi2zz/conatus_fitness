import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:conatus_fitness/features/music/domain/music_playlist_codec.dart';

const valid = '''
{
  "name": "下肢力量 · 推进曲线",
  "notes": "慢起快落",
  "sections": [
    {
      "stage": "warmup",
      "mood": "渐进唤醒",
      "tracks": [
        {"title": "Eye of the Tiger", "artist": "Survivor", "bpm": 109,
         "energy": 0.6, "reason": "经典起步"}
      ]
    },
    {
      "stage": "main",
      "mood": "稳定节奏",
      "tracks": [
        {"title": "Till I Collapse", "artist": "Eminem", "bpm": 148, "energy": 0.9}
      ]
    }
  ]
}
''';

void main() {
  test('解析合法 JSON', () {
    final playlist = MusicPlaylistCodec.tryParse(valid);
    expect(playlist, isNotNull);
    expect(playlist!.name, '下肢力量 · 推进曲线');
    expect(playlist.notes, '慢起快落');
    final warmup = playlist.sections.first;
    expect(warmup.stage, 'warmup');
    expect(warmup.mood, '渐进唤醒');
    final track = warmup.tracks.first;
    expect(track.title, 'Eye of the Tiger');
    expect(track.artist, 'Survivor');
    expect(track.bpm, 109);
    expect(track.energy, 0.6);
    expect(track.reason, '经典起步');
  });

  test('剥离代码块围栏', () {
    final playlist = MusicPlaylistCodec.tryParse('```json\n$valid\n```');
    expect(playlist, isNotNull);
    expect(playlist!.sections.last.stage, 'main');
  });

  test('artist/reason 缺省为 null', () {
    final stripped = valid
        .replaceFirst('"artist": "Survivor", ', '')
        .replaceFirst(', "reason": "经典起步"', '');
    final playlist = MusicPlaylistCodec.tryParse(stripped)!;
    final track = playlist.sections.first.tracks.first;
    expect(track.artist, isNull);
    expect(track.reason, isNull);
  });

  test('缺失 sections 返回 null', () {
    expect(MusicPlaylistCodec.tryParse('{"name": "歌单"}'), isNull);
  });

  test('缺失 name 返回 null', () {
    expect(MusicPlaylistCodec.tryParse('{"sections": []}'), isNull);
  });

  test('空 sections 返回 null', () {
    expect(
      MusicPlaylistCodec.tryParse('{"name": "歌单", "sections": []}'),
      isNull,
    );
  });

  test('非法 stage 返回 null', () {
    final broken = valid.replaceAll('"warmup"', '"party"');
    expect(MusicPlaylistCodec.tryParse(broken), isNull);
  });

  test('空阶段曲目返回 null', () {
    final broken = valid.replaceAll(
      '{"title": "Till I Collapse", "artist": "Eminem", "bpm": 148, "energy": 0.9}',
      '',
    );
    expect(MusicPlaylistCodec.tryParse(broken), isNull);
  });

  test('bpm 越界返回 null', () {
    final broken = valid.replaceAll('"bpm": 109', '"bpm": 195');
    expect(MusicPlaylistCodec.tryParse(broken), isNull);
  });

  test('energy 越界返回 null', () {
    final broken = valid.replaceAll('"energy": 0.9', '"energy": 1.5');
    expect(MusicPlaylistCodec.tryParse(broken), isNull);
  });

  test('非 JSON 文本返回 null', () {
    expect(MusicPlaylistCodec.tryParse('抱歉，我无法生成歌单'), isNull);
  });

  test('toJson 往返一致', () {
    final playlist = MusicPlaylistCodec.tryParse(valid)!;
    final restored = MusicPlaylistCodec.tryParse(jsonEncode(playlist.toJson()));
    expect(restored, isNotNull);
    expect(restored!.name, playlist.name);
    expect(restored.sections.length, playlist.sections.length);
    expect(restored.sections.first.tracks.first.bpm, 109);
  });
}
