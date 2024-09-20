import 'package:flutter/material.dart';

//import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:provider/provider.dart';
import 'package:comm_skills_chatbot_kestrel/models/chats_data.dart';

//import 'package:comm_skills_chatbot_kestrel/screens/messages/messages_screen.dart'; // Import MessagesScreen
import 'package:comm_skills_chatbot_kestrel/screens/chats/widgets/difficulty_indicator.dart';
import 'package:comm_skills_chatbot_kestrel/screens/chats/chat_history_screen.dart'; // Import ChatHistoryScreen

import 'package:comm_skills_chatbot_kestrel/models/attempt.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});
  static const routeName = '/chats';

  @override
  _ChatsScreenState createState() => _ChatsScreenState();
}

enum SortOption {
  titleAscending,
  titleDescending,
  //difficultyAscending,
  //difficultyDescending,
  attemptsAscending,
  attemptsDescending,
}

class _ChatsScreenState extends State<ChatsScreen> {
  List<ChatsData> chats = ChatsData.getChats();
  SortOption sortOption = SortOption.titleAscending;

  //this is for updating UI when values in hive box change
  Box<Attempt>? _attemptBox;

  @override
  void initState() {
    super.initState();
    // Get the Hive box using Provider
    _attemptBox = Provider.of<Box<Attempt>>(context, listen: false);
    _updateAttempts(); // Load attempts for each chat
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Trigger a rebuild whenever the box changes using ValueListenableBuilder
    if (_attemptBox != null) {
      debugPrint('Added listener $_attemptBox');
      _attemptBox!.listenable().addListener(_updateAttempts);
    }
  }

  void _updateAttempts() {
    debugPrint('updating _attemptBox $_attemptBox');
    if (_attemptBox == null) return;

    // Iterate over chats and update their attempt counts
    for (var chat in chats) {
      //debugPrint('Chat id: ${chat.id}');
      final attemptsForChat = _attemptBox!.values
          .where((attempt) => attempt.chatId == chat.id)
          .toList();

      // Sort the attempts by date in reverse order (most recent first)
      //attemptsForChat.sort((a, b) => a.date.compareTo(b.date));

      setState(() {
        chat.attemptCount = attemptsForChat.length; // Update the attempt count
        chat.pastAttempts = attemptsForChat; // Update the list of past attempts
      });
    }
  }

  @override
  void dispose() {
    // Clean up the listener when the widget is disposed
    _attemptBox?.listenable().removeListener(_updateAttempts);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //_loadAttemptsForChats(); // This will call every time build is called
    chats.sort((a, b) {
      switch (sortOption) {
        case SortOption.titleAscending:
          return a.title.compareTo(b.title);
        case SortOption.titleDescending:
          return b.title.compareTo(a.title);
        /*case SortOption.difficultyAscending:
          return a.difficulty.compareTo(b.difficulty);
        case SortOption.difficultyDescending:
          return b.difficulty.compareTo(a.difficulty);*/
        case SortOption.attemptsAscending:
          return a.attemptCount.compareTo(b.attemptCount);
        case SortOption.attemptsDescending:
          return b.attemptCount.compareTo(a.attemptCount);
      }
    });

    /*return PopScope(
      canPop: true, // Allow the route to be popped
      onPopInvokedWithResult: _handlePopAttempt, 
      child:*/
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Chats'),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButton<SortOption>(
                  value: sortOption,
                  items: const [
                    DropdownMenuItem<SortOption>(
                      value: SortOption.titleAscending,
                      child: Text('Sort by Title (Ascending)'),
                    ),
                    DropdownMenuItem<SortOption>(
                      value: SortOption.titleDescending,
                      child: Text('Sort by Title (Descending)'),
                    ),
                    /*DropdownMenuItem<SortOption>(
                        value: SortOption.difficultyAscending,
                        child: Text('Sort by Difficulty (Ascending)'),
                      ),
                      DropdownMenuItem<SortOption>(
                        value: SortOption.difficultyDescending,
                        child: Text('Sort by Difficulty (Descending)'),
                      ),*/
                    DropdownMenuItem<SortOption>(
                      value: SortOption.attemptsAscending,
                      child: Text('Sort by Attempts (Ascending)'),
                    ),
                    DropdownMenuItem<SortOption>(
                      value: SortOption.attemptsDescending,
                      child: Text('Sort by Attempts (Descending)'),
                    )
                  ],
                  onChanged: (SortOption? newValue) {
                    setState(() {
                      sortOption = newValue!;
                    });
                  },
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: AssetImage(chats[index].avatar),
                  ),
                  title: Text(chats[index].title),
                  subtitle:
                      DifficultyIndicator(difficulty: chats[index].difficulty),
                  trailing: () {
                    //todo extract to a widget
                    if (chats[index].attemptCount == 1) {
                      return const Icon(Icons.check, color: Colors.green);
                    } else if (chats[index].attemptCount > 1) {
                      return Badge.count(
                        count: chats[index].attemptCount,
                        backgroundColor: Colors.blue,
                        child: const Icon(Icons.check, color: Colors.green),
                      );
                    } else {
                      // No attempts yet - reserve space with an invisible icon
                      return const SizedBox(
                        width:
                            24, // Set width equal to the icon's width to reserve space
                        child: Icon(Icons.check, color: Colors.transparent),
                      );
                    }
                  }(),
                  onTap: () {
                    if (chats[index].pastAttempts.length > 0) {
                      //navigate intermediate ChatHistoryScreen
                      Navigator.pushNamed(
                        context,
                        ChatHistoryScreen.routeName,
                        arguments: {
                          'chatData': chats[index],
                          'chatIndex': chats[index].id,
                          'updateAttemptsCallback':
                              _updateAttempts, // Pass the callback here
                        },
                      );
                    } else {
                      //navigate straight to MessagesScreen
                      Navigator.pushNamed(
                        context,
                        '/messages',
                        arguments: {
                          'assistantId': chats[index].assistantId,
                          'advisorId': chats[index].advisorId,
                          'instructions': chats[index].instructions,
                          'avatar': chats[index].avatar,
                          'voice': chats[index].voice,
                          'title': chats[index].title,
                          'chatIndex': chats[index]
                              .id, // Pass the index as needed when calling back to incrementAttempts
                          /*'incrementAttempts':
                                incrementAttempts, // Pass the callback function*/
                          'attemptIndex': null, //starting a new attempt
                          'systemMessage': chats[index].systemMessage,
                        },
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
    //);
  }
}
