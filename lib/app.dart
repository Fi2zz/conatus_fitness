import 'package:flutter/cupertino.dart';

import 'features/music/ui/music_page.dart';
import 'features/music/ui/playlist_detail_page.dart';
import 'features/music/ui/playlist_setup_page.dart';
import 'features/profile/ui/profile_page.dart';
import 'features/shell/home_shell.dart';
import 'features/training/domain/injury_risk_report.dart';
import 'features/training/domain/training_suggestion.dart';
import 'features/training/ui/analysis_page.dart';
import 'features/training/ui/injury_prevention_page.dart';
import 'features/training/ui/injury_records_page.dart';
import 'features/training/ui/injury_risk_result_page.dart';
import 'features/training/ui/log_workout_page.dart';
import 'features/training/ui/plan_detail_page.dart';
import 'features/training/ui/plan_setup_page.dart';
import 'features/training/ui/suggestion_form_page.dart';
import 'features/training/ui/suggestion_result_page.dart';
import 'features/training/ui/training_page.dart';
import 'features/training/ui/workout_history_page.dart';

/// 路由名。页面推进一律走 GenerateRoute（正规路由体系）。
abstract final class AppRoutes {
  static const home = '/';
  static const training = '/training';
  static const music = '/music';
  static const profile = '/profile';
  static const planSetup = '/training/plan-setup';
  static const planDetail = '/training/plan-detail';
  static const logWorkout = '/training/log';
  static const workoutHistory = '/training/history';
  static const analysis = '/training/analysis';
  static const suggestionForm = '/training/suggestion';
  static const suggestionResult = '/training/suggestion-result';
  static const injuryPrevention = '/training/injury-prevention';
  static const injuryRecords = '/training/injury-records';
  static const injuryPreventionResult = '/training/injury-prevention-result';
  static const playlistSetup = '/music/curate';
  static const playlistDetail = '/music/playlist';
}

class FitnessApp extends StatelessWidget {
  const FitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Conatus Fitness',
      theme: const CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: CupertinoColors.systemBlue,
        scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
      ),
      onGenerateRoute: onGenerateRoute,
      home: const HomeShell(),
    );
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final Widget? page = switch (settings.name) {
      AppRoutes.training => const TrainingPage(),
      AppRoutes.music => const MusicPage(),
      AppRoutes.profile => const ProfilePage(),
      AppRoutes.planSetup => const PlanSetupPage(),
      AppRoutes.logWorkout => const LogWorkoutPage(),
      AppRoutes.workoutHistory => const WorkoutHistoryPage(),
      AppRoutes.planDetail => PlanDetailPage(
        planId: settings.arguments as String,
      ),
      AppRoutes.analysis => const AnalysisPage(),
      AppRoutes.suggestionForm => const SuggestionFormPage(),
      AppRoutes.suggestionResult => SuggestionResultPage(
        suggestion: settings.arguments as TrainingSuggestion,
      ),
      AppRoutes.injuryPrevention => const InjuryPreventionPage(),
      AppRoutes.injuryRecords => const InjuryRecordsPage(),
      AppRoutes.injuryPreventionResult => InjuryRiskResultPage(
        report: settings.arguments as InjuryRiskReport,
      ),
      AppRoutes.playlistSetup => const PlaylistSetupPage(),
      AppRoutes.playlistDetail => PlaylistDetailPage(
        playlistId: settings.arguments as String,
      ),
      _ => null,
    };
    if (page == null) return null;
    return CupertinoPageRoute<void>(settings: settings, builder: (_) => page);
  }
}
