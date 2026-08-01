import '../../domain/entities/assistant_response.dart';
import '../../domain/repositories/ai_repository.dart';
import '../sources/rag_engine.dart';

class AIRepositoryImpl implements AIRepository {
  final NexusRagEngine _ragEngine;

  AIRepositoryImpl({
    NexusRagEngine? ragEngine,
  }) : _ragEngine = ragEngine ?? NexusRagEngine();

  @override
  Future<AssistantResponse> getResponse(String userMessage) async {
    final response = await _ragEngine.query(userMessage);

    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    return response;
  }
}