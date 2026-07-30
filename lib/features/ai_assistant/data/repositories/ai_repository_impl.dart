import '../../domain/entities/assistant_response.dart';
import '../../domain/repositories/ai_repository.dart';
import '../sources/intent_engine.dart';
import '../sources/knowledge_source.dart';

class AIRepositoryImpl implements AIRepository {
  final IntentEngine _intentEngine;
  final KnowledgeSource _knowledgeSource;

  AIRepositoryImpl({
    required IntentEngine intentEngine,
    required KnowledgeSource knowledgeSource,
  })  : _intentEngine = intentEngine,
        _knowledgeSource = knowledgeSource;

  @override
  Future<AssistantResponse> getResponse(String userMessage) async {
    final intent = _intentEngine.detectIntent(userMessage);

    await Future.delayed(
      const Duration(milliseconds: 700),
    );

    return _knowledgeSource.getResponse(intent);
  }
}