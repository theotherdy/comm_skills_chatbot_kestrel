import 'dart:math';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoUtils {
  static Size calculateVideoDimensions(
      VideoPlayerController controller, double maxWidth, double maxHeight) {
    double aspectRatio = controller.value.aspectRatio;

    double videoWidth = min(maxWidth, controller.value.size.width);
    double videoHeight = min(maxHeight, videoWidth / aspectRatio);

    debugPrint('Pre-width: $videoWidth');
    debugPrint('Pre-height: $videoHeight');

    bool heightLimiting = false;
    bool widthLimiting = false;

    // If the video is in portrait mode, reduce the width further to ensure the height fits within the rectangle
    if (controller.value.size.aspectRatio < 1.0) {
      videoWidth = min(videoWidth, videoHeight * aspectRatio);
      videoHeight = videoWidth / aspectRatio;
    }

    if (videoWidth > maxWidth) {
      widthLimiting = true;
      debugPrint('Width limiting: $widthLimiting');
    }
    if (videoHeight > maxHeight) {
      heightLimiting = true;
      debugPrint('Height limiting: $heightLimiting');
    }

    if (widthLimiting == true) {
      //portrait
      videoWidth = min(videoWidth, videoHeight * aspectRatio);
      videoHeight = videoWidth / aspectRatio;
    } else if (heightLimiting == true) {
      //landscape
      videoHeight = min(videoHeight, videoWidth / aspectRatio);
      videoWidth = videoHeight * aspectRatio;
    }

    //maybe a check here whether width = height * aspect ratio and, if > reduce it

    debugPrint('Post-width: $videoWidth');
    debugPrint('Post-height: $videoHeight');

    return Size(videoWidth, videoHeight);
  }
}
