enum LocalMessageType { text, audio, image, video, loading }

enum LocalMessageRole { user, ai }

class LocalMessage {
  DateTime time;
  LocalMessageRole role;
  LocalMessageType type;
  String? text = '';
  String? filePath = '';

  LocalMessage({
    required this.time,
    required this.role,
    required this.type,
    this.text,
    this.filePath,
  });

  // Convert LocalMessage to JSON
  Map<String, dynamic> toJson() {
    return {
      'time': time.millisecondsSinceEpoch, // Store time as milliseconds
      'role': role.name, // Store the enum name (e.g., "user", "ai")
      'type': type.name, // Store the enum name
      'text': text,
      'filePath': filePath,
    };
  }

  // Create LocalMessage from JSON
  factory LocalMessage.fromJson(Map<String, dynamic> json) {
    return LocalMessage(
      time: DateTime.fromMillisecondsSinceEpoch(json['time']),
      role: LocalMessageRole.values
          .byName(json['role']), // Map enum name to value
      type: LocalMessageType.values.byName(json['type']),
      text: json['text'],
      filePath: json['filePath'],
    );
  }
}
