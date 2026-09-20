import 'package:sqflite/sqflite.dart';

import '../../../data/schema.dart';

/// 用户画像（users_profile 表，单用户 MVP）。
class UserProfile {
  const UserProfile({
    required this.goal,
    required this.fitnessLevel,
    required this.daysPerWeek,
    required this.equipment,
    required this.injuries,
  });

  final String goal;
  final String fitnessLevel;
  final int daysPerWeek;
  final String equipment;
  final String injuries;
}

/// users_profile 表读写：单用户，save 全量覆盖。
class ProfileDao {
  ProfileDao(this._db);

  final Database _db;

  Future<UserProfile?> load() async {
    final rows = await _db.query(
      Tables.usersProfile,
      orderBy: 'id DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return UserProfile(
      goal: row['goal']?.toString() ?? '',
      fitnessLevel: row['fitness_level']?.toString() ?? '',
      daysPerWeek: (row['days_per_week'] as int?) ?? 3,
      equipment: row['equipment']?.toString() ?? '',
      injuries: row['injuries']?.toString() ?? '',
    );
  }

  Future<void> save(UserProfile profile) async {
    await _db.delete(Tables.usersProfile);
    await _db.insert(Tables.usersProfile, <String, Object?>{
      'goal': profile.goal,
      'fitness_level': profile.fitnessLevel,
      'days_per_week': profile.daysPerWeek,
      'equipment': profile.equipment,
      'injuries': profile.injuries,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
