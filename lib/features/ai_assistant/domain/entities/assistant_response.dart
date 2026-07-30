class AssistantResponse {
  final String message;

  final String? actionLabel;

  final String? actionRoute;

  const AssistantResponse({
    required this.message,
    this.actionLabel,
    this.actionRoute,
  });
}