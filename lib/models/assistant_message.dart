//Written by ChatGPT, with a hbit of help around deadling with potentially null values of class proprties ie ? if they really will be null or required if they won't
//see: https://platform.openai.com/docs/api-reference/messages/object
class MessageText {
  String value;
  List<dynamic> annotations;

  MessageText({
    required this.value,
    required this.annotations,
  });

  factory MessageText.fromJson(Map<String, dynamic> json) {
    return MessageText(
      value: json['value'],
      annotations: List<dynamic>.from(json['annotations']),
    );
  }
}

class MessageContent {
  String type;
  MessageText text;

  MessageContent({
    required this.type,
    required this.text,
  });

  factory MessageContent.fromJson(Map<String, dynamic> json) {
    return MessageContent(
      type: json['type'],
      text: MessageText.fromJson(json['text']),
    );
  }
}

class AssistantMessage {
  String id;
  String object;
  int createdAt;
  String threadId;
  String role;
  List<MessageContent> content;
  List<String> attachments;
  String? assistantId;
  String? runId;
  Map<String, dynamic> metadata;

  AssistantMessage({
    required this.id,
    required this.object,
    required this.createdAt,
    required this.threadId,
    required this.role,
    required this.content,
    required this.attachments,
    this.assistantId,
    this.runId,
    required this.metadata,
  });

  factory AssistantMessage.fromJson(Map<String, dynamic> json) {
    return AssistantMessage(
      id: json['id'],
      object: json['object'],
      createdAt: json['created_at'],
      threadId: json['thread_id'],
      role: json['role'],
      content: List<MessageContent>.from(
          json['content'].map((content) => MessageContent.fromJson(content))),
      attachments: List<String>.from(json['attachments']), //this has chnaged from file_id in v1 of API
      assistantId: json['assistant_id'] as String?,
      runId: json['run_id'] as String?,
      metadata: json['metadata'],
    );
  }
}
