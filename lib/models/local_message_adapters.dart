import 'package:hive/hive.dart';

import 'package:comm_skills_chatbot_kestrel/models/local_message.dart'; // Your LocalMessage class

// Register the enums
class LocalMessageTypeAdapter extends TypeAdapter<LocalMessageType> {
  @override
  final typeId = 0;

  @override
  LocalMessageType read(BinaryReader reader) {
    return LocalMessageType.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, LocalMessageType obj) {
    writer.writeInt(obj.index);
  }
}

class LocalMessageRoleAdapter extends TypeAdapter<LocalMessageRole> {
  @override
  final typeId = 1;

  @override
  LocalMessageRole read(BinaryReader reader) {
    return LocalMessageRole.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, LocalMessageRole obj) {
    writer.writeInt(obj.index);
  }
}

class LocalMessageAdapter extends TypeAdapter<LocalMessage> {
  @override
  final typeId = 2;

  @override
  LocalMessage read(BinaryReader reader) {
    return LocalMessage(
      time: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      role: LocalMessageRole.values[reader.readInt()],
      type: LocalMessageType.values[reader.readInt()],
      text: reader.readString(),
      filePath: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, LocalMessage obj) {
    writer.writeInt(obj.time.millisecondsSinceEpoch);
    writer.writeInt(obj.role.index);
    writer.writeInt(obj.type.index);
    writer.writeString(obj.text ?? '');
    writer.writeString(obj.filePath ?? '');
  }
}
