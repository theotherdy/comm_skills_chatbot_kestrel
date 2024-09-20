import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_dotenv/flutter_dotenv.dart'; // dot_env package

class TranscriptionText {
  final String text;

  TranscriptionText({required this.text});

  factory TranscriptionText.fromJson(Map<String, dynamic> json) {
    return TranscriptionText(text: json['text'] ?? '');
  }
}

class WhisperTranscriptionService {
  //final String apiKey;
  //final String apiEndpoint;
  final String model;
  final String language;
  final String prompt;
  final String responseFormat;
  final double temperature;

  WhisperTranscriptionService({
    //required this.apiKey,
    //required this.apiEndpoint,
    this.model = 'whisper-1',
    this.language = 'en',
    this.prompt = '',
    this.responseFormat = 'json',
    this.temperature = 0,
  });

  Future<TranscriptionText?> transcribeVideo(String filePath) async {
    var openAIApiKey = dotenv.env[
        'OPEN_AI_API_KEY']; //access the OPEN_AI_API_KEY from the .env file in the root directory
    var whisperApiEndpoint = dotenv.env[
        'WHISPER_API_URL']; //access the OPEN_AI_API_KEY from the .env file in the root directory

    final Uri uri = Uri.parse(whisperApiEndpoint.toString());
    final File file = File(filePath);

    try {
      final Map<String, String> requestFields = {
        'model': model,
        'language': language,
        'prompt': prompt,
        'response_format': responseFormat,
        'temperature': temperature.toString(),
      };

      debugPrint(whisperApiEndpoint.toString());
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $openAIApiKey'
        ..fields.addAll(requestFields)
        ..files.add(http.MultipartFile(
          'file',
          file.readAsBytes().asStream(),
          file.lengthSync(),
          filename:
              'audio.${file.path.split('.').last}', //constructs a new filename with the prefix 'audio.' followed by the original file extension. This is used to ensure that the transcribed audio file has an appropriate filename.
        ));

      final response = await http.Response.fromStream(await request.send());

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return TranscriptionText.fromJson(data);
      } else {
        debugPrint('Error from Whisper: ${response.statusCode}');
        debugPrint(response.body);
        return null;
      }
    } catch (error) {
      debugPrint('Error from Whisper: $error');
      return null;
    }
  }
}

// Example usage:
/*void main() async {
  //final apiKey = 'YOUR_OPENAI_API_KEY';
  //final apiEndpoint = 'https://api.openai.com';
  const model = 'whisper-1';

  final whisperTranscriptionService = WhisperTranscriptionService(
    //apiKey: apiKey,
    //apiEndpoint: apiEndpoint,
    model: model,
  );

  const filePath = '/path/to/your/video/file.mp4';
  final transcription = await whisperTranscriptionService.transcribeVideo(filePath);

  if (transcription != null) {
    debugPrint('Transcription: ${transcription.text}');
  } else {
    debugPrint('Failed to transcribe video.');
  }
}*/
