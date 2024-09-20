import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:provider/provider.dart';

//import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

//import 'home_page.dart';
import 'theme.dart';

import 'package:comm_skills_chatbot_kestrel/screens/chats/chats_screen.dart';
import 'package:comm_skills_chatbot_kestrel/screens/chats/chat_history_screen.dart';
import 'package:comm_skills_chatbot_kestrel/screens/messages/messages_screen.dart';

// Import the generated adapter files
//import 'package:flutter_ai_chat/models/local_message.dart'; // Your LocalMessage class
import 'package:comm_skills_chatbot_kestrel/models/attempt.dart'; // Your Attempt class
import 'package:comm_skills_chatbot_kestrel/models/local_message_adapters.dart'; // Enum adapters

// the main function is made async. This enables us to use await keyword with dotenv inside.
Future<void> main() async {
  await dotenv.load(); // loads all the environment variables

  // Initialize Hive
  await Hive.initFlutter();

  // Register the adapters
  Hive.registerAdapter(LocalMessageTypeAdapter());
  Hive.registerAdapter(LocalMessageRoleAdapter());
  Hive.registerAdapter(LocalMessageAdapter());
  Hive.registerAdapter(AttemptAdapter());

  // Open a box (or whatever your first operation is)
  //var box = await Hive.openBox('myBox');

  // Open a box
  var hiveBox = await Hive.openBox<Attempt>('chatHistory');

  runApp(
    Provider<Box<Attempt>>.value(
      value:
          hiveBox, //to make hiveBox accessible wnyhwere else in the application.
      child: const MyApp(),
    ),
  );

  //runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Comm Skills Chatbot',
      theme: lightThemeData(context),
      darkTheme: darkThemeData(context),
      themeMode: ThemeMode.light,
      initialRoute: ChatsScreen.routeName,
      onGenerateRoute: (settings) {
        if (settings.name == ChatsScreen.routeName) {
          return MaterialPageRoute(builder: (context) => const ChatsScreen());
        } else if (settings.name == ChatHistoryScreen.routeName) {
          final args = settings.arguments as Map<String, dynamic>;
          final updateAttemptsCallback = args['updateAttemptsCallback'];
          final chatData = args['chatData'];
          final chatIndex = args['chatIndex'];

          return MaterialPageRoute(
            builder: (context) => ChatHistoryScreen(),
            settings: RouteSettings(arguments: {
              'chatData': chatData,
              'chatIndex': chatIndex,
            }),
          );
        } else if (settings.name == MessagesScreen.routeName) {
          // Handle MessagesScreen similarly
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => MessagesScreen(),
            settings: RouteSettings(arguments: args),
          );
        }

        // If no route matches, throw an error or return null
        //assert(false, 'Need to implement ${settings.name}');
        return null;
      },
    );
  }
}
