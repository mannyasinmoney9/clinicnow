enum MessageRole { user, ada }

enum TriageLevel { red, yellow, green, none }

class ChatMessage {
  ChatMessage({
    required this.role,
    required this.text,
    this.offline = false,
    this.isLoading = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final MessageRole role;
  final String text;
  final bool offline;
  final bool isLoading;
  final DateTime createdAt;

  bool get isUser => role == MessageRole.user;

  TriageLevel get triageLevel {
    if (text.contains('🔴')) return TriageLevel.red;
    if (text.contains('🟡')) return TriageLevel.yellow;
    if (text.contains('🟢')) return TriageLevel.green;
    return TriageLevel.none;
  }

  ChatMessage copyWith({String? text, bool? offline, bool? isLoading}) =>
      ChatMessage(
        role: role,
        text: text ?? this.text,
        offline: offline ?? this.offline,
        isLoading: isLoading ?? this.isLoading,
        createdAt: createdAt,
      );
}