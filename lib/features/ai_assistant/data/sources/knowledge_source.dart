import '../../domain/entities/assistant_response.dart';
import 'intent_engine.dart';
import 'knowledge_base.dart';

class KnowledgeSource {
  AssistantResponse getResponse(AssistantIntent intent) {
    return KnowledgeBase.responses[intent] ??
        KnowledgeBase.responses[AssistantIntent.unknown]!;
  }
}