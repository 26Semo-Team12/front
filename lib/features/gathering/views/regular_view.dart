import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../viewmodels/gathering_detail_view_model.dart';
import '../../chat/views/chat_screen.dart';
import '../../profile/views/settings_screen.dart';
import '../models/schedule_option.dart';

class RegularView extends StatelessWidget {
  const RegularView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GatheringDetailViewModel>();
    final inv = viewModel.invitation;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    void goToChat() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            gatheringId: int.tryParse(inv.id),
            gatheringTitle: inv.title,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Image.asset('assets/images/logo_2.png', height: 32, fit: BoxFit.contain),
        centerTitle: false,
        toolbarHeight: kToolbarHeight,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: cs.onSurface),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Image
              SizedBox(
                height: 220,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (inv.imageUrl != null && inv.imageUrl!.isNotEmpty)
                      Image.file(File(inv.imageUrl!), fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: const Color(0xFFD6706D).withValues(alpha: 0.2)))
                    else
                      Container(color: const Color(0xFFD6706D).withValues(alpha: 0.2)),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black54, Colors.transparent],
                          begin: Alignment.topCenter,
                          end: Alignment.center,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16, right: 16,
                      child: CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: () async {
                            final picker = ImagePicker();
                            final f = await picker.pickImage(source: ImageSource.gallery);
                            if (f != null) viewModel.updateImage(f.path);
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16, left: 16,
                      child: GestureDetector(
                        onTap: () => _showEditNameDialog(context, viewModel),
                        child: Row(
                          children: [
                            Text(
                              inv.title.isNotEmpty ? inv.title : '정기 모임',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
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
                padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Album
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('앨범', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
                        Icon(Icons.chevron_right, size: 20, color: cs.onSurface),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 140,
                      padding: const EdgeInsets.only(top: 16, bottom: 16, left: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 4,
                        itemBuilder: (ctx, i) => Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 12),
                          color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.grey.shade500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Schedule
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('일정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
                        IconButton(
                          icon: const Icon(Icons.add_box, size: 28, color: Color(0xFFD6706D)),
                          onPressed: () => _showScheduleCreateSheet(context, viewModel),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (viewModel.sortedScheduleOptions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Text('새로운 일정을 만들어보세요.',
                            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.bold)),
                      )
                    else
                      ...viewModel.sortedScheduleOptions.map((s) => _buildScheduleCard(context, viewModel, s)),

                    const SizedBox(height: 32),

                    // Chat
                    GestureDetector(
                      onTap: goToChat,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('채팅방', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
                                Icon(Icons.chevron_right, size: 20, color: cs.onSurface),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100,
                              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('최근 채팅', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: cs.onSurface)),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      width: 32, height: 32,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isDark ? Colors.white24 : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildChatBubble(context, '흠'),
                                          _buildChatBubble(context, '이해한 것 같아요'),
                                          _buildChatBubble(context, '더 궁금한 점이 있으면 도움말 센터에 문의할게요'),
                                        ],
                                      ),
                                    ),
                                    Text('13분 전',
                                        style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleCard(BuildContext context, GatheringDetailViewModel viewModel, ScheduleOption schedule) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final y = schedule.startAt.year;
    final m = schedule.startAt.month.toString().padLeft(2, '0');
    final d = schedule.startAt.day.toString().padLeft(2, '0');
    final h = schedule.startAt.hour.toString().padLeft(2, '0');
    final min = schedule.startAt.minute.toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        boxShadow: [BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black12, blurRadius: 4, offset: const Offset(2, 2))],
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
                    Text('$y.$m.$d $h:$min', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: cs.onSurface)),
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
          Row(
            children: [
              _voteButton(context, '참여 (${schedule.availableCount})', schedule.myVote == VoteStatus.AVAILABLE,
                  const Color(0xFFD6706D), () => viewModel.voteSchedule(schedule.id, VoteStatus.AVAILABLE)),
              const SizedBox(width: 8),
              _voteButton(context, '미정 (${schedule.maybeCount})', schedule.myVote == VoteStatus.MAYBE,
                  Colors.orange, () => viewModel.voteSchedule(schedule.id, VoteStatus.MAYBE)),
              const SizedBox(width: 8),
              _voteButton(context, '불참 (${schedule.unavailableCount})', schedule.myVote == VoteStatus.UNAVAILABLE,
                  Colors.grey, () => viewModel.voteSchedule(schedule.id, VoteStatus.UNAVAILABLE)),
            ],
          ),
          if (!schedule.isSelected)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ElevatedButton(
                onPressed: () => viewModel.finalizeSchedule(schedule.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white24 : Colors.black,
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

  Widget _voteButton(BuildContext context, String label, bool isSelected, Color activeColor, VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? activeColor : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? activeColor : (isDark ? Colors.white24 : Colors.grey.shade300)),
          ),
          child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : cs.onSurface)),
        ),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, GatheringDetailViewModel viewModel) {
    final ctrl = TextEditingController(text: viewModel.invitation.title);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('모임 이름 수정', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: '새로운 이름을 입력하세요.', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소', style: TextStyle(color: Colors.grey))),
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
      ),
    );
  }

  void _showScheduleCreateSheet(BuildContext context, GatheringDetailViewModel viewModel) {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateSheet) {
          final cs = Theme.of(ctx).colorScheme;
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('일정 생성', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                          icon: Icon(Icons.calendar_today, color: cs.onSurface),
                          label: Text('${selectedDate.year}.${selectedDate.month}.${selectedDate.day}',
                              style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context, initialDate: selectedDate,
                              firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) setStateSheet(() => selectedDate = date);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                          icon: Icon(Icons.access_time, color: cs.onSurface),
                          label: Text(
                            '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () async {
                            final time = await showTimePicker(context: context, initialTime: selectedTime);
                            if (time != null) setStateSheet(() => selectedTime = time);
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
                      final dt = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute);
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
      ),
    );
  }

  Widget _buildChatBubble(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87)),
    );
  }
}
