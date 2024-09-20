import 'package:hive/hive.dart';

import 'package:comm_skills_chatbot_kestrel/models/local_message.dart'; // Your LocalMessage class

part 'attempt.g.dart'; // The adapter will be generated here by the build_runner using the @HiveType and @HiveField annotations.

//cmd is: flutter pub run build_runner build
@HiveType(typeId: 3)
class Attempt {
  @HiveField(0)
  final int index; // Unique ID for this attempt

  @HiveField(1)
  DateTime date; // Date when the attempt started

  @HiveField(2)
  final List<LocalMessage> messages; // List of messages in this attempt

  @HiveField(3)
  int chatId; // The ID of the chat this attempt belongs to

  Attempt({
    required this.index,
    required this.date,
    required this.messages,
    required this.chatId,
  });
}
