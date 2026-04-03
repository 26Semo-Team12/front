import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../viewmodels/gathering_detail_view_model.dart';
import '../../chat/views/chat_screen.dart';
import '../../profile/views/settings_screen.dart';
import '../models/schedule_option.dart';

class RegularView extends StatefulWidget {
  const RegularView({super.key});

  @override
  State<RegularView> createState() => _RegularViewState();
}

class _RegularViewState extends State<RegularView> {
  PageController _headerPageController = PageController();
  Timer? _autoSlideTimer;
  int _currentHeaderPage = 0;
  int _lastImageCount = 0;

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _headerPageController.dispose();
    super.dispose();
  }

  void _rebuildControllerIfNeeded(int imageCount) {
    if (imageCount != _lastImageCount && imageCount > 0) {
      _headerPageController.dispose();
      _headerPageController = PageController();
      _currentHeaderPage = 0;
      _lastImageCount = imageCount;
    }
  }

  void _startAutoSlide() {
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      final viewModel = context.read<GatheringDetailViewModel>();
      final images = _getImages(viewModel);
      if (images.length <= 1) return;
      final next = (_currentHeaderPage + 1) % images.length;
      _headerPageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  List<String> _getImages(GatheringDetailViewModel vm) {
    final images = List<String>.from(vm.albumImages);
    if (vm.invitation.imageUrl != null && vm.invitation.imageUrl!.isNotEmpty) {
      if (!images.contains(vm.invitation.imageUrl)) {
        images.insert(0, vm.invitation.imageUrl!);
      }
    }
    return images;
  }

  void _openPhotoViewer(BuildContext context, List<String> images, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => _PhotoViewer(images: images, initialIndex: initialIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GatheringDetailViewModel>();
    final inv = viewModel.invitation;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final images = _getImages(viewModel);
    _rebuildControllerIfNeeded(images.length);

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
              // ── 헤더 슬라이드쇼 ──
              _buildHeader(context, viewModel, images, isDark),

              // ── 구성원 행 ──
              _buildMembersRow(context, viewModel, cs, isDark),

              Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 일정 ──
                    _buildSectionHeader(context, '일정', cs,
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 24, color: Color(0xFFD6706D)),
                        onPressed: () => _showScheduleCreateSheet(context, viewModel),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (viewModel.sortedScheduleOptions.isEmpty)
                      _buildEmptyState(context, '새로운 일정을 만들어보세요.', Icons.event_note, cs)
                    else
                      ...viewModel.sortedScheduleOptions.map((s) => _buildScheduleCard(context, viewModel, s)),

                    const SizedBox(height: 32),

                    // ── 채팅방 ──
                    GestureDetector(
                      onTap: goToChat,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(context, '채팅방', cs,
                            trailing: Icon(Icons.chevron_right, size: 20, color: cs.onSurface.withValues(alpha: 0.5)),
                          ),
                          const SizedBox(height: 12),
                          _buildChatPreview(context, viewModel, cs, isDark),
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

  // ── 헤더 슬라이드쇼 ──────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, GatheringDetailViewModel viewModel, List<String> images, bool isDark) {
    return SizedBox(
      height: 260,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 슬라이드쇼
          images.isEmpty
              ? Container(
                  color: const Color(0xFFD6706D).withValues(alpha: 0.08),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_library_outlined, size: 40, color: Color(0xFFD6706D)),
                        SizedBox(height: 10),
                        Text('아직 사진이 없어요.',
                            style: TextStyle(color: Color(0xFFD6706D), fontSize: 15, fontWeight: FontWeight.w500)),
                        SizedBox(height: 4),
                        Text('사진 추가 버튼을 눌러 추가해보세요.',
                            style: TextStyle(color: Color(0xFFD6706D), fontSize: 12)),
                      ],
                    ),
                  ),
                )
              : PageView.builder(
                  controller: _headerPageController,
                  itemCount: images.length,
                  onPageChanged: (i) => setState(() => _currentHeaderPage = i),
                  itemBuilder: (_, i) {
                    final url = images[i];
                    return GestureDetector(
                      onTap: () => _openPhotoViewer(context, images, i),
                      child: _buildImageWidget(url),
                    );
                  },
                ),
          // 그라디언트 오버레이
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black54, Colors.transparent, Colors.black38],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),

          // 사진 추가 버튼
          Positioned(
            top: 12, right: 12,
            child: GestureDetector(
              onTap: () async {
                final picker = ImagePicker();
                final f = await picker.pickImage(source: ImageSource.gallery);
                if (f != null) viewModel.updateImage(f.path);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text('사진 추가', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),

          // 모임 이름 + 편집
          Positioned(
            bottom: 40, left: 16, right: 60,
            child: GestureDetector(
              onTap: () => _showEditNameDialog(context, viewModel),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      viewModel.invitation.title.isNotEmpty ? viewModel.invitation.title : '정기 모임',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.edit, color: Colors.white70, size: 16),
                ],
              ),
            ),
          ),

          // 페이지 인디케이터
          if (images.length > 1)
            Positioned(
              bottom: 12,
              left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentHeaderPage == i ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentHeaderPage == i ? Colors.white : Colors.white54,
                    borderRadius: BorderRadius.circular(3),
                  ),
                )),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(url, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: const Color(0xFFD6706D).withValues(alpha: 0.2)));
    }
    return Image.file(File(url), fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: const Color(0xFFD6706D).withValues(alpha: 0.2)));
  }

  // ── 구성원 행 ────────────────────────────────────────────────────────────────
  Widget _buildMembersRow(BuildContext context, GatheringDetailViewModel viewModel, ColorScheme cs, bool isDark) {
    final members = viewModel.members;
    if (members.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          for (int i = 0; i < members.length.clamp(0, 7); i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.grey.shade700 : Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(members[i]['imageUrl'] ?? ''),
                      backgroundColor: cs.surfaceContainerHighest,
                      onBackgroundImageError: (_, __) {},
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    members[i]['name'] ?? '',
                    style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
          if (members.length > 7)
            Column(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: cs.onSurface.withValues(alpha: 0.08),
                  child: Text('+${members.length - 7}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.onSurface.withValues(alpha: 0.6))),
                ),
                const SizedBox(height: 4),
                Text('더보기', style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.4))),
              ],
            ),
        ],
      ),
    );
  }

  // ── 섹션 헤더 ────────────────────────────────────────────────────────────────
  Widget _buildSectionHeader(BuildContext context, String title, ColorScheme cs, {Widget? trailing}) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: cs.onSurface)),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  // ── 빈 상태 ──────────────────────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context, String message, IconData icon, ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: cs.onSurface.withValues(alpha: 0.25)),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 14)),
        ],
      ),
    );
  }

  // ── 채팅 미리보기 ─────────────────────────────────────────────────────────────
  Widget _buildChatPreview(BuildContext context, GatheringDetailViewModel viewModel, ColorScheme cs, bool isDark) {
    final latest = viewModel.latestMessage;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade50,
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: latest == null
          ? Row(
              children: [
                Icon(Icons.chat_bubble_outline, size: 18, color: cs.onSurface.withValues(alpha: 0.3)),
                const SizedBox(width: 8),
                Text('아직 채팅 메시지가 없어요.', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 14)),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: cs.surfaceContainerHighest,
                  child: Icon(Icons.person, size: 18, color: cs.onSurface.withValues(alpha: 0.5)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(latest['sender'] ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.onSurface.withValues(alpha: 0.6))),
                      const SizedBox(height: 2),
                      Text(latest['text'] ?? '', style: TextStyle(fontSize: 14, color: cs.onSurface), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(latest['time'] ?? '', style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
              ],
            ),
    );
  }

  // ── 일정 카드 ─────────────────────────────────────────────────────────────────
  Widget _buildScheduleCard(BuildContext context, GatheringDetailViewModel viewModel, ScheduleOption schedule) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dt = schedule.startAt;
    final kst = dt.isUtc ? dt.add(const Duration(hours: 9)) : dt;
    final dateStr = '${kst.year}.${kst.month.toString().padLeft(2, '0')}.${kst.day.toString().padLeft(2, '0')}';
    final ampm = kst.hour < 12 ? '오전' : '오후';
    final hour12 = kst.hour == 0 ? 12 : (kst.hour > 12 ? kst.hour - 12 : kst.hour);
    final timeStr = '$ampm $hour12시';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: schedule.isSelected
              ? const Color(0xFFD6706D).withValues(alpha: 0.6)
              : (isDark ? Colors.white12 : Colors.grey.shade200),
          width: schedule.isSelected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.05),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6706D).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.event, color: Color(0xFFD6706D), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dateStr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: cs.onSurface)),
                      Text(timeStr, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.55))),
                    ],
                  ),
                ),
                if (schedule.isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6706D).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('확정', style: TextStyle(color: Color(0xFFD6706D), fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade100),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                _voteButton(context, Icons.check, '참여\n${schedule.availableCount}',
                    schedule.myVote == VoteStatus.AVAILABLE, const Color(0xFFD6706D),
                    () => viewModel.voteSchedule(schedule.id, VoteStatus.AVAILABLE)),
                const SizedBox(width: 8),
                _voteButton(context, Icons.help_outline, '미정\n${schedule.maybeCount}',
                    schedule.myVote == VoteStatus.MAYBE, Colors.orange,
                    () => viewModel.voteSchedule(schedule.id, VoteStatus.MAYBE)),
                const SizedBox(width: 8),
                _voteButton(context, Icons.close, '불참\n${schedule.unavailableCount}',
                    schedule.myVote == VoteStatus.UNAVAILABLE, Colors.grey.shade500,
                    () => viewModel.voteSchedule(schedule.id, VoteStatus.UNAVAILABLE)),
              ],
            ),
          ),
          if (!schedule.isSelected)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => viewModel.finalizeSchedule(schedule.id),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFD6706D)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('이 일정으로 확정하기',
                      style: TextStyle(color: Color(0xFFD6706D), fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _voteButton(BuildContext context, IconData icon, String label, bool isSelected, Color activeColor, VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: 0.12) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? activeColor : (isDark ? Colors.white12 : Colors.grey.shade200)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: isSelected ? activeColor : cs.onSurface.withValues(alpha: 0.4)),
              const SizedBox(height: 4),
              Text(label, textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? activeColor : cs.onSurface.withValues(alpha: 0.5))),
            ],
          ),
        ),
      ),
    );
  }

  // ── 모임 이름 수정 다이얼로그 ─────────────────────────────────────────────────
  void _showEditNameDialog(BuildContext context, GatheringDetailViewModel viewModel) {
    final ctrl = TextEditingController(text: viewModel.invitation.title);
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6706D).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit, color: Color(0xFFD6706D), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('모임 이름 수정', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: cs.onSurface)),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '모임 이름을 입력하세요',
                  filled: true,
                  fillColor: cs.onSurface.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD6706D), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('취소', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (ctrl.text.trim().isNotEmpty) {
                          viewModel.updateTitle(ctrl.text.trim());
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD6706D),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('저장', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 일정 생성 팝업 ────────────────────────────────────────────────────────────
  void _showScheduleCreateSheet(BuildContext context, GatheringDetailViewModel viewModel) {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          final cs = Theme.of(ctx).colorScheme;
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD6706D).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.event_available, color: Color(0xFFD6706D), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text('일정 추가', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: cs.onSurface)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // 날짜 선택
                  GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context, initialDate: selectedDate,
                        firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) setStateDialog(() => selectedDate = date);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.onSurface.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Color(0xFFD6706D), size: 18),
                          const SizedBox(width: 12),
                          Text('${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: cs.onSurface)),
                          const Spacer(),
                          Icon(Icons.chevron_right, size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 시간 선택
                  GestureDetector(
                    onTap: () async {
                      final time = await showTimePicker(context: context, initialTime: selectedTime);
                      if (time != null) setStateDialog(() => selectedTime = time);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.onSurface.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, color: Color(0xFFD6706D), size: 18),
                          const SizedBox(width: 12),
                          Text('${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: cs.onSurface)),
                          const Spacer(),
                          Icon(Icons.chevron_right, size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('취소', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6))),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD6706D),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            final dt = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute);
                            viewModel.addSchedule(dt);
                            Navigator.pop(ctx);
                          },
                          child: const Text('추가', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── 사진 전체화면 뷰어 ──────────────────────────────────────────────────────────
class _PhotoViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  const _PhotoViewer({required this.images, required this.initialIndex});

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _ctrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('${_current + 1} / ${widget.images.length}',
            style: const TextStyle(color: Colors.white, fontSize: 14)),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _ctrl,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) {
          final url = widget.images[i];
          final isLocal = !url.startsWith('http://') && !url.startsWith('https://');
          return InteractiveViewer(
            child: Center(
              child: isLocal
                  ? Image.file(File(url), fit: BoxFit.contain)
                  : Image.network(url, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54, size: 64)),
            ),
          );
        },
      ),
    );
  }
}
