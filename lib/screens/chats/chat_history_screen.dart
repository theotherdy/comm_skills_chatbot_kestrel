import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';

import 'package:comm_skills_chatbot_kestrel/models/chats_data.dart';

import 'package:comm_skills_chatbot_kestrel/models/attempt.dart';

/*todo:
- show whether you have had the AI's feedback on the conversation?
*/

class ChatHistoryScreen extends StatelessWidget {
  ChatHistoryScreen({super.key});
  static const routeName = '/chat_history';

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final updateAttemptsCallback =
        args['updateAttemptsCallback'] as Function? ?? () {};
    ChatsData chatData = args['chatData'];

    chatData.pastAttempts.sort((a, b) => b.date.compareTo(a.date));

    int chatIndex = args['chatIndex'];

    return Scaffold(
      appBar: AppBar(title: Text('Attempts - ${chatData.title}')),
      body: SafeArea(
        child: Stack(
          children: [
            chatData.pastAttempts.isEmpty
                ? const Center(child: Text('No past attempts found.'))
                : Padding(
                    padding:
                        const EdgeInsets.only(bottom: 80.0), // Space for FAB
                    child: ListView.builder(
                      itemCount: chatData.pastAttempts.length,
                      itemBuilder: (context, index) {
                        final attempt = chatData.pastAttempts[index];
                        final formattedDate =
                            DateFormat('dd/MM/yy HH:mm').format(attempt.date);
                        return ListTile(
                          leading:
                              Icon(Icons.question_answer, color: Colors.green),
                          title: Text('Attempt on $formattedDate'),
                          onTap: () {
                            // Handle loading and displaying messages for this attempt
                            Navigator.pushNamed(
                              context,
                              '/messages',
                              arguments: {
                                'assistantId': chatData.assistantId,
                                'advisorId': chatData.advisorId,
                                'instructions': chatData.instructions,
                                'avatar': chatData.avatar,
                                'voice': chatData.voice,
                                'title': chatData.title,
                                'chatIndex':
                                    chatIndex, // Pass the index as needed when calling back to incrementAttempts
                                'attemptIndex': attempt.index,
                                'attemptMessages': attempt.messages,
                                'systemMessage': chatData.systemMessage,
                              },
                            );
                          },
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () {
                              _deleteAttempt(context, chatData, index);
                              updateAttemptsCallback();
                            },
                          ),
                        );
                      },
                    ),
                  ),
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/messages',
                    arguments: {
                      'assistantId': chatData.assistantId,
                      'advisorId': chatData.advisorId,
                      'instructions': chatData.instructions,
                      'avatar': chatData.avatar,
                      'voice': chatData.voice,
                      'title': chatData.title,
                      'chatIndex':
                          chatIndex, // Pass the index as needed when calling back to incrementAttempts
                      'attemptIndex':
                          null, //ie start a new one with new attempt index
                      'attemptMessages': null,
                      'systemMessage': chatData.systemMessage,
                    },
                  );
                },
                child: Icon(Icons.add),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteAttempt(BuildContext context, ChatsData chatData, int index) {
    // Confirm deletion
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Attempt'),
          content: Text('Are you sure you want to delete this attempt?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Remove the attempt from the list
                final attemptToDelete = chatData.pastAttempts[index];

                // Delete from Hive storage
                final box = Hive.box<Attempt>('chatHistory');
                final attemptKey = box.keys.firstWhere(
                  (key) {
                    final attempt = box.get(key);
                    return attempt?.chatId == attemptToDelete.chatId &&
                        attempt?.index == attemptToDelete.index;
                  },
                  orElse: () => null, // Return null if no matching key is found
                );

                if (attemptKey != null) {
                  await box.delete(attemptKey);
                }

                Navigator.of(context).pop(); // Dismiss the dialog
                (context as Element).markNeedsBuild(); // Refresh the UI
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
