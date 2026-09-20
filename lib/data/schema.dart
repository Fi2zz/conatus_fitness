/// 表名常量（架构 10.1）。资源 Key 统一 snake_case。
abstract final class Tables {
  static const usersProfile = 'users_profile';
  static const workoutLogs = 'workout_logs';
  static const trainingPlans = 'training_plans';
  static const agentMemory = 'agent_memory';
  static const musicPreferences = 'music_preferences';
  static const voiceHistory = 'voice_history';
  static const playlists = 'playlists';
  static const hostPersona = 'host_persona';
  static const eventLog = 'event_log';
  static const eventDeadLetter = 'event_dead_letter';
}

/// v1 全量建表（架构 10.1）。列结构随各 Phase 落地按需扩展（走迁移）。
abstract final class SchemaV1 {
  static const int version = 1;

  static const List<String> statements = [
    '''
    CREATE TABLE users_profile (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      goal TEXT,
      fitness_level TEXT,
      days_per_week INTEGER,
      equipment TEXT,
      injuries TEXT,
      updated_at TEXT NOT NULL
    )
    ''',
    '''
    CREATE TABLE workout_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      exercise TEXT NOT NULL,
      set_number INTEGER NOT NULL,
      weight REAL NOT NULL,
      reps INTEGER NOT NULL,
      rpe REAL,
      session_id TEXT NOT NULL,
      performed_at TEXT NOT NULL
    )
    ''',
    '''
    CREATE TABLE training_plans (
      id TEXT PRIMARY KEY,
      payload TEXT NOT NULL,
      source TEXT NOT NULL,
      safety_status TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
    ''',
    '''
    CREATE TABLE agent_memory (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      domain TEXT NOT NULL,
      kind TEXT NOT NULL,
      content TEXT NOT NULL,
      embedding BLOB,
      created_at TEXT NOT NULL
    )
    ''',
    '''
    CREATE TABLE music_preferences (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      track_id TEXT,
      signal TEXT NOT NULL,
      weight REAL NOT NULL,
      context TEXT,
      recorded_at TEXT NOT NULL
    )
    ''',
    '''
    CREATE TABLE voice_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      transcript TEXT NOT NULL,
      intent TEXT,
      created_at TEXT NOT NULL
    )
    ''',
    '''
    CREATE TABLE playlists (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      payload TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
    ''',
    '''
    CREATE TABLE host_persona (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      topic TEXT NOT NULL,
      reaction TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
    ''',
    '''
    CREATE TABLE event_log (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      event_id TEXT NOT NULL,
      trace_id TEXT NOT NULL,
      source_agent TEXT NOT NULL,
      payload TEXT NOT NULL,
      occurred_at TEXT NOT NULL
    )
    ''',
    '''
    CREATE TABLE event_dead_letter (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      event_id TEXT NOT NULL,
      payload TEXT NOT NULL,
      error TEXT NOT NULL,
      recorded_at TEXT NOT NULL
    )
    ''',
    'CREATE INDEX idx_workout_logs_session ON workout_logs(session_id)',
    'CREATE INDEX idx_workout_logs_exercise ON workout_logs(exercise)',
    'CREATE INDEX idx_event_log_trace ON event_log(trace_id)',
    'CREATE INDEX idx_agent_memory_domain ON agent_memory(domain, kind)',
  ];
}
