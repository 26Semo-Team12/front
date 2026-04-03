import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../viewmodels/gathering_detail_view_model.dart';
import '../../chat/views/chat_screen.dart';
import '../models/schedule_option.dart';

class RegularView extends StatelessWidget {
  const RegularView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GatheringDetailViewModel>();
    final inv = viewModel.invitation;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.face, color: Colors.black, size: 28),
            SizedBox(width: 8),
            Text('앱 이름', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () {},
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(color: Colors.black, height: 2),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image Area
            SizedBox(
              height: 220,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background Image
                  if (inv.imageUrl != null && inv.imageUrl!.isNotEmpty)
                    Image.file(
                      File(inv.imageUrl!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: const Color(0xFFD6706D).withValues(alpha: 0.2)),
                    )
                  else
                    Container(color: const Color(0xFFD6706D).withValues(alpha: 0.2)),
                  
                  // Black Gradient overlay for text readability
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black54, Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                      ),
                    ),
                  ),

                  // Image Change Button
                  Positioned(
                    top: 16,
                    right: 16,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        onPressed: () async {
                          final picker = ImagePicker();
                          final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                          if (pickedFile != null) {
                            viewModel.updateImage(pickedFile.path);
                          }
                        },
                      ),
                    ),
                  ),

                  // Title Area
                  Positioned(
                    top: 16,
                    left: 16,
                    child: GestureDetector(
                      onTap: () => _showEditNameDialog(context, viewModel),
                      child: Row(
                        children: [
                          Text(
                            inv.title.isNotEmpty ? inv.title : '정기 모임',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.edit, color: Colors.white70, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Album Segment
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('앨범', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Icon(Icons.chevron_right, size: 20),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 140,
                    padding: const EdgeInsets.only(top: 16, bottom: 16, left: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 4,
                      itemBuilder: (ctx, i) {
                        return Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade500,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Schedule Segment
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('일정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_box, size: 28, color: Color(0xFFD6706D)),
                        onPressed: () => _showScheduleCreateSheet(context, viewModel),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Render Schedules
                  if (viewModel.sortedScheduleOptions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 24),
                      child: Text('새로운 일정을 만들어보세요.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    )
                  else
                    ...viewModel.sortedScheduleOptions.map((s) => _buildScheduleCard(context, viewModel, s)),
                  
                  const SizedBox(height: 32),

                  // Chat Segment
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('채팅방', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Icon(Icons.chevron_right, size: 20),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            gatheringId: int.tryParse(inv.id),
                            gatheringTitle: inv.title,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('최근 채팅', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildChatBubble('흠'),
                                    _buildChatBubble('이해한 것 같아요'),
                                    _buildChatBubble('더 궁금한 점이 있으면 도움말 센터에 문의할게요'),
                                  ],
                                ),
                              ),
                              const Text('13분 전', style: TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold)),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard(BuildContext context, GatheringDetailViewModel viewModel, ScheduleOption schedule) {
    // Format Date securely (Mock)
    final y = schedule.startAt.year;
    final m = schedule.startAt.month.toString().padLeft(2, '0');
    final d = schedule.startAt.day.toString().padLeft(2, '0');
    final h = schedule.startAt.hour.toString().padLeft(2, '0');
    final min = schedule.startAt.minute.toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.event_available, color: Color(0xFFD6706D), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$y.$m.$d $h:$min', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    if (schedule.isSelected)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text('확정된 일정', style: TextStyle(color: Color(0xFFD6706D), fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Vote Toggles
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => viewModel.voteSchedule(schedule.id, VoteStatus.AVAILABLE),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: schedule.myVote == VoteStatus.AVAILABLE ? const Color(0xFFD6706D) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: schedule.myVote == VoteStatus.AVAILABLE ? const Color(0xFFD6706D) : Colors.grey.shade300),
                    ),
                    child: Text(
                      '참여 (${schedule.availableCount})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: schedule.myVote == VoteStatus.AVAILABLE ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => viewModel.voteSchedule(schedule.id, VoteStatus.MAYBE),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: schedule.myVote == VoteStatus.MAYBE ? Colors.orange : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: schedule.myVote == VoteStatus.MAYBE ? Colors.orange : Colors.grey.shade300),
                    ),
                    child: Text(
                      '미정 (${schedule.maybeCount})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: schedule.myVote == VoteStatus.MAYBE ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => viewModel.voteSchedule(schedule.id, VoteStatus.UNAVAILABLE),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: schedule.myVote == VoteStatus.UNAVAILABLE ? Colors.grey : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: schedule.myVote == VoteStatus.UNAVAILABLE ? Colors.grey : Colors.grey.shade300),
                    ),
                    child: Text(
                      '불참 (${schedule.unavailableCount})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: schedule.myVote == VoteStatus.UNAVAILABLE ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!schedule.isSelected)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ElevatedButton(
                onPressed: () => viewModel.finalizeSchedule(schedule.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 36),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('이 일정으로 확정하기', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, GatheringDetailViewModel viewModel) {
    final ctrl = TextEditingController(text: viewModel.invitation.title);
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('모임 이름 수정', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(
              hintText: '새로운 이름을 입력하세요.',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD6706D)),
              onPressed: () {
                if (ctrl.text.trim().isNotEmpty) {
                  viewModel.updateTitle(ctrl.text.trim());
                  Navigator.pop(context);
                }
              },
              child: const Text('저장', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showScheduleCreateSheet(BuildContext context, GatheringDetailViewModel viewModel) {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateSheet) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('일정 생성', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                            icon: const Icon(Icons.calendar_today, color: Colors.black87),
                            label: Text(
                              '${selectedDate.year}.${selectedDate.month}.${selectedDate.day}',
                              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setStateSheet(() => selectedDate = date);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                            icon: const Icon(Icons.access_time, color: Colors.black87),
                            label: Text(
                              '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                              );
                              if (time != null) {
                                setStateSheet(() => selectedTime = time);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD6706D),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        final dt = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );
                        viewModel.addSchedule(dt);
                        Navigator.pop(context);
                      },
                      child: const Text('일정 만들기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChatBubble(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
         color: Colors.white.withValues(alpha: 0.9),
         borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: const TextStyle(fontSize: 14, color: Colors.black87)),
    );
  }
}
