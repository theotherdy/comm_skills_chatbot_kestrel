import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioRecorderModal extends StatefulWidget {
  final Function(String filePath) onRecordingComplete;

  const AudioRecorderModal({Key? key, required this.onRecordingComplete})
      : super(key: key);

  @override
  _AudioRecorderModalState createState() => _AudioRecorderModalState();
}

class _AudioRecorderModalState extends State<AudioRecorderModal> {
  //final Record _recorder = Record();
  final AudioRecorder _recorder =
      AudioRecorder(); // Use AudioRecorder instead of Record
  String? _audioPath;
  bool _isRecording = false;
  Timer? _timer;
  int _timerSeconds = 30; // 30 seconds countdown

  @override
  void dispose() {
    _recorder.dispose(); // Properly dispose of the recorder
    _timer?.cancel(); // Cancel the timer before disposal
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (await _recorder.hasPermission()) {
      Directory tempDir = await getTemporaryDirectory();
      String fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _audioPath = '${tempDir.path}/$fileName';

      await _recorder.start(const RecordConfig(), path: _audioPath!);

      setState(() {
        _isRecording = true;
        _startTimer(); // Start the countdown timer
      });
    }
  }

  Future<void> _stopRecording() async {
    final path =
        await _recorder.stop(); // Adjust this to the new method signature
    _timer?.cancel(); // Stop the timer

    if (path != null) {
      widget.onRecordingComplete(path);
    }
    Navigator.pop(context); // Close the modal after recording
  }

  /*Future<void> _startRecording() async {
    PermissionStatus status = await Permission.microphone.request();
    if (status.isGranted) {
      Directory tempDir = await getTemporaryDirectory();
      String fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _audioPath = '${tempDir.path}/$fileName';

      await _recorder.start(
        path: _audioPath,
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        samplingRate: 44100,
      );

      setState(() {
        _isRecording = true;
        _startTimer(); // Start the countdown timer
      });
    }
  }

  Future<void> _stopRecording() async {
    await _recorder.stop();
    _timer?.cancel(); // Stop the timer

    if (_audioPath != null) {
      widget.onRecordingComplete(_audioPath!);
    }
    Navigator.pop(context); // Close the modal after recording
  }*/

  void _startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(oneSec, (Timer timer) {
      if (_timerSeconds == 0) {
        timer.cancel();
        _stopRecording(); // Stop recording when timer reaches 0
      } else {
        setState(() {
          _timerSeconds--;
        });
      }
    });
  }

  void _closeModal() {
    _timer?.cancel(); // Cancel the timer when closing
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5),
      body: Stack(
        children: [
          // Close button
          Positioned(
            top: 16.0,
            right: 16.0,
            child: IconButton(
              icon: Icon(Icons.close),
              color: Colors.white,
              onPressed: _closeModal,
            ),
          ),
          // Recording UI
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    size: 80.0, // Bigger icon for better usability
                    color: Colors.redAccent,
                  ),
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                ),
                Text(
                  _isRecording ? 'Recording...' : 'Tap to record',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                if (_isRecording)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      '$_timerSeconds',
                      style: TextStyle(
                        fontSize: 24,
                        color: _timerSeconds <= 5 ? Colors.red : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
