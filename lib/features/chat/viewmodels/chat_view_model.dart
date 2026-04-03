import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class ChatViewModel extends ChangeNotifier {
  final List<ChatMessage> _messages = [
    ChatMessage(
      id: 'msg_0',
      senderName: '나',
      text: '흠',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      isMe: true,
    ),
    ChatMessage(
      id: 'msg_1',
      senderName: '다른 유저',
      text: '이해한 것 같아요',
      timestamp: DateTime.now().subtract(const Duration(minutes: 14)),
      isMe: false,
    ),
    ChatMessage(
      id: 'msg_2',
      senderName: '다른 유저',
      text: '더 궁금한 점이 있으면 도움말 센터에 문의할게요',
      timestamp: DateTime.now().subtract(const Duration(minutes: 13)),
      isMe: false,
    ),
  ];

  List<ChatMessage> get messages => List.unmodifiable(_messages.reversed);

  final List<String> aiTemplates = [
    "요즘 가장 재미있게 본 영화는 뭔가요? ✨",
    "주말에 주로 어떤 활동을 하시나요? ✨",
    "최근에 갔던 맛집 공유해요! ✨",
  ];

  void sendMessage(String text, {ChatMessageType type = ChatMessageType.text, bool isMe = true}) {
    if (text.trim().isEmpty) return;

    final newMessage = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderName: isMe ? '나' : '시스템',
      text: text,
      timestamp: DateTime.now(),
      type: type,
      isMe: isMe,
    );
    _messages.add(newMessage);
    notifyListeners();
  }
}
