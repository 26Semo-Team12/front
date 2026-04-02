import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../models/chat_message.dart';
import '../viewmodels/chat_view_model.dart';
import 'widgets/ladder_game_dialog.dart';

class ChatScreen extends StatelessWidget {
  final String gatheringTitle;

  const ChatScreen({super.key, required this.gatheringTitle});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatViewModel(),
      child: _ChatScreenContent(gatheringTitle: gatheringTitle),
    );
  }
}

class _ChatScreenContent extends StatefulWidget {
  final String gatheringTitle;
  const _ChatScreenContent({required this.gatheringTitle});

  @override
  State<_ChatScreenContent> createState() => _ChatScreenContentState();
}

class _ChatScreenContentState extends State<_ChatScreenContent> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _handleSend(ChatViewModel viewModel) {
    if (_textController.text.trim().isEmpty) return;
    viewModel.sendMessage(_textController.text);
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChatViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.gatheringTitle.isNotEmpty ? widget.gatheringTitle : '정기 모임', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: viewModel.messages.length,
                itemBuilder: (context, index) {
                  final msg = viewModel.messages[index];
                  return _buildMessageBubble(msg);
                },
              ),
            ),
            
            _buildAiIcebreakingPanel(viewModel),

            _buildInputArea(viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    bool isMe = msg.isMe;

    if (msg.type == ChatMessageType.system) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(msg.text, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        ),
      );
    }
    
    if (msg.type == ChatMessageType.aiIcebreaking) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFD6706D).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD6706D), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFFD6706D), size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(msg.text, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD6706D))),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.black87,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFD6706D) : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 0),
                  bottomRight: Radius.circular(isMe ? 0 : 16),
                ),
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiIcebreakingPanel(ChatViewModel viewModel) {
    if (viewModel.aiTemplates.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: viewModel.aiTemplates.map((template) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(template, style: const TextStyle(color: Color(0xFFD6706D), fontWeight: FontWeight.bold, fontSize: 13)),
                backgroundColor: const Color(0xFFD6706D).withValues(alpha: 0.1),
                side: const BorderSide(color: Color(0xFFD6706D)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                onPressed: () {
                  _textController.text = template.replaceAll(' ✨', '');
                  _textController.selection = TextSelection.fromPosition(TextPosition(offset: _textController.text.length));
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInputArea(ChatViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black54),
            onPressed: () => _showAttachmentMenu(context),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: '메시지 입력...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                fillColor: Colors.grey.shade100,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onSubmitted: (_) => _handleSend(viewModel),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFD6706D),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () => _handleSend(viewModel),
            ),
          ),
        ],
      ),
    );
  }

  void _showAttachmentMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 40, left: 24, right: 24),
          child: Wrap(
            spacing: 32,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              _buildAttachItem(ctx, Icons.image, '사진', () => _pickImage(ctx)),
              _buildAttachItem(ctx, Icons.videocam, '동영상', () => _pickVideo(ctx)),
              _buildAttachItem(ctx, Icons.attach_file, '파일', () => _pickFile(ctx)),
              _buildAttachItem(ctx, Icons.calendar_today, '일정', () => _pickSchedule(ctx)),
              _buildAttachItem(ctx, Icons.casino, '사다리타기', () => _playMinigame(ctx)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachItem(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFD6706D).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFFD6706D), size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87)),
        ],
      ),
    );
  }

  void _pickImage(BuildContext ctx) async {
    Navigator.pop(ctx);
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      final viewModel = context.read<ChatViewModel>();
      viewModel.sendMessage('[사진 전송됨: ${pickedFile.name}]', type: ChatMessageType.system, isMe: true);
    }
  }

  void _pickVideo(BuildContext ctx) async {
    Navigator.pop(ctx);
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      final viewModel = context.read<ChatViewModel>();
      viewModel.sendMessage('[동영상 전송됨: ${pickedFile.name}]', type: ChatMessageType.system, isMe: true);
    }
  }

  void _pickFile(BuildContext ctx) async {
    Navigator.pop(ctx);
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && mounted) {
      final viewModel = context.read<ChatViewModel>();
      viewModel.sendMessage('[파일 전송됨: ${result.files.single.name}]', type: ChatMessageType.system, isMe: true);
    }
  }

  void _pickSchedule(BuildContext ctx) async {
    Navigator.pop(ctx);
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null && mounted) {
      TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null && mounted) {
        final viewModel = context.read<ChatViewModel>();
        final y = date.year;
        final m = date.month.toString().padLeft(2, '0');
        final d = date.day.toString().padLeft(2, '0');
        final h = time.hour.toString().padLeft(2, '0');
        final min = time.minute.toString().padLeft(2, '0');
        
        viewModel.sendMessage('📅 새로운 일정이 제안되었습니다: $y년 $m월 $d일 $h:$min', type: ChatMessageType.system, isMe: false);
        // TODO: 일정 생성/투표 화면으로 네비게이션 트리거 연동 필요
      }
    }
  }

  void _playMinigame(BuildContext ctx) {
    Navigator.pop(ctx);
    showDialog(
      context: context,
      builder: (_) {
        return LadderGameDialog(
          onResultSelected: (resultString) {
            final viewModel = context.read<ChatViewModel>();
            viewModel.sendMessage(resultString, type: ChatMessageType.aiIcebreaking, isMe: false);
          },
        );
      },
    );
  }
}

