import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'package:comm_skills_chatbot_kestrel/constants.dart';
import 'package:comm_skills_chatbot_kestrel/models/local_message.dart';
import 'dart:async';

class AudioMessage extends StatefulWidget {
  final LocalMessage message;

  const AudioMessage({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  _AudioMessageState createState() => _AudioMessageState();
}

class _AudioMessageState extends State<AudioMessage> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _audioDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;

  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;

  @override
  void initState() {
    super.initState();

    _audioPlayer = AudioPlayer();

    // Subscribing to player state stream
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return; // Check if the widget is still in the tree
      setState(() {
        _isPlaying = state.playing;
      });
    });

    // Subscribing to duration stream
    _durationSubscription = _audioPlayer.durationStream.listen((duration) {
      if (!mounted) return; // Check if the widget is still in the tree
      setState(() {
        _audioDuration = duration ?? Duration.zero;
      });
    });

    // Subscribing to position stream
    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      if (!mounted) return; // Check if the widget is still in the tree
      setState(() {
        _currentPosition = position;
      });
    });

    // Listen for when the audio is completed
    _audioPlayer.processingStateStream.listen((state) async {
      if (state == ProcessingState.completed) {
        await _audioPlayer.pause();
        await _audioPlayer.seek(Duration.zero);
        if (!mounted) return; // Check before calling setState
        setState(() {
          _currentPosition = Duration.zero;
          _isPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    // Cancel the stream subscriptions to avoid memory leaks
    _playerStateSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();

    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (_audioPlayer.processingState != ProcessingState.ready) {
        await _audioPlayer.setFilePath(widget.message.filePath!);
      }
      await _audioPlayer.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding * 0.75,
        vertical: kDefaultPadding / 2,
      ),
      decoration: BoxDecoration(
        color: widget.message!.role == LocalMessageRole.user
            ? kSecondaryColor
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: kPrimaryColor,
                ),
                onPressed: _togglePlayPause,
              ),
              Expanded(
                child: Slider(
                  value: _currentPosition.inSeconds.toDouble(),
                  max: _audioDuration.inSeconds.toDouble(),
                  activeColor: Colors.white,
                  thumbColor: kPrimaryColor,
                  inactiveColor: Colors.white54,
                  onChanged: (value) async {
                    final position = Duration(seconds: value.toInt());
                    await _audioPlayer.seek(position);
                  },
                ),
              ),
              Text(
                '${_currentPosition.inMinutes}:${(_currentPosition.inSeconds % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.black),
              ),
            ],
          ),
          Text(
            widget.message.text ?? '',
            style: const TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }
}
