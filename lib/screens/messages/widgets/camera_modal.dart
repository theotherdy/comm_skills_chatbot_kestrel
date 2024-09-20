import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraModal extends StatefulWidget {
  final Function(String) onVideoRecorded;

  const CameraModal({Key? key, required this.onVideoRecorded})
      : super(key: key);

  @override
  State<CameraModal> createState() => _CameraModalState();
}

class _CameraModalState extends State<CameraModal> {
  bool _isLoading = true;
  bool _isRecording = false;
  late CameraController _cameraController;
  Timer? _timer;
  int _timerSeconds = 30;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _timer?.cancel(); // Cancel the timer to prevent memory leaks
    super.dispose();
  }

  _recordVideo() async {
    if (_isRecording) {
      final file = await _cameraController.stopVideoRecording();
      setState(() => _isRecording = false);
      widget.onVideoRecorded(file.path);
      Navigator.pop(context);
    } else {
      await _cameraController.prepareForVideoRecording();
      await _cameraController.startVideoRecording();
      setState(() {
        _isRecording = true;
        _startTimer();
      });
    }
  }

  void _startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(oneSec, (Timer timer) {
      if (_timerSeconds == 0) {
        timer.cancel();
        _recordVideo(); // Stop recording when timer reaches 0
      } else {
        setState(() {
          _timerSeconds--;
        });
      }
    });
  }

  void _closeModal() {
    _timer?.cancel(); // Cancel the timer before closing the modal
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.white,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Camera preview and other elements
            Center(
              child: CameraPreview(_cameraController),
            ),
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
            // Record/Stop button
            Positioned(
              bottom: 30.0,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingActionButton(
                  backgroundColor: Colors.red,
                  foregroundColor: _isRecording ? Colors.white : Colors.red,
                  child: Icon(_isRecording ? Icons.stop : Icons.circle),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(width: 3, color: Colors.white),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  onPressed: () => _recordVideo(),
                ),
              ),
            ),
            if (_isRecording)
              Positioned(
                top: 20, // Adjust the position to be closer to the top
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 80, // Adjust the width of the background container
                    padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    decoration: BoxDecoration(
                      color:
                          Colors.black.withOpacity(0.5), // Adjust opacity here
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_timerSeconds',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _timerSeconds <= 5 ? Colors.red : Colors.white,
                        fontSize: 24, // Smaller font size
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }
  }

  _initCamera() async {
    final cameras = await availableCameras();
    final front = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front);
    _cameraController = CameraController(front, ResolutionPreset.low);
    await _cameraController.initialize();
    setState(() => _isLoading = false);
  }
}
