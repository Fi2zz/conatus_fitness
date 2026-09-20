/// Planner Agent 输入（架构 5.1）：用户画像 + 计划跨度。
class PlannerInput {
  const PlannerInput({
    required this.goal,
    required this.fitnessLevel,
    required this.daysPerWeek,
    required this.equipment,
    required this.injuries,
    required this.weeks,
  });

  final String goal;
  final String fitnessLevel;
  final int daysPerWeek;
  final String equipment;
  final String injuries;
  final int weeks;
}
