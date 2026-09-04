import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/messaging/data/models/chat_thread.dart';
import 'package:mobile/features/messaging/presentation/controllers/chat_controller.dart';

class TestableChatController extends ChatController {
  void setTestThreads(List<ChatThread> testThreads) {
    threads.clear();
    threads.addAll(testThreads);
    notifyListeners();
  }
}

void main() {
  group('ChatController.totalUnreadCount', () {
    test('returns 0 when threads list is empty', () {
      final controller = TestableChatController();
      expect(controller.totalUnreadCount, 0);
    });

    test('correctly calculates total unread count across non-self threads', () {
      final controller = TestableChatController();

      final thread1 = ChatThread(
        id: 1,
        isDirectMessage: true,
        isSelf: false,
        updatedAt: DateTime.now(),
        unreadCount: 3,
      );

      final thread2 = ChatThread(
        id: 2,
        isDirectMessage: true,
        isSelf: false,
        updatedAt: DateTime.now(),
        unreadCount: 5,
      );

      // Self thread with unreadCount should be ignored
      final selfThread = ChatThread(
        id: 3,
        isDirectMessage: true,
        isSelf: true,
        updatedAt: DateTime.now(),
        unreadCount: 2,
      );

      controller.setTestThreads([thread1, thread2, selfThread]);

      expect(controller.totalUnreadCount, 8);
    });

    test('returns 0 when all threads have 0 unread messages', () {
      final controller = TestableChatController();

      final thread1 = ChatThread(
        id: 1,
        isDirectMessage: true,
        isSelf: false,
        updatedAt: DateTime.now(),
        unreadCount: 0,
      );

      final thread2 = ChatThread(
        id: 2,
        isDirectMessage: true,
        isSelf: false,
        updatedAt: DateTime.now(),
        unreadCount: 0,
      );

      controller.setTestThreads([thread1, thread2]);

      expect(controller.totalUnreadCount, 0);
    });
  });
}
