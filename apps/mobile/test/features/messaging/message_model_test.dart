import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/messaging/data/models/chat_thread.dart';
import 'package:mobile/features/messaging/data/models/message.dart';

void main() {
  group('Message.fromJson', () {
    test('parses complete message payload correctly', () {
      final json = {
        'id': 123,
        'senderId': 456,
        'messageType': 'Text',
        'content': 'Hello there',
        'latitude': null,
        'longitude': null,
        'sentAt': '2026-09-03T11:47:21.057Z',
        'deliveredAt': null,
        'seenAt': null,
        'threadId': 789,
      };

      final message = Message.fromJson(json);

      expect(message.id, 123);
      expect(message.senderId, 456);
      expect(message.messageType, 'Text');
      expect(message.content, 'Hello there');
      expect(message.threadId, 789);
      expect(message.deliveredAt, isNull);
      expect(message.seenAt, isNull);
    });

    test(
      'handles summary lastMessage payload with missing id and threadId safely',
      () {
        final json = {
          'content': 'Hi!',
          'messageType': 'Text',
          'sentAt': '2026-09-03T11:47:21.057Z',
          'seenAt': null,
          'senderId': 1,
        };

        final message = Message.fromJson(json);

        expect(message.id, 0);
        expect(message.threadId, 0);
        expect(message.senderId, 1);
        expect(message.content, 'Hi!');
        expect(message.messageType, 'Text');
        expect(message.seenAt, isNull);
      },
    );
  });

  group('ChatThread.fromJson', () {
    test('parses thread with summary lastMessage without throwing', () {
      final json = {
        'id': 10,
        'isDirectMessage': true,
        'updatedAt': '2026-09-03T11:47:21.057Z',
        'isSelf': false,
        'otherParticipant': {
          'userId': 2,
          'firstName': 'Adopter',
          'lastName': 'User',
          'avatarUrl': 'http://localhost:9000/happypaws-public/avatars/2.png',
          'email': 'adopter@happypawsnetwork.com',
          'isSelf': false,
        },
        'lastMessage': {
          'id': 55,
          'threadId': 10,
          'content': 'Hi!',
          'messageType': 'Text',
          'sentAt': '2026-09-03T11:47:21.057Z',
          'seenAt': null,
          'senderId': 1,
        },
        'unreadCount': 1,
      };

      final thread = ChatThread.fromJson(json);

      expect(thread.id, 10);
      expect(thread.isDirectMessage, isTrue);
      expect(thread.otherParticipant?.firstName, 'Adopter');
      expect(thread.lastMessage?.content, 'Hi!');
      expect(thread.lastMessage?.id, 55);
      expect(thread.unreadCount, 1);
    });
  });
}
