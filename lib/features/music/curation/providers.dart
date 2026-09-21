import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/event_log_dao.dart';
import '../../../di/app_providers.dart';
import '../../../di/llm_providers.dart';
import 'agents/curator_agent.dart';
import 'data/music_prefs_dao.dart';
import 'data/playlists_dao.dart';

/// Curator Agent 装配（架构 6.1）；LLM 未配置时为 null。
final curatorAgentProvider = FutureProvider<CuratorAgent?>((ref) async {
  if (ref.watch(llmStatusProvider) != LlmStatus.ready) return null;
  final ctx = ref.watch(agentContextProvider);
  final db = (await ref.watch(appDatabaseProvider.future)).db;
  return CuratorAgent(
    ctx: ctx,
    playlistsDao: PlaylistsDao(db),
    prefsDao: MusicPrefsDao(db),
    eventLog: EventLogDao(db),
  );
});

/// 歌单列表（最新在前）。
final playlistsProvider = FutureProvider<List<StoredPlaylist>>((ref) async {
  final db = (await ref.watch(appDatabaseProvider.future)).db;
  return PlaylistsDao(db).listLatest();
});

/// 歌单详情。
final playlistDetailProvider = FutureProvider.family<StoredPlaylist?, String>((
  ref,
  id,
) async {
  final db = (await ref.watch(appDatabaseProvider.future)).db;
  return PlaylistsDao(db).findById(id);
});
