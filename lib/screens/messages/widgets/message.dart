import 'package:flutter/material.dart';

import '../../../constants.dart';

import 'package:comm_skills_chatbot_kestrel/models/local_message.dart';
//import 'package:just_audio/just_audio.dart'; // Import just_audio

import 'package:comm_skills_chatbot_kestrel/screens/messages/widgets/text_message.dart';
import 'package:comm_skills_chatbot_kestrel/screens/messages/widgets/audio_message.dart';
import 'package:comm_skills_chatbot_kestrel/screens/messages/widgets/video_message.dart';
import 'package:comm_skills_chatbot_kestrel/screens/messages/widgets/loading_message.dart';

class Message extends StatelessWidget {
  const Message({
    super.key,
    required this.message,
    required this.avatar,
    //required this.audioPlayer, // Add the AudioPlayer here
  });

  final LocalMessage message;
  final String avatar;
  //final AudioPlayer audioPlayer; // AudioPlayer instance
  //final FlutterSoundPlayer flutterSoundPlayer;

  @override
  Widget build(BuildContext context) {
    Widget messageContent(LocalMessage message) {
      switch (message.type) {
        case LocalMessageType.text:
          return TextMessage(message: message);
        case LocalMessageType.loading:
          return LoadingMessage(message: message);
        case LocalMessageType.audio:
          return AudioMessage(
              message:
                  message); //, audioPlayer: audioPlayer); // Pass the AudioPlayer instance here
        case LocalMessageType.video:
          //debugPrint(message.filePath.toString());
          return VideoMessage(message: message);
        default:
          return const SizedBox();
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: kDefaultPadding),
      child: Row(
        mainAxisAlignment: message.role == LocalMessageRole.user
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          if (message.role != LocalMessageRole.user) ...[
            CircleAvatar(
              radius: 12,
              backgroundImage: AssetImage(avatar),
            ),
            const SizedBox(width: kDefaultPadding / 2),
          ],
          Flexible(child: messageContent(message)),
        ],
      ),
    );
  }
}
