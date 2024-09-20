import 'dart:convert'; // package to encode/decode JSON data type
import 'dart:async'; //for the Timer
import 'dart:typed_data'; //Uint8List

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // dot_env package
import 'package:http/http.dart' as http; // http package

import 'package:hive/hive.dart';

import '../models/assistant_message.dart';
import '../models/local_message.dart';
import 'package:comm_skills_chatbot_kestrel/models/attempt.dart';

var openAIApiKey = dotenv.env[
    'OPEN_AI_API_KEY']; //access the OPEN_AI_API_KEY from the .env file in the root directory
var openAIApiAssistantsEndpoint = dotenv.env[
    'ASSISTANTS_API_URL']; //access the OPEN_AI_API_KEY from the .env file in the root directory
var chatApiEndpoint = dotenv.env['CHAT_API_URL'];
var openAISpeechEndpoint = dotenv.env['SPEECH_API_URL'];

String speechifySpeechEndpoint = dotenv.env['SPEECHIFY_API_URL'] ??
    'https://api.sws.speechify.com/v1/audio/speech';
var speechifySpeechKey = dotenv.env['SPEECHIFY_API_KEY'];

class OpenAiService {
  String _assistantId = '';

  //note that all of these maps will have a key of _assistantId, so that we
  //don't get mixed up between state in different assistants
  //not strictly necessary while a new instance of OpenAIService (and therefore
  //a new _threadId, etc) is created for every launch of the messages_body (ie
  //a new conversation every time the user opens a chat) but might be useful in
  //future, if we instantiate OpenAiService at a higher level in the tree and
  //allow students to come back to a partially complete conversation
  final Map<String, String> _threadId = {};
  final Map<String, String> _lastMessageId = {};
  final Map<String, String> _runId = {};
  final Map<String, bool> _runComplete = {}; //was false;

  /// Gets a response from the assistant for a message.
  ///
  /// Returns a <List<LocalMessage>> of messages recieved from the Assistant AI

  Future getAssistantResponseFromMessage(String message, assistantId) async {
    // declaring a messages List to collate chat history
    List<LocalMessage> messages = [];
    _assistantId = assistantId;

    //debugPrint(message);
    //if no assistant, create assistant - for now just use ID = asst_oLP6zXce2HxRuR4dDPBDt3IM

    debugPrint('Do we have a _threadId? ${_threadId[_assistantId]}');

    //if no thread, create a thread
    if (_threadId[_assistantId] == null ||
        _threadId[_assistantId].toString() == "") {
      _threadId[_assistantId] = await _createThread();
    }

    //debugPrint('_threadId ' + _threadId[_assistantId].toString());

    //attach message(s) to thread as user
    String messageId = '';
    if (_threadId[_assistantId] != "" && message != "") {
      messageId = await _addMesageToThread(message, _threadId[_assistantId]);
    }

    debugPrint('messageId $messageId');

    //run assistant on the thread
    if (_assistantId != "" && _threadId[_assistantId] != "") {
      _runId[_assistantId] =
          await _runAssistantOnThread(_assistantId, _threadId[_assistantId]);
    }

    debugPrint('_runId[_assistantId] ${_runId[_assistantId]}');

    //is run complete
    if (_runId[_assistantId] != "" && _threadId[_assistantId] != "") {
      _runComplete[_assistantId] = await _isRunComplete(
          _threadId[_assistantId].toString(), _runId[_assistantId].toString());
    }

    debugPrint('_runComplete[_assistantId] ${_runComplete[_assistantId]}');

    //get messages from completed run
    if (_runComplete[_assistantId]! && _threadId[_assistantId] != "") {
      messages = await _getCompletedResponse(_threadId[_assistantId]);
    }

    debugPrint('messages $messages');

    return messages;
  }

  /// Creates a thread.
  ///
  /// Returns a [threadId] or an error message

  Future<String> _createThread() async {
    // post the prompt to the API and receive response
    try {
      final res = await http.post(
        Uri.parse("$openAIApiAssistantsEndpoint"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $openAIApiKey",
          "OpenAI-Beta": "assistants=v2",
        },
      );
      //debugPrint('openAIApiAssistantsEndpoint $openAIApiAssistantsEndpoint');
      if (res.statusCode == 200) {
        // decode the JSON response
        Map<String, dynamic> response = jsonDecode(res.body);
        String threadId = response['id'];
        debugPrint('threadId $threadId');
        return threadId;
      } else {
        var statusCode = res.statusCode.toString();
        return "OOPS! An Error occured in thread creation. Status code: $statusCode";
      }
    } catch (error) {
      return error.toString();
    }
  }

  /// Adds a [message] to a thread with [threadId].
  ///
  /// Returns a [messageId] or an error message

  Future<String> _addMesageToThread(message, threadId) async {
    //debugPrint(message);
    try {
      final res = await http.post(
        Uri.parse("$openAIApiAssistantsEndpoint/$threadId/messages"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $openAIApiKey",
          "OpenAI-Beta": "assistants=v2",
        },
        // encode the object to JSON
        body: jsonEncode(
          {
            "role": "user",
            "content": message,
          },
        ),
      );

      if (res.statusCode == 200) {
        // decode the JSON response
        Map<String, dynamic> response = jsonDecode(res.body);
        String messageId = response['id'];
        return messageId;
      } else {
        var statusCode = res.statusCode.toString();
        return "OOPS! An Error occured in message adding. Status code: $statusCode";
      }
    } catch (error) {
      return error.toString();
    }
  }

  /// Runs an assistant with [assistantId] on a thread with [threadId].
  ///
  /// Returns a [runId] or an error message

  Future<String> _runAssistantOnThread(assistantId, threadId) async {
    try {
      final res = await http.post(
        Uri.parse("$openAIApiAssistantsEndpoint/$threadId/runs"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $openAIApiKey",
          "OpenAI-Beta": "assistants=v2",
        },
        // encode the object to JSON
        body: jsonEncode(
          {
            "assistant_id": assistantId,
          },
        ),
      );

      if (res.statusCode == 200) {
        // decode the JSON response
        Map<String, dynamic> response = jsonDecode(res.body);
        String runId = response['id'];
        return runId;
      } else {
        var statusCode = res.statusCode.toString();
        return "OOPS! An Error occured in running the assistant $assistantId on the thread $threadId. Status code: $statusCode";
      }
    } catch (error) {
      return error.toString();
    }
  }

  /// Checks whether a run with [runId] on thread with [threadId] has status = complete.
  ///
  /// Returns a record of with (true or false, message)
  /// Adapted from code written by ChatGPT

  Future<bool> _isRunComplete(String threadId, String runId) async {
    bool isComplete = false;
    int maxAttempts = 10; // Set the maximum number of attempts
    int attempt = 0;

    while (!isComplete && attempt < maxAttempts) {
      //debugPrint('$openAIApiAssistantsEndpoint/$threadId/runs/$runId');
      final response = await http.get(
        Uri.parse('$openAIApiAssistantsEndpoint/$threadId/runs/$runId'),
        headers: {
          'Authorization': 'Bearer $openAIApiKey',
          "OpenAI-Beta": "assistants=v2",
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final runStatus = responseData['status'];

        if (runStatus == 'completed') {
          isComplete = true;
          //debugPrint('Run $runId on Thread $threadId is complete.');
        } else {
          //debugPrint('Run $runId on Thread $threadId is still processing...');
        }
      } else {
        //debugPrint('Error checking run status: ${response.statusCode}');
      }

      await Future.delayed(
          const Duration(seconds: 5)); // Wait for 5 seconds before next attempt
      attempt++;
    }

    return isComplete;
  }

  /// Get messages from a completed assistant run from a thread with [threadId], with optionally, a [afterMessageId] to specify message after which to return messages .
  ///
  /// Returns a list of the messages

  Future<(List<dynamic>?, String)> _getMessagesFromThread(threadId,
      [afterMessageId]) async {
    try {
      String url = "$openAIApiAssistantsEndpoint/$threadId/messages";
      if (afterMessageId != null) {
        debugPrint('afterMessageId coming through as $afterMessageId');
        url =
            "$url?api-version=2024-02-15-preview&order=asc&after=$afterMessageId"; //add after paramter value if fromMessageId
      } else {
        url = "$url?api-version=2024-02-15-preview";
      }
      final res = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $openAIApiKey",
          "OpenAI-Beta": "assistants=v2",
        },
      );

      if (res.statusCode == 200) {
        // decode the JSON response
        Map<String, dynamic> response = jsonDecode(res.body);
        List<dynamic> messageList = response['data'];
        return (messageList, "No problems");
      } else {
        var statusCode = res.statusCode.toString();
        return (
          null,
          "OOPS! An Error occured in getting messages from the thread $threadId. Status code: $statusCode"
        );
      }
    } catch (error) {
      return (null, error.toString());
    }
  }

  /// Chcek for completion of run with [runId] from a thread with [threadId]
  ///
  /// Returns a <List<LocalMessage>> of the the messages

  Future<List<LocalMessage>> _getCompletedResponse(threadId) async {
    List<LocalMessage> messages = [];

    //Now that we know the run has completed, return the new messages
    List<dynamic>? returnedMessages = [];
    String statusText = "";
    if (_threadId[_assistantId] != "") {
      //debugPrint("going in $_lastMessageId");
      if (_lastMessageId[_assistantId] != "") {
        (returnedMessages, statusText) = await _getMessagesFromThread(
            _threadId[_assistantId], _lastMessageId[_assistantId]);
        //debugPrint('Im using $_lastMessageId');
      } else {
        (returnedMessages, statusText) =
            await _getMessagesFromThread(_threadId[_assistantId]);
        //debugPrint('Im not using a last message Id');
      }
    }
    //debugPrint(statusText);
    //now pull messages out into the messages List
    if (returnedMessages != null) {
      for (var returnedMessage in returnedMessages) {
        final assistantMessage = AssistantMessage.fromJson(returnedMessage);
        debugPrint(
            '${assistantMessage.content[0].text.value} id: ${assistantMessage.id}');
        if (assistantMessage.role != "user") {
          //discard role:user messages
          messages.add(//{
              LocalMessage(
                  time: DateTime.now(),
                  role: LocalMessageRole.ai,
                  type: LocalMessageType.text,
                  text: assistantMessage.content[0].text.value));

          _lastMessageId[_assistantId] = assistantMessage
              .id; //update the _lastMessageId with the last loaded message so that _getMessagesFromThread can be told to only return messages after that
        }

        //debugPrint("coming out $_lastMessageId");
      }
    }
    //debugPrint(messages.toString());
    return messages;
  }

  //Deals with Chat API (for student-'patient' interactions)
  //Note that this needs not just the current messages but the whole conversation history
  Future<List<LocalMessage>> getChatResponseFromMessage(
      List<LocalMessage> conversationHistory, String systemMessage) async {
    List<LocalMessage> messages = [];

    // Prepare the conversation history in the proper format for Chat API
    /*List<Map<String, String>> messagesPayload = conversationHistory.map((message) {
      return {
        'role': message.role == LocalMessageRole.user ? 'user' : 'assistant',
        'content': message.text,
      };
    }).toList();*/

    List<Map<String, String>> messagesPayload = [
      {
        'role': 'system',
        'content': systemMessage,
      }
    ];

    messagesPayload.addAll(conversationHistory.map((message) {
      String role =
          message.role == LocalMessageRole.user ? 'user' : 'assistant';
      String content = message.text ?? ''; // Handle nullable text

      return {
        'role': role,
        'content': content,
      };
    }).toList());

    /*List<Map<String, String>> messagesPayload =
        conversationHistory.map((message) {
      String role =
          message.role == LocalMessageRole.user ? 'user' : 'assistant';
      String content = message.text ?? ''; // Handle nullable text

      return {
        'role': role,
        'content': content,
      };
    }).toList();*/

    try {
      final response = await http.post(
        Uri.parse(chatApiEndpoint!),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAIApiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o', // specify the model
          'messages': messagesPayload,
          'temperature': 0.7,
        }),
      );

      // Check the response status code
      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        List<dynamic> choices = responseData['choices'];

        for (var choice in choices) {
          Map<String, dynamic> message = choice['message'];
          if (message['role'] == 'assistant') {
            messages.add(LocalMessage(
              time: DateTime.now(),
              role: LocalMessageRole.ai,
              type: LocalMessageType.text,
              text: message['content'],
            ));
          }
        }
      } else {
        throw Exception("Failed to fetch the response from the Chat API");
      }
    } catch (error) {
      throw Exception("An error occurred: $error");
    }

    return messages;
  }

  /// Get speech from [openAISpeechEndpoint] using [voice] for [text]
  ///
  /// Returns a Future<Uint8List?> of the audio

  /*Future<Uint8List?> generateAudio({
    required String text,
    required String voice,
    String model = 'tts-1',
    String responseFormat = 'mp3',
    double speed = 1.0,
  }) async {
    text = removeTextInSquareBrackets(
        text); //remove any non-verbals in square brackets
    final url = Uri.parse('$openAISpeechEndpoint');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $openAIApiKey',
    };
    final body = {
      'model': model,
      'input': text,
      'voice': 'shimmer', //todo relace with voiceß
      'response_format': responseFormat,
      'speed': speed,
    };

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      debugPrint('I have a response');
      return response.bodyBytes;
    } else {
      print('Failed to generate audio: ${response.statusCode}');
      return null;
    }
  }*/

  /// Get speech from Speechify using [voice] for [text]
  ///
  /// Returns a Future<Uint8List?> of the audio
  Future<Uint8List?> generateAudio({
    required String text,
    required String voice,
    String model = 'simba-turbo',
    String responseFormat = 'mp3',
    String language = 'en-GB',
  }) async {
    //text = removeTextInSquareBrackets(
    //    text); // Remove any non-verbals in square brackets

    text = _cleanText(text);

    final url = Uri.parse(speechifySpeechEndpoint);
    final headers = {
      'Content-Type': 'application/json',
      'Authorization':
          'Bearer $speechifySpeechKey', // Replace with your Speechify API Key
    };
    final body = {
      'audio_format': responseFormat,
      'input': text,
      'language': language,
      'voice_id': voice, //voice,
      'model': model,
    };

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode(body),
    );

    final encodedBody = json.encode(body);

    debugPrint(url.toString());
    debugPrint(headers.toString());
    debugPrint(encodedBody.toString());

    if (response.statusCode == 200) {
      debugPrint('Audio generated successfully');
      final jsonResponse = json.decode(response.body);
      String audioData = jsonResponse['audio_data'];
      return base64Decode(audioData);
    } else {
      debugPrint('Failed to generate audio: ${response.statusCode}');
      return null;
    }
  }

  Future<int> addMessageToAttempt(int chatId, LocalMessage message,
      {int? attemptIndex}) async {
    final box = Hive.box<Attempt>('chatHistory');

    if (attemptIndex == null) {
      // If attemptIndex is null, find the maximum existing index for this chat and increment it
      final attemptsForChat =
          box.values.where((attempt) => attempt.chatId == chatId).toList();

      if (attemptsForChat.isEmpty) {
        // If no previous attempts, start with index 0
        attemptIndex = 0;
      } else {
        // Get the maximum index from the existing attempts
        attemptIndex = attemptsForChat
                .map((attempt) => attempt.index)
                .reduce((curr, next) => curr > next ? curr : next) +
            1;
      }

      debugPrint('New attemptIndex for chatId $chatId: $attemptIndex');
    }

    // Find the key of the existing attempt if it exists
    final existingKey = box.keys.firstWhere(
      (key) {
        final attempt = box.get(key);
        return attempt?.chatId == chatId && attempt?.index == attemptIndex;
      },
      orElse: () => null, // Return null if no matching key is found
    );

    if (existingKey == null) {
      // If no existing attempt, create a new one
      Attempt newAttempt = Attempt(
        index: attemptIndex,
        date: DateTime.now(),
        messages: [message],
        chatId: chatId,
      );

      // Save the new attempt to Hive
      await box.add(newAttempt);
    } else {
      // If the attempt exists, add the message to it
      Attempt? existingAttempt = box.get(existingKey);
      if (existingAttempt != null) {
        existingAttempt.messages.add(message);
        existingAttempt.date =
            DateTime.now(); // Update the date to the current date

        // Save the updated attempt back to Hive
        await box.put(existingKey, existingAttempt);
      }
    }

    // Return the attemptIndex used
    return attemptIndex;
  }

  String _cleanText(String text) {
    // Remove any non-verbals in square brackets
    text = text.replaceAll(RegExp(r'\[.*?\]'), '');
    // Remove double newlines
    text = text.replaceAll('\n\n', '');
    // Remove single newlines
    text = text.replaceAll('\n', '');
    // Remove exclamation marks
    text = text.replaceAll('!', '.');
    // Replace UTF-8 apostrophes with standard ASCII apostrophes
    text = _replaceUTF8Apostrophes(text);
    // Trim spaces outside <speak> tags
    final RegExp speakTagRegExp =
        RegExp(r'^\s*<speak>(.*)</speak>\s*$', multiLine: true, dotAll: true);
    if (speakTagRegExp.hasMatch(text)) {
      final match = speakTagRegExp.firstMatch(text);
      if (match != null) {
        final contentInsideSpeak = match.group(1)?.trim() ?? '';
        text = '<speak>$contentInsideSpeak</speak>';
      }
    } else {
      text = text.trim(); // If no <speak> tags, just trim the entire text
    }

    // Validate and fix tags
    text = _ensureSpeakTagClosed(text);

    return text;
  }

  // Helper function to ensure <speak> tag is closed and remove orphaned closing tags
  String _ensureSpeakTagClosed(String text) {
    // Check if <speak> tag is present
    final RegExp speakTagOpenRegExp = RegExp(r'<speak>');
    final RegExp speakTagCloseRegExp = RegExp(r'</speak>');

    final bool hasOpenTag = speakTagOpenRegExp.hasMatch(text);
    final bool hasCloseTag = speakTagCloseRegExp.hasMatch(text);

    if (hasOpenTag && !hasCloseTag) {
      // Add closing tag at the end if it is missing
      text += '</speak>';
    }

    // Remove any orphaned closing tags
    text = text.replaceAllMapped(speakTagCloseRegExp, (match) {
      // Check the part of the string before this closing tag
      final beforeCloseTag = text.substring(0, match.start);
      if (beforeCloseTag.contains('<speak>')) {
        return match.group(0) ?? '';
      } else {
        // Orphaned closing tag found
        return '';
      }
    });

    return text;
  }

  String _replaceUTF8Apostrophes(String text) {
    // Replace common UTF-8 apostrophe variants with standard ASCII apostrophe
    text = text.replaceAll('â', "'");
    text = text.replaceAll('’', "'");
    return text;
  }
}
