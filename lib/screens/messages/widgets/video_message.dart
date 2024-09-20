import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:comm_skills_chatbot_kestrel/constants.dart';
import 'package:comm_skills_chatbot_kestrel/models/local_message.dart';

import 'package:comm_skills_chatbot_kestrel/screens/messages/widgets/video_thumbnail.dart';
import 'package:comm_skills_chatbot_kestrel/screens/messages/widgets/video_dialog.dart';

class VideoMessage extends StatelessWidget {
  final LocalMessage? message;

  const VideoMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: initializeVideoController(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          VideoPlayerController controller =
              snapshot.data as VideoPlayerController;
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
              ),
              child: Column(children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoThumbnail(
                      controller: controller,
                      child: IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) =>
                                VideoDialog(controller: controller),
                          );
                        },
                        icon: Icon(
                          Icons.play_arrow,
                          size: 50,
                          color: Colors.white
                              .withOpacity(0.7), // Adjust opacity as needed
                        ),
                        color: Colors.transparent, // Transparent background
                        splashColor: Colors.transparent, // No splash effect
                        highlightColor:
                            Colors.transparent, // No highlight effect
                      ),
                    ),
                  ],
                ),
                Text(
                  message!.text
                      .toString(), //need to cast to string as .text is Strng? (optional)
                  style: TextStyle(color: Colors.black),
                ),
              ]));
        } else {
          return const CircularProgressIndicator(); // or other loading indicator
        }
      },
    );
  }

  Future<VideoPlayerController> initializeVideoController() async {
    VideoPlayerController controller =
        VideoPlayerController.file(File(message!.filePath.toString()));
    await controller.initialize();
    return controller;
  }
}
