import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data'; //Uint8List
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'package:just_audio/just_audio.dart';
//import 'package:flutter_sound/flutter_sound.dart';

import 'package:jumping_dot/jumping_dot.dart';

import 'package:ffmpeg_kit_flutter_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full/return_code.dart';

import 'package:comm_skills_chatbot_kestrel/constants.dart';

import 'package:comm_skills_chatbot_kestrel/services/open_ai_service.dart';
import 'package:comm_skills_chatbot_kestrel/services/whisper_transcription_service.dart';

import 'package:comm_skills_chatbot_kestrel/models/local_message.dart';

import 'package:comm_skills_chatbot_kestrel/screens/messages/widgets/message.dart';
import 'package:comm_skills_chatbot_kestrel/screens/messages/widgets/camera_modal.dart';
import 'package:comm_skills_chatbot_kestrel/screens/messages/widgets/audio_recorder.dart';
import 'package:comm_skills_chatbot_kestrel/screens/messages/widgets/information_modal.dart';
import 'package:comm_skills_chatbot_kestrel/screens/messages/widgets/input_bar.dart';

class MessagesBody extends StatefulWidget {
  final String assistantId;
  final String advisorId;
  final String avatar;
  final String voice;
  final int chatIndex; // Receive the index
  final int? attemptIndex;
  final List<LocalMessage>? attemptMessages;
  final String systemMessage;

  MessagesBody({
    super.key,
    required this.assistantId,
    required this.advisorId,
    required this.avatar,
    required this.voice,
    required this.chatIndex, // Receive the index
    required this.attemptIndex,
    required this.attemptMessages,
    required this.systemMessage,
  });

  @override
  State<MessagesBody> createState() => _MessagesBodyState();
}

class _MessagesBodyState extends State<MessagesBody> {
  final ScrollController _scrollController = ScrollController();
  final OpenAiService openAiService =
      OpenAiService(); //todo NEW INSTANCE of service (ie new thread) every time we come to this page - may want to do this explictly to allow people to continue a conversation?
  final WhisperTranscriptionService whisperTranscriptionService =
      WhisperTranscriptionService();

  String tempChatHistoryContent = '';
  final List<LocalMessage> _chatHistory = [];
  String _lastAdvisorResponse = ''; //to hold last respnse from advisor

  late AudioPlayer _audioPlayer;
  //late FlutterSoundPlayer _flutterSoundPlayer;
  // Define a state variable to hold the attempt index
  int? _currentAttemptIndex;

  @override
  void initState() {
    super.initState();
    debugPrint(
        'Coming in to MessagesBody attemptIndex = ${widget.attemptIndex}');
    _audioPlayer = AudioPlayer();
    //_flutterSoundPlayer = FlutterSoundPlayer(); // Initialize FlutterSoundPlayer
    /*_flutterSoundPlayer.openPlayer().then((value) {
      debugPrint('FlutterSoundPlayer initialized');
    }).catchError((e) {
      debugPrint('Error initializing player: $e');
    });*/
    // Initialize _currentAttemptIndex with the initial value passed from the widget
    _currentAttemptIndex = widget.attemptIndex;
    debugPrint('Init _currentAttemptIndex $_currentAttemptIndex');
    // Load attemptMessages into _chatHistory if they exist
    if (widget.attemptMessages != null && widget.attemptMessages!.isNotEmpty) {
      debugPrint('I have some messages');
      setState(() {
        _chatHistory.addAll(widget.attemptMessages!);
      });
      _scrollToBottom(); // Scroll to bottom after loading messages
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    //_flutterSoundPlayer.closePlayer(); // Close the player when done
    super.dispose();
  }

  //Scrolls to bottom of page
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  /// Shows a loading message of [role] by adding to end of [_chatHistory] and scrolling down.
  ///
  ///
  void _showLoadingMessage(LocalMessageRole role) {
    setState(() {
      _chatHistory.add(LocalMessage(
          time: DateTime.now(),
          type: LocalMessageType.loading,
          role: role,
          text: "..."));
    });
    _scrollToBottom();
  }

  /// Shows a text message of [role] by adding to end of [_chatHistory] and scrolling down.
  ///
  ///
  void _showTextMessage(LocalMessageRole role, String text) {
    _lastAdvisorResponse = ''; //new message so can't reuse
    setState(() {
      _chatHistory.add(LocalMessage(
          time: DateTime.now(),
          type: LocalMessageType.text,
          role: role,
          text: text));
    });
    _scrollToBottom();
  }

  void _showCameraModal(BuildContext context) async {
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true, // Set to true for full-screen modal
      builder: (BuildContext context) {
        return Container(
            height: MediaQuery.of(context).size.height, // Full height
            padding: const EdgeInsets.all(0),
            child: CameraModal(onVideoRecorded: (filePath) async {
              // Callback function when file is selected in CameraModal
              _lastAdvisorResponse = ''; //new message so can't reuse
              // Audio Extraction with ffmpeg_kit_flutter and path_provider
              final tempDirectory =
                  await getTemporaryDirectory(); // Get temporary directory
              final audioOutputPath =
                  '${tempDirectory.path}/extracted_audio.mp3'; // Use a suitable extension
              await _extractAudio(filePath, audioOutputPath);

              final transcription = await whisperTranscriptionService
                  .transcribeVideo(audioOutputPath);

              String transcribedText = '';

              if (transcription != null &&
                  transcription.text != '' &&
                  transcription.text.toLowerCase() != 'you') {
                //for some reason, it seems to hallucinate 'you' if no sound!
                transcribedText = transcription.text;
                setState(() {
                  //add video message to list of messages
                  _chatHistory.add(LocalMessage(
                      time: DateTime.now(),
                      type: LocalMessageType.video,
                      role: LocalMessageRole.user,
                      text: transcribedText,
                      filePath: filePath));
                });
                _scrollToBottom();
                _sendTextMessageAndShowTextResponse(
                    transcription.text); //send off to chat api to respond to
              } else {
                //show an eror dialogue
                _showWhisperErrorDialog();
              }
            }));
      },
    );
  }

  void _showWhisperErrorDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext newContext) {
        // Capture a new BuildContext
        return AlertDialog(
          title: Text("Sorry"),
          content: Text(
              "I'm afraid couldn't find any speech in that video, or something went wrong - please try again, or type your message instead"),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(newContext).pop(); // Use the new BuildContext
              },
            ),
          ],
        );
      },
    );
  }

  // Helper function for audio extraction using FFmpegKit
  Future<void> _extractAudio(String inputPath, String outputPath) async {
    String command =
        '-y -i $inputPath -vn -acodec libmp3lame $outputPath'; //-y tells it to autooverwrite
    await FFmpegKit.execute(command).then((session) async {
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        // SUCCESS, audio extracted
        debugPrint('Audio extraction success');
      } else if (ReturnCode.isCancel(returnCode)) {
        // Operation was canceled
        debugPrint('Audio extraction canceled');
      } else {
        // ERROR
        debugPrint('Error extracting audio. Error Code: $returnCode');
      }

      // Access logs
      await session.getLogs().then((logs) {
        logs.forEach((log) => debugPrint(log.getMessage()));
      });
    });
  }

  void _showAudioModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return AudioRecorderModal(
          onRecordingComplete: (filePath) async {
            final transcription =
                await whisperTranscriptionService.transcribeVideo(filePath);
            String transcribedText = transcription?.text ?? '';

            setState(() {
              _chatHistory.add(LocalMessage(
                time: DateTime.now(),
                type: LocalMessageType.audio,
                role: LocalMessageRole.user,
                text: transcribedText,
                filePath: filePath,
              ));
            });

            _scrollToBottom();
            _sendTextMessageAndShowTextResponse(transcribedText);
          },
        );
      },
    );

    /*showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return AudioRecorder(onRecordingComplete: (filePath) async {
          final transcription =
              await whisperTranscriptionService.transcribeVideo(filePath);
          String transcribedText = transcription?.text ?? '';

          setState(() {
            _chatHistory.add(LocalMessage(
              time: DateTime.now(),
              type: LocalMessageType.audio,
              role: LocalMessageRole.user,
              text: transcribedText,
              filePath: filePath,
            ));
          });

          _scrollToBottom();
          _sendTextMessageAndShowTextResponse(transcribedText);
        });
      },
    );*/
  }

  void _showAdvisorSpinnerModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true, // Prevent users from dismissing the dialog
      builder: (BuildContext context) {
        return Stack(
          children: [
            Container(
              color: Colors.black
                  .withOpacity(0.5), // Semi-transparent black background
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Analysing conversation and formulating advice - this will take a few seconds',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white), // Ensure text is visible
                  ),
                  const SizedBox(height: 20),
                  JumpingDots(
                    numberOfDots: 3,
                    color: Colors.grey,
                    radius: 3,
                    innerPadding: 4.5,
                    delay: 1000,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _hideAdvisorSpinnerModal(BuildContext context) {
    Navigator.pop(context); // Dismiss the bottom sheet to hide the spinner
  }

  void _showAdvisorModal(BuildContext context, String advisorResponse) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return InformationModal(
            information: advisorResponse, title: 'AI feedback');
      },
      barrierDismissible: true,
    );
  }

  // Function to strip SSML tags from the text
  String stripSSMLTags(String text) {
    final RegExp ssmlRegExp = RegExp(r'<[^>]+>');
    return text.replaceAll(ssmlRegExp, '');
  }

  // Function to handle adding a message to an attempt
  Future<void> _addMessageToAttempt(LocalMessage messageToAdd) async {
    debugPrint('Just before adding $_currentAttemptIndex');
    debugPrint('widget.chatIndex ${widget.chatIndex}');
    debugPrint('messageToAdd ${messageToAdd}');
    debugPrint('attemptIndex ${_currentAttemptIndex}');
    // Await the result of addMessageToAttempt
    int returnedAttemptIndex = await openAiService.addMessageToAttempt(
      widget.chatIndex,
      messageToAdd,
      attemptIndex: _currentAttemptIndex, // Use the current attempt index
    );

    // Update the state with the returned attempt index
    setState(() {
      _currentAttemptIndex = returnedAttemptIndex;
      debugPrint('returnedAttemptIndex = $returnedAttemptIndex');
    });
  }

  // Updated function to handle sending a text message and showing the AI response using the Chat API
  void _sendTextMessageAndShowTextResponse(String text) {
    _showLoadingMessage(LocalMessageRole.ai);

    List<LocalMessage> updatedConversationHistory = List.from(_chatHistory);
    LocalMessage messageToAdd = LocalMessage(
      time: DateTime.now(),
      role: LocalMessageRole.user,
      type: LocalMessageType.text,
      text: text,
    );
    updatedConversationHistory.add(messageToAdd);

    _addMessageToAttempt(messageToAdd);

    openAiService
        .getChatResponseFromMessage(
            updatedConversationHistory, widget.systemMessage)
        .then((aiResponses) async {
      String textToSend = aiResponses.map((msg) => msg.text).join(" ");

      // Send the text to generate audio
      final audioFuture = openAiService.generateAudio(
        text: textToSend,
        voice: widget.voice,
      );

      try {
        final audioBytes =
            await audioFuture.timeout(const Duration(seconds: 5));
        if (audioBytes != null) {
          _playAudio(audioBytes);
        }
      } catch (e) {
        debugPrint(
            'Audio generation timed out, showing text messages instead.');
      }

      // Strip SSML tags from AI responses
      aiResponses = aiResponses.map((msg) {
        //debugPrint(msg.toString());
        _addMessageToAttempt(msg);
        msg.text = msg.text != null ? stripSSMLTags(msg.text!) : null;
        return msg;
      }).toList();

      setState(() {
        _chatHistory.removeLast(); // Remove the loading message
      });
      setState(() {
        _chatHistory.addAll(aiResponses);
      });
      _scrollToBottom();
    });
  }

  void _sendConversationAndShowAdvisorFeedback() {
    //check if we have a _lastAdvisorResponse - if so, then no new messages have been posted/received so just redisplay that
    if (_lastAdvisorResponse != '') {
      _showAdvisorModal(context, _lastAdvisorResponse);
    } else {
      _showAdvisorSpinnerModal(
          context); // Show spinner before making the API call
      //get conversation - text only - from _chatHistory
      String textToSend = '';
      for (var localMessage in _chatHistory) {
        if (localMessage.type == LocalMessageType.text) {
          if (localMessage.role == LocalMessageRole.user) {
            textToSend +=
                'Doctor (${DateFormat('kk:mm:ss').format(localMessage.time)}):';
          } else {
            textToSend +=
                'Patient (${DateFormat('kk:mm:ss').format(localMessage.time)}):';
          }
          textToSend += localMessage.text!;
        }
      }

      openAiService
          .getAssistantResponseFromMessage(textToSend, widget.advisorId)
          .then((aiResponses) {
        String advisorResponse = '';
        for (var aiResponse in aiResponses) {
          advisorResponse += aiResponse.text;
        }
        debugPrint('Got response');
        _hideAdvisorSpinnerModal(context); // Hide spinner when request ends
        _lastAdvisorResponse = advisorResponse;
        _showAdvisorModal(context, advisorResponse);
      });
    }
  }

  /*void _playAudio(Uint8List audioBytes) async {
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = '${tempDir.path}/temp.mp4'; // Using m4a for FlutterSound compatibility
    File tempFile = File(tempPath);

    await tempFile.writeAsBytes(audioBytes);

    try {
      await _flutterSoundPlayer.startPlayer(
        fromURI: tempFile.path,
        codec: Codec.aacMP4, // Ensure the codec is set correctly
        whenFinished: () {
          debugPrint("AI audio playback finished");
        },
      );
    } catch (e) {
      debugPrint('Error playing AI audio: $e');
    }
  }*/

  /*void _playAudio(Uint8List audioBytes) async {
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = '${tempDir.path}/temp.mp3'; // Change to 'temp.aac'?
    File tempFile = File(tempPath);
    debugPrint('File created at: $tempPath');
    await tempFile.writeAsBytes(audioBytes); // Asynchronous write
    debugPrint('Audio file saved at: $tempPath');
    await _audioPlayer.setAudioSource(AudioSource.uri(Uri.file(tempPath)));
    _audioPlayer.play();
    //debugPrint('Trying to play $tempPath');
  }*/

  void _playAudio(Uint8List audioBytes) async {
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = '${tempDir.path}/temp.mp3'; // Change to 'temp.aac'?
    File tempFile = File(tempPath);

    await tempFile.writeAsBytes(audioBytes); // Asynchronous write

    // Test playing the audio
    try {
      await _audioPlayer.setAudioSource(AudioSource.uri(Uri.file(tempPath)));
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error setting audio source: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the available height dynamically

    return Column(
      children: [
        Expanded(
          child: Stack(children: [
            Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
              child: ListView.builder(
                itemCount: _chatHistory.length,
                shrinkWrap: true,
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) => Message(
                    message: _chatHistory[index], avatar: widget.avatar),
                //audioPlayer: _audioPlayer),
              ),
            ),
            Visibility(
              visible: _chatHistory.isNotEmpty,
              child: Positioned(
                bottom: kDefaultPadding, // Adjust the bottom position as needed
                right: kDefaultPadding, // Adjust the right position as needed
                child: FloatingActionButton(
                  onPressed: () {
                    _sendConversationAndShowAdvisorFeedback();
                  },
                  child: const Icon(
                    Icons.tips_and_updates,
                    //color: kPrimaryColor,
                  ),
                ),
              ),
            ),
          ]),
        ),
        //todo - move this out into a separate chat_input widget
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding * 0.1,
            vertical: kDefaultPadding * 0.1,
          ),
          decoration: BoxDecoration(
            color:
                Colors.grey[200], //Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                offset: const Offset(0, 4),
                blurRadius: 32,
                color: const Color(0xFF087949).withOpacity(0.08),
              ),
            ],
          ),
          child: SafeArea(
              child: InputBar(
            onBtnSendPressed: (textOfMessage) {
              // Callback function when message is sent in InputBar
              tempChatHistoryContent =
                  textOfMessage; //hold on to this even afetr we've cleared input
              _showTextMessage(LocalMessageRole.user, tempChatHistoryContent);
              _sendTextMessageAndShowTextResponse(tempChatHistoryContent);
            },
            onBtnVideoPressed: () {
              // Callback function when video button pressed is selected in InputBar
              _showCameraModal(context);
            },
            onBtnAudioPressed: () {
              _showAudioModal(context);
            },
          )),
        )
      ],
    );
  }
}
