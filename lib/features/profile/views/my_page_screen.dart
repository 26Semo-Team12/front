import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/models/tag_colors.dart';
import '../../auth/services/auth_service.dart';
import '../../home/viewmodels/home_view_model.dart';
import '../../home/views/location_picker.dart';
import '../viewmodels/profile_view_model.dart';
import 'settings_screen.dart';
import '../../../core/utils/image_utils.dart';

const List<String> kInterestPresets = [
  '등산', '독서', '요리', '여행', '사진', '음악', '영화', '게임', '운동', '카페',
  '드라이브', '캠핑', '낚시', '자전거', '수영', '테니스', '골프', '볼링', '당구',
  '보드게임', '그림', '공예', '뜨개질', '원예', '반려동물', '봉사', '언어교환',
  '스터디', '재테크', '명상', '요가', '필라테스', '댄스', '노래', '악기',
];

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel(AuthService()),
      child: _MyPageContent(
        onPop: () {
          // 마이페이지 닫힐 때 홈화면 프로필 갱신
          try {
            context.read<HomeViewModel>().refreshUser();
          } catch (_) {}
        },
      ),
    );
  }
}

class _MyPageContent extends StatelessWidget {
  final VoidCallback? onPop;
  const _MyPageContent({this.onPop});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileViewModel>();
    final user = viewModel.currentUser;

    if (viewModel.isLoading || user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFD6706D))),
      );
    }

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            onPop?.call();
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),
              _ProfileHeader(user: user, viewModel: viewModel),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      context: context,
                      title: '주 활동 지역',
                      onEdit: () => showDialog(
                        context: context,
                        builder: (_) => LocationPicker(
                          onSelected: (loc) => viewModel.addLocation(loc),
                        ),
                      ),
                      child: _buildLocationChips(user, viewModel, cs),
                    ),
                    const SizedBox(height: 28),
                    _buildSection(
                      context: context,
                      title: '나의 관심사',
                      onEdit: () => showDialog(
                        context: context,
                        builder: (_) => _InterestPickerDialog(viewModel: viewModel),
                      ),
                      child: _buildInterestChips(user, viewModel),
                    ),
                    const SizedBox(height: 28),
                    _buildSection(
                      context: context,
                      title: '모임 가능 시간',
                      onEdit: () => _showTimeSlotPicker(context, user, viewModel),
                      child: _buildTimeChips(user, cs),
                    ),
                    const SizedBox(height: 28),
                    _buildSection(
                      context: context,
                      title: '기본 정보',
                      onEdit: null,
                      child: _buildInfoChips(user),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required VoidCallback? onEdit,
    required Widget child,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface)),
            if (onEdit != null)
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6706D).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit, size: 16, color: Color(0xFFD6706D)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildLocationChips(UserProfile user, ProfileViewModel viewModel, ColorScheme cs) {
    if (user.locations.isEmpty) {
      return Text('등록된 활동 지역이 없습니다.',
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 14));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: user.locations.map((loc) => Chip(
        label: Text(loc.displayLabel,
            style: const TextStyle(color: Colors.white, fontSize: 13)),
        backgroundColor: kTagColors[TagType.location] ?? const Color(0xFF4A90D9),
        deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white70),
        onDeleted: () => viewModel.removeTag(loc.displayLabel, TagType.location),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      )).toList(),
    );
  }

  Widget _buildInterestChips(UserProfile user, ProfileViewModel viewModel) {
    if (user.interests.isEmpty) {
      return Text('등록된 관심사가 없습니다.',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 14));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: user.interests.map((interest) => Chip(
        label: Text(interest,
            style: const TextStyle(color: Colors.white, fontSize: 13)),
        backgroundColor: kTagColors[TagType.interest] ?? const Color(0xFFE05C5C),
        deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white70),
        onDeleted: () => viewModel.removeTag(interest, TagType.interest),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      )).toList(),
    );
  }

  Widget _buildTimeChips(UserProfile user, ColorScheme cs) {
    if (user.availableTimes.isEmpty) {
      return Text('등록된 모임 가능 시간이 없습니다.',
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 14));
    }
    final byDay = <int, List<int>>{};
    for (final slot in user.availableTimes) {
      byDay.putIfAbsent(slot.weekday, () => []).add(slot.hourIndex);
    }
    const dayLabels = ['월', '화', '수', '목', '금', '토', '일'];
    const timeColor = Color(0xFF7B68EE);
    final sortedDays = byDay.keys.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedDays.map((day) {
        final hours = byDay[day]!..sort();
        final ranges = <String>[];
        int s = hours[0], e = hours[0];
        for (int i = 1; i < hours.length; i++) {
          if (hours[i] == e + 1) { e = hours[i]; }
          else { ranges.add(_formatRange(s, e)); s = hours[i]; e = hours[i]; }
        }
        ranges.add(_formatRange(s, e));
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32, height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: day >= 5 ? timeColor : timeColor.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(dayLabels[day],
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Wrap(
                  spacing: 6, runSpacing: 6,
                  children: ranges.map((r) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: timeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: timeColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(r,
                        style: const TextStyle(color: Color(0xFF5B4FC7), fontSize: 13)),
                  )).toList(),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatRange(int start, int end) {
    final s = '${start.toString().padLeft(2, '0')}:00';
    if (start == end) return s;
    return '$s – ${(end + 1).toString().padLeft(2, '0')}:00';
  }

  Widget _buildInfoChips(UserProfile user) {
    final chips = <Widget>[];
    if (user.gender != null) {
      chips.add(Chip(
        label: Text(user.gender!.displayName,
            style: const TextStyle(color: Colors.white, fontSize: 13)),
        backgroundColor: kTagColors[TagType.gender] ?? const Color(0xFFE8A838),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ));
    }
    if (user.ageRange?.isNotEmpty ?? false) {
      chips.add(Chip(
        label: Text(user.ageRange!,
            style: const TextStyle(color: Colors.white, fontSize: 13)),
        backgroundColor: kTagColors[TagType.ageRange] ?? const Color(0xFF50C878),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ));
    }
    if (chips.isEmpty) {
      return Text('등록된 정보가 없습니다.',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 14));
    }
    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  void _showTimeSlotPicker(
      BuildContext context, UserProfile user, ProfileViewModel viewModel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _TimeSlotPickerScreen(
          initialSlots: List<TimeSlot>.from(user.availableTimes),
          onSave: (slots) => viewModel.updateAvailableTimes(slots),
        ),
      ),
    );
  }
}

// ─── 프로필 헤더 (사진 수정 포함) ────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final UserProfile user;
  final ProfileViewModel viewModel;
  const _ProfileHeader({required this.user, required this.viewModel});

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('프로필 사진 변경',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('앨범에서 선택'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('카메라로 촬영'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 800);
    if (picked == null) return;

    final bytes = await File(picked.path).readAsBytes();
    final ext = picked.path.split('.').last.toLowerCase();
    final mime = (ext == 'png') ? 'image/png'
        : (ext == 'webp') ? 'image/webp'
        : 'image/jpeg';
    final base64Str = base64Encode(bytes);
    final dataUrl = 'data:$mime;base64,$base64Str';

    if (context.mounted) {
      await viewModel.updateProfileImage(dataUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        // 프로필 사진 + 편집 버튼
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            SafeCircleAvatar(
              radius: 48,
              imageUrl: user.profileImageUrl,
              backgroundColor: Colors.grey.shade200,
            ),
            GestureDetector(
              onTap: () => _pickImage(context), // ignore: discarded_futures
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFD6706D),
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.surface, width: 2),
                ),
                child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(user.name,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: cs.onSurface)),
        const SizedBox(height: 6),
        Text(
          '${user.displayBirthYear} · ${user.gender?.displayName ?? '성별미상'}',
          style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5)),
        ),
      ],
    );
  }
}

// ─── 관심사 선택 다이얼로그 ────────────────────────────────────────────────────
final _sortedInterests = List<String>.from(kInterestPresets)..sort();

const _chosungList = [
  'ㄱ','ㄲ','ㄴ','ㄷ','ㄸ','ㄹ','ㅁ','ㅂ','ㅃ','ㅅ',
  'ㅆ','ㅇ','ㅈ','ㅉ','ㅊ','ㅋ','ㅌ','ㅍ','ㅎ',
];

({int cho, int jung, int jong})? _decomposeHangul(String char) {
  final code = char.codeUnitAt(0);
  if (code < 0xAC00 || code > 0xD7A3) return null;
  final offset = code - 0xAC00;
  return (cho: offset ~/ 588, jung: (offset % 588) ~/ 28, jong: offset % 28);
}

bool _isJamo(String char) {
  final code = char.codeUnitAt(0);
  return code >= 0x3131 && code <= 0x314E;
}

int _jamoToChosungIndex(String jamo) => _chosungList.indexOf(jamo);

bool _charMatches(String qChar, String wChar, {required bool isLast}) {
  if (_isJamo(qChar)) {
    final qIdx = _jamoToChosungIndex(qChar);
    if (qIdx < 0) return qChar == wChar;
    final wd = _decomposeHangul(wChar);
    if (wd == null) return false;
    return wd.cho == qIdx;
  }
  final qd = _decomposeHangul(qChar);
  if (qd == null) return qChar.toLowerCase() == wChar.toLowerCase();
  final wd = _decomposeHangul(wChar);
  if (wd == null) return false;
  if (qd.cho != wd.cho || qd.jung != wd.jung) return false;
  if (isLast) return qd.jong == 0 || qd.jong == wd.jong;
  return qd.jong == wd.jong;
}

bool _interestMatchesQuery(String word, String query) {
  if (query.isEmpty) return true;
  final qChars = query.characters.toList();
  final wChars = word.characters.toList();
  if (qChars.length > wChars.length) return false;
  for (var start = 0; start <= wChars.length - qChars.length; start++) {
    bool ok = true;
    for (var i = 0; i < qChars.length; i++) {
      if (!_charMatches(qChars[i], wChars[start + i], isLast: i == qChars.length - 1)) {
        ok = false; break;
      }
    }
    if (ok) return true;
  }
  return false;
}

class _InterestPickerDialog extends StatefulWidget {
  final ProfileViewModel viewModel;
  const _InterestPickerDialog({required this.viewModel});

  @override
  State<_InterestPickerDialog> createState() => _InterestPickerDialogState();
}

class _InterestPickerDialogState extends State<_InterestPickerDialog> {
  final _searchController = TextEditingController();
  List<String> _filtered = _sortedInterests;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearch);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchController.text.trim();
    setState(() {
      _filtered = q.isEmpty
          ? _sortedInterests
          : _sortedInterests.where((s) => _interestMatchesQuery(s, q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.55,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 + X버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('관심사 추가',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: '관심사 검색...',
                  prefixIcon:
                      const Icon(Icons.search, size: 20, color: Colors.grey),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              size: 18, color: Colors.grey),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: cs.onSurface.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _filtered.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('검색 결과가 없습니다.',
                            style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final item = _filtered[i];
                        final added = widget.viewModel.currentUser?.interests
                                .contains(item) ??
                            false;
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                          title:
                              Text(item, style: const TextStyle(fontSize: 15)),
                          trailing: added
                              ? const Icon(Icons.check_circle,
                                  color: Color(0xFFD6706D), size: 20)
                              : const Icon(Icons.add_circle_outline,
                                  color: Color(0xFFD6706D), size: 20),
                          onTap: added
                              ? null
                              : () {
                                  widget.viewModel
                                      .addTag(item, TagType.interest);
                                  Navigator.pop(context);
                                },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 모임 가능 시간 선택 (전체화면) ──────────────────────────────────────────
class _TimeSlotPickerScreen extends StatefulWidget {
  final List<TimeSlot> initialSlots;
  final ValueChanged<List<TimeSlot>> onSave;

  const _TimeSlotPickerScreen({
    required this.initialSlots,
    required this.onSave,
  });

  @override
  State<_TimeSlotPickerScreen> createState() => _TimeSlotPickerScreenState();
}

class _TimeSlotPickerScreenState extends State<_TimeSlotPickerScreen> {
  late Set<String> _selectedKeys;

  static const _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];
  static const _startHour = 6;
  static const _endHour = 23;
  static const _timeLabelWidth = 36.0;

  bool? _isDragSelecting;
  final Set<String> _draggedKeys = {};
  final GlobalKey _gridKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _selectedKeys = widget.initialSlots
        .map((s) => '${s.weekday}-${s.hourIndex}')
        .toSet();
  }

  String _key(int weekday, int hour) => '$weekday-$hour';

  List<TimeSlot> _buildSlots() => _selectedKeys.map((k) {
        final p = k.split('-');
        return TimeSlot(weekday: int.parse(p[0]), hourIndex: int.parse(p[1]));
      }).toList();

  ({int weekday, int hour})? _hitTest(Offset globalPos) {
    final rb = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (rb == null) return null;
    final local = rb.globalToLocal(globalPos);
    if (local.dx < _timeLabelWidth || local.dx > rb.size.width) return null;

    // 헤더 높이 계산: 요일 행 높이를 rowHeight와 동일하게 맞춤
    final totalRows = _endHour - _startHour + 1 + 1; // +1 for header
    final rowHeight = rb.size.height / totalRows;
    final y = local.dy - rowHeight; // 헤더 제외
    if (y < 0) return null;

    final rowIdx = (y / rowHeight).floor();
    final hour = _startHour + rowIdx;
    if (hour > _endHour) return null;

    final cellW = (rb.size.width - _timeLabelWidth) / 7;
    final col = ((local.dx - _timeLabelWidth) / cellW).floor();
    if (col < 0 || col > 6) return null;

    return (weekday: col, hour: hour);
  }

  void _onPointerDown(PointerDownEvent e) {
    final cell = _hitTest(e.position);
    if (cell == null) return;
    final k = _key(cell.weekday, cell.hour);
    _isDragSelecting = !_selectedKeys.contains(k);
    _draggedKeys..clear()..add(k);
    _applyDrag(k);
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (_isDragSelecting == null) return;
    final cell = _hitTest(e.position);
    if (cell == null) return;
    final k = _key(cell.weekday, cell.hour);
    if (_draggedKeys.contains(k)) return;
    _draggedKeys.add(k);
    _applyDrag(k);
  }

  void _onPointerUp(PointerUpEvent e) {
    _isDragSelecting = null;
    _draggedKeys.clear();
  }

  void _applyDrag(String k) {
    setState(() {
      if (_isDragSelecting!) {
        _selectedKeys.add(k);
      } else {
        _selectedKeys.remove(k);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFFD6706D);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hours = List.generate(_endHour - _startHour + 1, (i) => _startHour + i);
    final totalRows = hours.length + 1; // +1 헤더

    return Scaffold(
      appBar: AppBar(
        title: const Text('모임 가능 시간 선택',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() => _selectedKeys.clear()),
            child: Text('초기화',
                style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.5), fontSize: 14)),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: () {
                widget.onSave(_buildSlots());
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('저장',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.touch_app,
                      size: 14, color: cs.onSurface.withValues(alpha: 0.4)),
                  const SizedBox(width: 4),
                  Text('탭 또는 드래그하여 시간을 선택하세요',
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.4))),
                ],
              ),
            ),
            // 그리드: Expanded로 남은 공간 전부 사용 → 스크롤 없이 모든 셀 표시
            Expanded(
              child: Listener(
                onPointerDown: _onPointerDown,
                onPointerMove: _onPointerMove,
                onPointerUp: _onPointerUp,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final rowH = constraints.maxHeight / totalRows;
                      final cellVMargin = rowH * 0.06;
                      final cellH = rowH - cellVMargin * 2;

                      return Column(
                        key: _gridKey,
                        children: [
                          // 요일 헤더
                          SizedBox(
                            height: rowH,
                            child: Row(
                              children: [
                                SizedBox(width: _timeLabelWidth),
                                ...List.generate(7, (d) => Expanded(
                                  child: Center(
                                    child: Text(
                                      _weekdayLabels[d],
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: d >= 5
                                            ? themeColor
                                            : cs.onSurface,
                                      ),
                                    ),
                                  ),
                                )),
                              ],
                            ),
                          ),
                          // 시간 행
                          ...hours.map((hour) {
                            return SizedBox(
                              height: rowH,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: _timeLabelWidth,
                                    child: Text(
                                      '${hour.toString().padLeft(2, '0')}시',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: cs.onSurface
                                              .withValues(alpha: 0.5)),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  ...List.generate(7, (d) {
                                    final selected =
                                        _selectedKeys.contains(_key(d, hour));
                                    return Expanded(
                                      child: Container(
                                        margin: EdgeInsets.symmetric(
                                            horizontal: 1.5,
                                            vertical: cellVMargin),
                                        height: cellH,
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? themeColor.withValues(alpha: 0.85)
                                              : (isDark
                                                  ? Colors.white
                                                      .withValues(alpha: 0.07)
                                                  : Colors.grey.shade100),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                            color: selected
                                                ? themeColor
                                                : (isDark
                                                    ? Colors.white
                                                        .withValues(alpha: 0.12)
                                                    : Colors.grey.shade200),
                                            width: selected ? 1.5 : 0.5,
                                          ),
                                        ),
                                        child: selected
                                            ? const Center(
                                                child: Icon(Icons.check,
                                                    size: 10,
                                                    color: Colors.white),
                                              )
                                            : null,
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
