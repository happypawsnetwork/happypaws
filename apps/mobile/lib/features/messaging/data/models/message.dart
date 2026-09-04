class Message {
  final int id;
  final int senderId;
  final String messageType;
  final String content;
  final double? latitude;
  final double? longitude;
  final DateTime sentAt;
  final DateTime? deliveredAt;
  final DateTime? seenAt;
  final int threadId;

  Message({
    required this.id,
    required this.senderId,
    required this.messageType,
    required this.content,
    this.latitude,
    this.longitude,
    required this.sentAt,
    this.deliveredAt,
    this.seenAt,
    required this.threadId,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? 0,
      senderId: json['senderId'] ?? 0,
      messageType: json['messageType']?.toString() ?? 'Text',
      content: json['content'] ?? '',
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      sentAt: json['sentAt'] != null
          ? DateTime.parse(json['sentAt'])
          : DateTime.now(),
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'])
          : null,
      seenAt: json['seenAt'] != null ? DateTime.parse(json['seenAt']) : null,
      threadId: json['threadId'] ?? 0,
    );
  }
}
