class AlertRecommendation {
  final String attackType;
  final String summary;
  final List<String> actions;

  const AlertRecommendation({
    required this.attackType,
    required this.summary,
    required this.actions,
  });
}
