import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:comm_skills_chatbot_kestrel/constants.dart';
import 'package:comm_skills_chatbot_kestrel/models/local_message.dart';

class TextMessage extends StatelessWidget {
  const TextMessage({
    Key? key,
    this.message,
  }) : super(key: key);

  final LocalMessage? message;

  String capitalizeFirstLetter(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    String text = message!.text ?? '';
    text = text.replaceAll('’', "'");
    text = utf8.decode(text.runes.toList(), allowMalformed: true);

    final RegExp regex = RegExp(r'\[([^\]]+)\]');
    final List<String> nonVerbalInfos = [];

    text = text.replaceAllMapped(regex, (match) {
      nonVerbalInfos.add(capitalizeFirstLetter(match.group(1)!));
      return '';
    });

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding * 0.75,
        vertical: kDefaultPadding / 2,
      ),
      decoration: BoxDecoration(
        color: message!.role == LocalMessageRole.user
            ? kSecondaryColor // Light green for user
            : Colors.white, // White for assistant
        borderRadius: BorderRadius.circular(10),
        /*border: message!.role == LocalMessageRole.ai
            ? Border.all(color: kPrimaryColor.withOpacity(0.1), width: 2) // Thin green border for assistant
            : null,*/
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text.trim(),
            style: TextStyle(
              color: message!.role == LocalMessageRole.user
                  ? Colors.black // Dark text on light-green for user
                  : Colors.black, // Dark text on white for assistant
            ),
          ),
          for (String nonVerbalInfo in nonVerbalInfos)
            Text(
              capitalizeFirstLetter(nonVerbalInfo.trim()),
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: message!.role == LocalMessageRole.user
                    ? Colors.black
                    : Colors.black,
              ),
            ),
        ],
      ),
    );
  }
}
