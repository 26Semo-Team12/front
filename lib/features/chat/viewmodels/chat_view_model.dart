import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';
import '../services/chat_service.dart';
import '../../../core/network/api_client.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  IO.Socket? _socket;
  
  int? _currentRoomId;
  int? _currentUserId;
  bool _isLoading = false;
  bool _isSocketConnected = false;
  bool _hasMore = false;
  int? _nextBeforeMessageId;

  List<ChatMessage> _messages = [];
  
  int? get currentRoomId => _currentRoomId;
  bool get isLoading => _isLoading;
  bool get isSocketConnected => _isSocketConnected;
  bool get hasMore => _hasMore;

  ChatViewModel() {
    _initUserId();
  }

  Future<void> _initUserId() async {
    // Current implementation doesn't use prefs yet, but might in the future.
  }

  final List<String> aiTemplates = [
    "요즘 가장 재미있게 본 영화는 뭔가요? ✨",
    "주말에 주로 어떤 활동을 하시나요? ✨",
    "최근에 갔던 맛집 공유해요! ✨",
  ];

  List<ChatMessage> get messages => List.unmodifiable(_messages.reversed);

  void initSocket(int userId) {
    if (_socket != null) return;
    _currentUserId = userId;

    SharedPreferences.getInstance().then((prefs) {
      final token = prefs.getString('access_token');
      
      _socket = IO.io('${ApiClient.baseUrl.replaceAll('/api/v1', '')}/chat', IO.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'accessToken': token})
        .build());

      _socket!.onConnect((_) {
        _isSocketConnected = true;
        notifyListeners();
        debugPrint('Chat Socket Connected');
        if (_currentRoomId != null) {
          joinRoom(_currentRoomId!);
        }
      });

      _socket!.onDisconnect((_) {
        _isSocketConnected = false;
        notifyListeners();
        debugPrint('Chat Socket Disconnected');
      });

      _socket!.on('room_history', (data) {
        final List<dynamic> msgsJson = data['messages'];
        _messages = msgsJson.map((j) => ChatMessage.fromJson(j, currentUserId: _currentUserId)).toList();
        _hasMore = data['hasMore'] ?? false;
        _nextBeforeMessageId = data['nextBeforeMessageId'];
        notifyListeners();
      });

      _socket!.on('message', (data) {
        final newMessage = ChatMessage.fromJson(data, currentUserId: _currentUserId);
        _messages.insert(0, newMessage); // 최신이 위로 (또는 아래로, UI에 따라 다름. 여기선 List.unmodifiable(_messages.reversed) 였으므로 insert(0) if reversed used in UI)
        notifyListeners();
      });

      _socket!.on('error', (err) => debugPrint('Chat Socket Error: $err'));
      
      _socket!.connect();
    });
  }

  void joinRoom(int roomId) {
    _currentRoomId = roomId;
    _messages = [];
    if (_socket != null && _socket!.connected) {
      _socket!.emit('join_room', roomId);
    }
    notifyListeners();
  }

  void leaveRoom() {
    if (_currentRoomId != null && _socket != null && _socket!.connected) {
      _socket!.emit('leave_room', _currentRoomId);
    }
    _currentRoomId = null;
    _messages = [];
    notifyListeners();
  }

  Future<void> loadMoreMessages() async {
    if (_currentRoomId == null || !_hasMore || _isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _chatService.getChatMessages(
        _currentRoomId!, 
        beforeMessageId: _nextBeforeMessageId
      );
      final List<dynamic> msgsJson = data['messages'];
      final newMsgs = msgsJson.map((j) => ChatMessage.fromJson(j, currentUserId: _currentUserId)).toList();
      
      _messages.addAll(newMsgs);
      _hasMore = data['hasMore'] ?? false;
      _nextBeforeMessageId = data['nextBeforeMessageId'];
    } catch (e) {
      debugPrint('Failed to load more messages: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty || _currentRoomId == null) return;
    if (_socket == null || !_socket!.connected) {
      debugPrint('Socket not connected. Cannot send message.');
      return;
    }

    _socket!.emit('send_message', {
      'roomId': _currentRoomId,
      'content': text,
    });
  }

  Future<ChatRoom> openGatheringRoom(int gatheringId) async {
    return await _chatService.openGatheringChatRoom(gatheringId);
  }

  @override
  void dispose() {
    _socket?.dispose();
    super.dispose();
  }
}
