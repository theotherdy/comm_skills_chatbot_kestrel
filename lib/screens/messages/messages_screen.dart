import 'package:flutter/material.dart';
import 'package:comm_skills_chatbot_kestrel/constants.dart';
import 'package:comm_skills_chatbot_kestrel/screens/messages/widgets/messages_body.dart';
import 'package:comm_skills_chatbot_kestrel/screens/messages/widgets/information_modal.dart';
import 'package:comm_skills_chatbot_kestrel/models/local_message.dart'; // Your LocalMessage class

class MessagesScreen extends StatelessWidget {
  MessagesScreen({super.key});
  static const routeName = '/messages';
  bool _isFirstLoad = true; // Introduce the variable
  //bool _attemptsIncremented = false;

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    String assistantId = args['assistantId'];
    String advisorId = args['advisorId'];
    String instructions = args['instructions'];
    String avatar = args['avatar'];
    String voice = args['voice'];
    String title = args['title'];
    int chatIndex = args['chatIndex'];
    //Function(int) incrementAttempts = args['incrementAttempts'];
    int? attemptIndex = args['attemptIndex'];
    List<LocalMessage>? attemptMessages = args['attemptMessages'];
    String systemMessage = args['systemMessage'];
    //String title = args['title'];

    // Show the dialog on initial load
    if (_isFirstLoad && attemptMessages == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isFirstLoad = false; // Make sure it only shows once
        _showInstructionsDialog(context, instructions);
      });
    }

    debugPrint('Coming in to MessagesScreen attemptIndex = $attemptIndex');

    return Scaffold(
        appBar: buildAppBar(title, avatar, context, instructions),
        backgroundColor: Colors.grey[100],
        body: MessagesBody(
          assistantId: assistantId,
          advisorId: advisorId,
          avatar: avatar,
          voice: voice,
          chatIndex: chatIndex, // Pass the index
          //incrementAttempts: incrementAttempts, // Pass the callback function),
          attemptIndex: attemptIndex,
          attemptMessages: attemptMessages,
          systemMessage: systemMessage,
        ));
  }

  AppBar buildAppBar(
      String title, String avatar, BuildContext context, String instructions) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(children: [
        const BackButton(),
        CircleAvatar(backgroundImage: AssetImage(avatar)),
        const SizedBox(width: kDefaultPadding * 0.75),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 16)),
          ]),
        ),
      ]),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => _showInstructionsDialog(context, instructions),
        ),
      ],
    );
  }

  void _showInstructionsDialog(BuildContext context, String instructions) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return InformationModal(
            information: instructions, title: 'Instructions');
      },
      barrierDismissible: true,
    );
  }
}
