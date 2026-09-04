import 'message.dart';

class ChatThreadParticipant {
  final int userId;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final bool isSelf;

  ChatThreadParticipant({
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    this.isSelf = false,
  });

  factory ChatThreadParticipant.fromJson(Map<String, dynamic> json) {
    return ChatThreadParticipant(
      userId: json['userId'] ?? json['id'] ?? 0,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      avatarUrl: json['avatarUrl'],
      isSelf: json['isSelf'] ?? false,
    );
  }
}

class ChatThread {
  final int id;
  final bool isDirectMessage;
  final bool isSelf;
  final DateTime updatedAt;
  final ChatThreadParticipant? otherParticipant;
  final Message? lastMessage;
  final int unreadCount;

  ChatThread({
    required this.id,
    required this.isDirectMessage,
    this.isSelf = false,
    required this.updatedAt,
    this.otherParticipant,
    this.lastMessage,
    required this.unreadCount,
  });

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    return ChatThread(
      id: json['id'],
      isDirectMessage: json['isDirectMessage'] ?? false,
      isSelf: json['isSelf'] ?? (json['otherParticipant']?['isSelf'] ?? false),
      updatedAt: DateTime.parse(json['updatedAt']),
      otherParticipant: json['otherParticipant'] != null
          ? ChatThreadParticipant.fromJson(json['otherParticipant'])
          : null,
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(json['lastMessage'])
          : null,
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}
