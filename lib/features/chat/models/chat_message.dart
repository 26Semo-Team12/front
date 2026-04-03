// lib/features/chat/models/chat_message.dart

enum ChatMessageType { 
  text, 
  aiIcebreaking, 
  system;

  static ChatMessageType fromString(String val) {
    if (val == 'AI_ICEBREAKING') return ChatMessageType.aiIcebreaking;
    if (val == 'SYSTEM') return ChatMessageType.system;
    return ChatMessageType.text;
  }

  String get value {
    if (this == ChatMessageType.aiIcebreaking) return 'AI_ICEBREAKING';
    if (this == ChatMessageType.system) return 'SYSTEM';
    return 'TEXT';
  }
}

class ChatMessage {
  final int id;
  final int roomId;
  final int senderUserId;
  final String senderName; // UI mapping
  final String text;
  final DateTime timestamp;
  final ChatMessageType type;
  final bool isMe;
  final bool isAiGenerated;

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderUserId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.type = ChatMessageType.text,
    this.isMe = false,
    this.isAiGenerated = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, {int? currentUserId}) {
    final senderId = json['senderUserId'] as int;
    return ChatMessage(
      id: json['id'] as int,
      roomId: json['roomId'] as int,
      senderUserId: senderId,
      senderName: senderId == currentUserId ? '나' : (json['senderName'] as String? ?? '유저 $senderId'),
      text: json['content'] as String? ?? '',
      timestamp: DateTime.parse(json['createdAt'] as String),
      type: ChatMessageType.fromString(json['messageType'] as String? ?? 'TEXT'),
      isMe: senderId == currentUserId,
      isAiGenerated: json['isAiGenerated'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'senderUserId': senderUserId,
      'content': text,
      'createdAt': timestamp.toIso8601String(),
      'messageType': type.value,
      'isAiGenerated': isAiGenerated,
    };
  }
}
