//Adapted from: https://github.com/bettercoding-dev/flutter-video/blob/master/lib/video_page.dart
//but developed with a lot of help from ChatGPT
//import 'dart:io';
//import 'dart:math';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:comm_skills_chatbot_kestrel/constants.dart';

import 'package:comm_skills_chatbot_kestrel/screens/messages/utils/video_utils.dart';
//import 'package:flutter_ai_chat/screens/messages/widgets/video_dialog.dart';

class VideoThumbnail extends StatelessWidget {
  final VideoPlayerController controller;
  final Widget? child;

  const VideoThumbnail({super.key, required this.controller, this.child});

  @override
  Widget build(BuildContext context) {
    double maxWidth = MediaQuery.of(context).size.width * 0.45;
    double aspectRatio =
        16 / 9; // Desired aspect ratio - always a landscape shape

    double rectWidth = maxWidth;
    double rectHeight = rectWidth / aspectRatio;

    double videoWidth =
        VideoUtils.calculateVideoDimensions(controller, rectWidth, rectHeight)
            .width;
    double videoHeight =
        VideoUtils.calculateVideoDimensions(controller, rectWidth, rectHeight)
            .height;

    return Container(
      width: rectWidth,
      height: rectHeight,
      decoration: BoxDecoration(
        color: kSecondaryColor.withOpacity(1),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: videoWidth,
            height: videoHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: VideoPlayer(controller),
            ),
          ),
          if (child != null) Positioned.fill(child: child!),
        ],
      ),
      /*child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: videoWidth,
            height: videoHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: VideoPlayer(controller),
            ),
          ),
        ],
      ),*/
    );
  }
}
