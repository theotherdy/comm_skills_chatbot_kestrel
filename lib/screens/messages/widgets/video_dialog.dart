import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:comm_skills_chatbot_kestrel/screens/messages/utils/video_utils.dart';

class VideoDialog extends StatelessWidget {
  final VideoPlayerController controller;

  const VideoDialog({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    double dialogWidth = screenWidth * 0.9;
    double dialogHeight =
        screenHeight * 0.9; //dialogWidth / (16 / 9); // Aspect ratio 16:9

    return Dialog(
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: _VideoPlayer(
            controller: controller,
            containerWidth: dialogWidth,
            containerHeight: dialogHeight),
      ),
    );
  }
}

class _VideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;
  final double containerWidth;
  final double containerHeight;

  const _VideoPlayer({
    Key? key,
    required this.controller,
    required this.containerWidth,
    required this.containerHeight,
  }) : super(key: key);

  @override
  _VideoPlayerState createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<_VideoPlayer> {
  bool _isPaused = true;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(() {});
    super.dispose();
  }

  // Internal control methods
  void _play() {
    widget.controller.play();
    setState(() {
      _isPaused = false;
    });
  }

  void _pause() {
    widget.controller.pause();
    setState(() {
      _isPaused = true;
    });
  }

  void _replay() {
    widget.controller.seekTo(Duration.zero);
    widget.controller.play();
    setState(() {
      _isPaused = false;
    });
  }

  void _close() {
    widget.controller.pause();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    Size videoDimensions = VideoUtils.calculateVideoDimensions(
      widget.controller,
      widget.containerWidth,
      widget.containerHeight,
    );

    return SizedBox(
      width: videoDimensions.width,
      height: videoDimensions.height,
      child: Stack(
        children: [
          // Video player
          Center(
            child: SizedBox(
              width: videoDimensions.width,
              height: videoDimensions.height,
              child: widget.controller.value.isInitialized
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: VideoPlayer(widget.controller),
                    )
                  : Container(),
            ),
          ),

          // Gradient top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 50.0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(27.0),
                  topRight: Radius.circular(27.0),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              child: Row(
                // Align the close button within the gradient bar
                mainAxisAlignment:
                    MainAxisAlignment.end, // Push close button to the right
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _close,
                  ),
                ],
              ),
            ),
          ),

          // Gradient bottom bar with controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 50.0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(27),
                  bottomRight: Radius.circular(27),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed:
                        (widget.controller.value.position == Duration.zero ||
                                _isPaused)
                            ? _play
                            : _pause,
                    icon: Icon(
                      _isPaused ? Icons.play_arrow : Icons.pause,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  IconButton(
                    onPressed: widget.controller.value.position > Duration.zero
                        ? _replay
                        : null,
                    icon: const Icon(Icons.replay, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
