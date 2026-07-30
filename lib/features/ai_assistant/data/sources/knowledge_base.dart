import '../../domain/entities/assistant_response.dart';
import 'intent_engine.dart';

class KnowledgeBase {
  static final Map<AssistantIntent, AssistantResponse> responses = {
    AssistantIntent.greeting: const AssistantResponse(
      message: "Hello 👋 I'm Nexus Assistant.\nHow can I help you today?",
    ),

    AssistantIntent.meeting: const AssistantResponse(
      message:
          "Your next internship meeting is scheduled for Friday at 6:00 PM.",
      actionLabel: "View Schedule",
      actionRoute: "/schedule",
    ),

    AssistantIntent.deliverables: const AssistantResponse(
      message:
          "You can view your current deliverables from the Deliverables page.",
      actionLabel: "Open Deliverables",
      actionRoute: "/deliverables",
    ),

    AssistantIntent.announcements: const AssistantResponse(
      message:
          "The latest internship announcements are available on your Dashboard.",
      actionLabel: "Open Dashboard",
      actionRoute: "/dashboard",
    ),

    AssistantIntent.programs: const AssistantResponse(
      message:
          "Available internship programs can be found in the Programs section.",
      actionLabel: "Browse Programs",
      actionRoute: "/programs",
    ),

    AssistantIntent.account: const AssistantResponse(
      message:
          "You can manage your account and profile from the Settings page.",
      actionLabel: "Open Settings",
      actionRoute: "/settings",
    ),

    AssistantIntent.faq: const AssistantResponse(
      message:
          "You can ask me about meetings, deliverables, announcements, programs or your account.",
    ),

    AssistantIntent.unknown: const AssistantResponse(
      message:
          "Sorry, I couldn't understand that. Please try asking in a different way.",
    ),
  };
}