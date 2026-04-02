enum ChatMessageType { text, aiIcebreaking, system }

class ChatMessage {
  final String id;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final ChatMessageType type;
  final bool isMe;

  ChatMessage({
    required this.id,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.type = ChatMessageType.text,
    required this.isMe,
  });
}
