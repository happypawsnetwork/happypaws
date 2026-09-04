import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/messaging/data/models/message.dart';

void main() {
  testWidgets('Short message bubble width is much smaller than max width', (
    tester,
  ) async {
    final shortMessage = Message(
      id: 1,
      senderId: 10,
      messageType: 'Text',
      content: 'Hey!',
      sentAt: DateTime.now(),
      threadId: 1,
    );

    final longMessage = Message(
      id: 2,
      senderId: 10,
      messageType: 'Text',
      content: 'Hi, I am a design manager from a tech company, I know you from the work on dribbble. Have you got a job?',
      sentAt: DateTime.now(),
      threadId: 1,
    );

    // Build a widget testing the bubble layout directly
    Widget buildTestBubble(Message msg) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400 * 0.76),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                      bottomLeft: Radius.circular(4),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      Text(
                        msg.content,
                        style: const TextStyle(fontSize: 15, height: 1.4),
                      ),
                      const Text('18:43', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildTestBubble(shortMessage));
    final shortBubbleSize = tester.getSize(find.byType(Container));

    await tester.pumpWidget(buildTestBubble(longMessage));
    final longBubbleSize = tester.getSize(find.byType(Container));

    // Short message bubble must be much smaller than the 304px max width
    expect(shortBubbleSize.width, lessThan(160));
    // Long message bubble should expand to accommodate content
    expect(longBubbleSize.width, greaterThan(shortBubbleSize.width));
  });
}
