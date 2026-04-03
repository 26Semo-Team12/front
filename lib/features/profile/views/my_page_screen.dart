import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/models/tag_colors.dart';
import '../../../core/services/mock_api_service.dart';
import '../../home/viewmodels/home_view_model.dart'; // TagType
import '../../home/views/location_picker.dart';
import '../viewmodels/profile_view_model.dart';
import 'settings_screen.dart';

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
      create: (_) => ProfileViewModel(MockApiService.instance),
      child: const _MyPageContent(),
    );
  }
}

class _MyPageContent extends StatelessWidget {
  const _MyPageContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileViewModel>();
    final user = viewModel.currentUser;

    if (viewModel.isLoading || user == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Color(0xFFD6706D))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('마이페이지', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // ── 상단 프로필 영역 ──
            _buildProfileHeader(user),
            const SizedBox(height: 32),
            // ── 정보 섹션들 ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    title: '주 활동 지역',
                    onEdit: () {
                      showDialog(
                        context: context,
                        builder: (_) => LocationPicker(
                          onSelected: (loc) => viewModel.addLocation(loc),
                        ),
                      );
                    },
                    child: _buildLocationChips(user, viewModel),
                  ),
                  const SizedBox(height: 28),
                  _buildSection(
                    title: '나의 관심사',
                    onEdit: () => _showInterestDialog(context, viewModel),
                    child: _buildInterestChips(user, viewModel),
                  ),
                  const SizedBox(height: 28),
                  _buildSection(
                    title: '모임 가능 시간',
                    onEdit: () => _showTimeSlotPicker(context, user, viewModel),
                    child: _buildTimeChips(user),
                  ),
                  const SizedBox(height: 28),
                  _buildSection(
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
    );
  }

  // ── 상단 프로필 헤더 ──
  Widget _buildProfileHeader(UserProfile user) {
    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundImage: NetworkImage(
            user.profileImageUrl.isNotEmpty
                ? user.profileImageUrl
                : 'https://via.placeholder.com/150',
          ),
          backgroundColor: Colors.grey.shade200,
        ),
        const SizedBox(height: 16),
        Text(
          user.name,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFD6706D),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, size: 14, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                '신뢰도 ${user.reputationScore}점',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${user.birthYear ?? '연도미상'} · ${user.gender?.displayName ?? '성별미상'}',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  // ── 섹션 빌더 (헤더 Row + 데이터 영역) ──
  Widget _buildSection({
    required String title,
    required VoidCallback? onEdit,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
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

  // ── 활동 지역 Chip ──
  Widget _buildLocationChips(UserProfile user, ProfileViewModel viewModel) {
    if (user.locations.isEmpty) {
      return Text('등록된 활동 지역이 없습니다.', style: TextStyle(color: Colors.grey.shade400, fontSize: 14));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: user.locations.map((loc) {
        return Chip(
          label: Text(loc.displayLabel, style: const TextStyle(color: Colors.white, fontSize: 13)),
          backgroundColor: kTagColors[TagType.location] ?? const Color(0xFF4A90D9),
          deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white70),
          onDeleted: () => viewModel.removeTag(loc.displayLabel, TagType.location),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          side: BorderSide.none,
        );
      }).toList(),
    );
  }

  // ── 관심사 Chip ──
  Widget _buildInterestChips(UserProfile user, ProfileViewModel viewModel) {
    if (user.interests.isEmpty) {
      return Text('등록된 관심사가 없습니다.', style: TextStyle(color: Colors.grey.shade400, fontSize: 14));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: user.interests.map((interest) {
        return Chip(
          label: Text(interest, style: const TextStyle(color: Colors.white, fontSize: 13)),
          backgroundColor: kTagColors[TagType.interest] ?? const Color(0xFFE05C5C),
          deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white70),
          onDeleted: () => viewModel.removeTag(interest, TagType.interest),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          side: BorderSide.none,
        );
      }).toList(),
    );
  }

  // ── 모임 가능 시간 (요일별 범위 요약) ──
  Widget _buildTimeChips(UserProfile user) {
    if (user.availableTimes.isEmpty) {
      return Text('등록된 모임 가능 시간이 없습니다.', style: TextStyle(color: Colors.grey.shade400, fontSize: 14));
    }

    // 요일별로 그룹핑 후, 연속 시간을 범위로 합침
    final byDay = <int, List<int>>{};
    for (final slot in user.availableTimes) {
      byDay.putIfAbsent(slot.weekday, () => []).add(slot.hourIndex);
    }

    const dayLabels = ['월', '화', '수', '목', '금', '토', '일'];
    const timeColor = Color(0xFF7B68EE);

    final sortedDays = byDay.keys.toList()..sort();
    final rangeWidgets = <Widget>[];

    for (final day in sortedDays) {
      final hours = byDay[day]!..sort();
      // 연속 시간을 범위로 합침
      final ranges = <String>[];
      int start = hours[0];
      int end = hours[0];
      for (int i = 1; i < hours.length; i++) {
        if (hours[i] == end + 1) {
          end = hours[i];
        } else {
          ranges.add(_formatRange(start, end));
          start = hours[i];
          end = hours[i];
        }
      }
      ranges.add(_formatRange(start, end));

      rangeWidgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: day >= 5 ? timeColor : timeColor.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  dayLabels[day],
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ranges.map((r) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: timeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: timeColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(r, style: const TextStyle(color: Color(0xFF5B4FC7), fontSize: 13)),
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rangeWidgets,
    );
  }

  String _formatRange(int start, int end) {
    final s = '${start.toString().padLeft(2, '0')}:00';
    if (start == end) return s;
    final e = '${(end + 1).toString().padLeft(2, '0')}:00';
    return '$s – $e';
  }

  // ── 기본 정보 Chip (읽기 전용) ──
  Widget _buildInfoChips(UserProfile user) {
    final chips = <Widget>[];
    if (user.gender != null) {
      chips.add(Chip(
        label: Text(user.gender!.displayName, style: const TextStyle(color: Colors.white, fontSize: 13)),
        backgroundColor: kTagColors[TagType.gender] ?? const Color(0xFFE8A838),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ));
    }
    if (user.ageRange?.isNotEmpty ?? false) {
      chips.add(Chip(
        label: Text(user.ageRange!, style: const TextStyle(color: Colors.white, fontSize: 13)),
        backgroundColor: kTagColors[TagType.ageRange] ?? const Color(0xFF50C878),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ));
    }
    if (chips.isEmpty) {
      return Text('등록된 정보가 없습니다.', style: TextStyle(color: Colors.grey.shade400, fontSize: 14));
    }
    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  // ── 관심사 선택 다이얼로그 ──
  void _showInterestDialog(BuildContext context, ProfileViewModel viewModel) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('관심사 추가', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 350),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: kInterestPresets.length,
              itemBuilder: (_, index) {
                final item = kInterestPresets[index];
                return ListTile(
                  title: Text(item),
                  trailing: const Icon(Icons.add_circle_outline, color: Color(0xFFD6706D), size: 20),
                  onTap: () {
                    viewModel.addTag(item, TagType.interest);
                    Navigator.pop(ctx);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('닫기', style: TextStyle(color: Colors.black54)),
            ),
          ],
        );
      },
    );
  }

  // ── 모임 가능 시간 선택 바텀시트 ──
  void _showTimeSlotPicker(BuildContext context, UserProfile user, ProfileViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TimeSlotPickerSheet(
        initialSlots: List<TimeSlot>.from(user.availableTimes),
        onSave: (slots) => viewModel.updateAvailableTimes(slots),
      ),
    );
  }
}

// ─── 시간대 선택 바텀시트 위젯 ──────────────────────────────────────────────

class _TimeSlotPickerSheet extends StatefulWidget {
  final List<TimeSlot> initialSlots;
  final ValueChanged<List<TimeSlot>> onSave;

  const _TimeSlotPickerSheet({
    required this.initialSlots,
    required this.onSave,
  });

  @override
  State<_TimeSlotPickerSheet> createState() => _TimeSlotPickerSheetState();
}

class _TimeSlotPickerSheetState extends State<_TimeSlotPickerSheet> {
  late Set<String> _selectedKeys;

  static const _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];
  static const _startHour = 6;
  static const _endHour = 23;
  static const _cellHeight = 34.0;
  static const _cellVMargin = 1.5;
  static const _rowHeight = _cellHeight + _cellVMargin * 2;
  static const _timeLabelWidth = 44.0;

  // ── 드래그 상태 ──
  bool? _isDragSelecting; // true=선택 모드, false=해제 모드, null=드래그 중 아님
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

  List<TimeSlot> _buildSlots() {
    return _selectedKeys.map((k) {
      final parts = k.split('-');
      return TimeSlot(weekday: int.parse(parts[0]), hourIndex: int.parse(parts[1]));
    }).toList();
  }

  /// 글로벌 좌표로부터 그리드 셀 (weekday, hour)을 계산
  ({int weekday, int hour})? _hitTest(Offset globalPos) {
    final rb = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (rb == null) return null;

    final local = rb.globalToLocal(globalPos);
    if (local.dx < _timeLabelWidth || local.dx > rb.size.width) return null;

    // 요일 헤더 행(~24px) + SizedBox(6) = 약 30px 오프셋
    const headerOffset = 30.0;
    final y = local.dy - headerOffset;
    if (y < 0) return null;

    final rowIdx = y ~/ _rowHeight;
    final hour = _startHour + rowIdx;
    if (hour > _endHour) return null;

    final cellAreaWidth = rb.size.width - _timeLabelWidth;
    final col = ((local.dx - _timeLabelWidth) / (cellAreaWidth / 7)).floor();
    if (col < 0 || col > 6) return null;

    return (weekday: col, hour: hour);
  }

  void _onPointerDown(PointerDownEvent e) {
    final cell = _hitTest(e.position);
    if (cell == null) return;

    final k = _key(cell.weekday, cell.hour);
    // 처음 터치한 셀의 상태로 모드 결정: 이미 선택돼 있으면 해제 모드, 아니면 선택 모드
    _isDragSelecting = !_selectedKeys.contains(k);
    _draggedKeys.clear();
    _draggedKeys.add(k);
    _applyDrag(k);
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (_isDragSelecting == null) return;
    final cell = _hitTest(e.position);
    if (cell == null) return;

    final k = _key(cell.weekday, cell.hour);
    if (_draggedKeys.contains(k)) return; // 이미 처리한 셀
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
    final hours = List.generate(_endHour - _startHour + 1, (i) => _startHour + i);
    final selectedCount = _selectedKeys.length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── 핸들 ──
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // ── 헤더 ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '모임 가능 시간 선택',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$selectedCount개 시간대 선택됨',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _selectedKeys.clear()),
                      child: Text('초기화', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      onPressed: () {
                        widget.onSave(_buildSlots());
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      child: const Text('저장', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.touch_app, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(
                  '탭 또는 드래그하여 시간을 선택하세요',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── 시간표 그리드 (드래그 지원) ──
          Expanded(
            child: Listener(
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  key: _gridKey,
                  children: [
                    // 요일 헤더
                    Row(
                      children: [
                        const SizedBox(width: _timeLabelWidth),
                        ...List.generate(7, (d) => Expanded(
                          child: Center(
                            child: Text(
                              _weekdayLabels[d],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: d >= 5 ? themeColor : Colors.black87,
                              ),
                            ),
                          ),
                        )),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // 시간 행
                    ...hours.map((hour) {
                      return SizedBox(
                        height: _rowHeight,
                        child: Row(
                          children: [
                            SizedBox(
                              width: _timeLabelWidth,
                              child: Text(
                                '${hour.toString().padLeft(2, '0')}시',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            ...List.generate(7, (d) {
                              final selected = _selectedKeys.contains(_key(d, hour));
                              return Expanded(
                                child: Container(
                                  margin: const EdgeInsets.all(_cellVMargin),
                                  height: _cellHeight,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? themeColor.withValues(alpha: 0.85)
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: selected
                                          ? themeColor
                                          : Colors.grey.shade200,
                                      width: selected ? 1.5 : 0.5,
                                    ),
                                  ),
                                  child: selected
                                      ? const Center(
                                          child: Icon(Icons.check, size: 14, color: Colors.white),
                                        )
                                      : null,
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

