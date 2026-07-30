import '../entities/assistant_response.dart';

abstract class AIRepository {
  Future<AssistantResponse> getResponse(
    String userMessage,
  );
}