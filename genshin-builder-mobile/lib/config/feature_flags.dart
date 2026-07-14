/// Remote Config 相当の機能フラグ（ローカル設定で無効化可能）
class FeatureFlags {
  FeatureFlags({
    required this.hoyolabLinkEnabled,
    this.enableGrowthGoals = true,
    this.enableMaterialInventory = true,
    this.enableSavedTeams = true,
    this.enableDailyPlan = true,
    this.enableInvestmentDiagnosis = true,
    this.enableGrowthTimeline = true,
    this.enableAccountHealth = true,
  });

  /// HoYoLAB 連携全体の ON/OFF（`app_settings.hoyolab_link_enabled`）
  final bool hoyolabLinkEnabled;

  // ─── Phase 1 flags ──────────────────────────────────────────────

  final bool enableGrowthGoals;
  final bool enableMaterialInventory;
  final bool enableSavedTeams;

  // ─── Phase 2 flags ──────────────────────────────────────────────

  /// Daily plan generation (today's tasks)
  final bool enableDailyPlan;

  /// Investment diagnosis per character
  final bool enableInvestmentDiagnosis;

  /// Growth event timeline
  final bool enableGrowthTimeline;

  /// Account health report
  final bool enableAccountHealth;

  // ─── Defaults ───────────────────────────────────────────────────

  static const defaultHoyolabLinkEnabled = true;
  static const defaultGrowthGoalsEnabled = true;
  static const defaultMaterialInventoryEnabled = true;
  static const defaultSavedTeamsEnabled = true;
  static const defaultDailyPlanEnabled = true;
  static const defaultInvestmentDiagnosisEnabled = true;
  static const defaultGrowthTimelineEnabled = true;
  static const defaultAccountHealthEnabled = true;

  // ─── AppSettings keys ───────────────────────────────────────────

  static const hoyolabLinkEnabledKey = 'hoyolab_link_enabled';
  static const growthGoalsEnabledKey = 'growth_goals_enabled';
  static const materialInventoryEnabledKey = 'material_inventory_enabled';
  static const savedTeamsEnabledKey = 'saved_teams_enabled';
  static const dailyPlanEnabledKey = 'daily_plan_enabled';
  static const investmentDiagnosisEnabledKey = 'investment_diagnosis_enabled';
  static const growthTimelineEnabledKey = 'growth_timeline_enabled';
  static const accountHealthEnabledKey = 'account_health_enabled';
}
