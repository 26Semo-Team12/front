// lib/features/home/views/home_screen_widgets.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'in_app_map_screen.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/models/tag_colors.dart';
import '../models/invitation.dart';
import '../viewmodels/home_view_model.dart';
import '../../settings/views/settings_screen.dart';
import 'location_picker.dart';
import 'time_picker.dart';

// ─── 한글 음절 분해 기반 퍼지 매칭 ─────────────────────────────────────────
// 한글 유니코드 구조: 음절 = 0xAC00 + (초성 * 21 + 중성) * 28 + 종성
// 초성 19개, 중성 21개, 종성 28개(0=없음)

const List<String> _chosungList = [
  'ㄱ','ㄲ','ㄴ','ㄷ','ㄸ','ㄹ','ㅁ','ㅂ','ㅃ','ㅅ',
  'ㅆ','ㅇ','ㅈ','ㅉ','ㅊ','ㅋ','ㅌ','ㅍ','ㅎ',
];
const List<String> _jungsungList = [
  'ㅏ','ㅐ','ㅑ','ㅒ','ㅓ','ㅔ','ㅕ','ㅖ','ㅗ','ㅘ',
  'ㅙ','ㅚ','ㅛ','ㅜ','ㅝ','ㅞ','ㅟ','ㅠ','ㅡ','ㅢ','ㅣ',
];
const List<String> _jongsungList = [
  '','ㄱ','ㄲ','ㄳ','ㄴ','ㄵ','ㄶ','ㄷ','ㄹ','ㄺ',
  'ㄻ','ㄼ','ㄽ','ㄾ','ㄿ','ㅀ','ㅁ','ㅂ','ㅄ','ㅅ',
  'ㅆ','ㅇ','ㅈ','ㅊ','ㅋ','ㅌ','ㅍ','ㅎ',
];

/// 한글 음절을 [초성, 중성, 종성] 인덱스로 분해. 비한글이면 null.
({int cho, int jung, int jong})? _decomposeHangul(String char) {
  final code = char.codeUnitAt(0);
  if (code < 0xAC00 || code > 0xD7A3) return null;
  final offset = code - 0xAC00;
  return (cho: offset ~/ 588, jung: (offset % 588) ~/ 28, jong: offset % 28);
}

/// 문자가 한글 자음(ㄱ~ㅎ)인지 확인
bool _isJamo(String char) {
  final code = char.codeUnitAt(0);
  return code >= 0x3131 && code <= 0x314E;
}

/// 자음 문자를 초성 인덱스로 변환. 없으면 -1.
int _jamoToChosungIndex(String jamo) => _chosungList.indexOf(jamo);

/// 쿼리 글자 하나가 단어의 글자 하나에 "접두 매칭"되는지 판단.
/// - 쿼리 글자가 완성 음절이면 → 단어 글자와 완전 일치
/// - 쿼리 글자가 자음(초성)이면 → 단어 글자의 초성과 일치
/// - 쿼리의 마지막 글자(미완성 가능)는 단어 글자가 쿼리 글자로 시작하면 OK
///   즉 단어 글자의 초성+중성이 쿼리 글자의 초성+중성과 일치하면 매칭
///   (종성은 아직 입력 중일 수 있으므로 무시)
bool _charMatches(String qChar, String wChar, {required bool isLast}) {
  // 쿼리 글자가 자음(초성)인 경우
  if (_isJamo(qChar)) {
    final qIdx = _jamoToChosungIndex(qChar);
    if (qIdx < 0) return qChar == wChar;
    final wd = _decomposeHangul(wChar);
    if (wd == null) return false;
    return wd.cho == qIdx;
  }

  // 쿼리 글자가 완성 한글인 경우
  final qd = _decomposeHangul(qChar);
  if (qd == null) {
    // 비한글(영문 등): 단순 일치
    return qChar.toLowerCase() == wChar.toLowerCase();
  }
  final wd = _decomposeHangul(wChar);
  if (wd == null) return false;

  // 초성+중성 일치 여부
  if (qd.cho != wd.cho || qd.jung != wd.jung) return false;

  // 마지막 글자: 종성은 아직 입력 중일 수 있으므로
  //   - 쿼리 종성이 없으면 → 단어 종성 무관하게 매칭 (미완성 입력 허용)
  //   - 쿼리 종성이 있으면 → 단어 종성과 일치해야 함
  if (isLast) {
    return qd.jong == 0 || qd.jong == wd.jong;
  }
  return qd.jong == wd.jong;
}

/// 쿼리가 단어의 어느 위치에서든 접두 매칭되는지 확인.
/// 단어의 각 시작 위치에서 쿼리 전체가 순서대로 매칭되면 true.
bool _matchesQuery(String word, String query) {
  if (query.isEmpty) return true;
  final qChars = query.characters.toList();
  final wChars = word.characters.toList();
  if (qChars.length > wChars.length) return false;

  // 단어의 각 시작 위치에서 시도
  for (var start = 0; start <= wChars.length - qChars.length; start++) {
    bool ok = true;
    for (var i = 0; i < qChars.length; i++) {
      final isLast = i == qChars.length - 1;
      if (!_charMatches(qChars[i], wChars[start + i], isLast: isLast)) {
        ok = false;
        break;
      }
    }
    if (ok) return true;
  }
  return false;
}

// ─── 관심사 프리셋 ───────────────────────────────────────────────────────────
const List<String> kInterestPresets = [
  '등산', '독서', '요리', '여행', '사진', '음악', '영화', '게임', '운동', '카페',
  '드라이브', '캠핑', '낚시', '자전거', '수영', '테니스', '골프', '볼링', '당구',
  '보드게임', '그림', '공예', '뜨개질', '원예', '반려동물', '봉사', '언어교환',
  '스터디', '재테크', '명상', '요가', '필라테스', '댄스', '노래', '악기',
];

// ─── CustomAppBar ────────────────────────────────────────────────────────────
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leading: const Padding(
        padding: EdgeInsets.only(left: 16),
        child: Icon(Icons.pets, color: Colors.black),
      ),
      title: const Text(
        '앱 이름',
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.black),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

// ─── UserProfileCard ─────────────────────────────────────────────────────────
class UserProfileCard extends StatelessWidget {
  final UserProfile user;
  const UserProfileCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // context.read: 구독 없이 한 번만 읽음 → 필터 변경 시 이 위젯 리빌드 없음
    final viewModel = context.read<HomeViewModel>();
    const cardColor = Color(0xFFD6706D);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 프로필 헤더 ──
          Row(
            children: [
              // 프로필 사진 + 편집 버튼
              GestureDetector(
                onTap: () => _showProfileEditDialog(context, viewModel),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundImage: NetworkImage(user.profileImageUrl),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, size: 13, color: Color(0xFFD6706D)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showProfileEditDialog(context, viewModel),
                      child: const Icon(Icons.edit, color: Colors.white, size: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ── 태그 영역 ──
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  // location 태그들
                  ...user.locations.map((loc) => UserProfileTag(
                        text: loc.displayLabel,
                        color: kTagColors[TagType.location]!,
                        onDelete: () =>
                            viewModel.removeTag(loc.displayLabel, TagType.location),
                        onTap: (ctx) => showDialog(
                          context: ctx,
                          builder: (_) => LocationPicker(
                            onSelected: (newLoc) {
                              viewModel.removeTag(loc.displayLabel, TagType.location);
                              viewModel.addLocation(newLoc);
                            },
                          ),
                        ),
                      )),
                  // location 추가 버튼 (3개 미만일 때만)
                  if (user.locations.length < 3)
                    _LabeledAddButton(
                      label: '모임 위치 추가',
                      onTap: (ctx) => showDialog(
                        context: ctx,
                        builder: (_) => LocationPicker(
                          onSelected: (loc) => viewModel.addLocation(loc),
                        ),
                      ),
                    ),

                  // time 태그 — 슬롯이 있으면 단일 태그(편집 아이콘), 없으면 추가 버튼
                  if (user.availableTimes.isNotEmpty)
                    _TimeTag(
                      onEdit: (ctx) => showDialog(
                        context: ctx,
                        builder: (_) => TimePicker(
                          initialSlots: user.availableTimes,
                          onConfirm: (slots) =>
                              viewModel.updateAvailableTimes(slots),
                        ),
                      ),
                    )
                  else
                    _LabeledAddButton(
                      label: '모임 가능 시간 추가',
                      onTap: (ctx) => showDialog(
                        context: ctx,
                        builder: (_) => TimePicker(
                          initialSlots: const [],
                          onConfirm: (slots) =>
                              viewModel.updateAvailableTimes(slots),
                        ),
                      ),
                    ),

                  // gender 태그
                  if (user.gender?.isNotEmpty ?? false)
                    UserProfileTag(
                      text: user.gender!,
                      color: kTagColors[TagType.gender]!,
                      onDelete: () =>
                          viewModel.removeTag(user.gender!, TagType.gender),
                      onTap: (ctx) => showDialog(
                        context: ctx,
                        builder: (_) => TagEditDialog(
                          viewModel: viewModel,
                          initialType: TagType.gender,
                        ),
                      ),
                    ),
                  if (!(user.gender?.isNotEmpty ?? false))
                    _LabeledAddButton(
                      label: '성별 추가',
                      onTap: (ctx) => showDialog(
                        context: ctx,
                        builder: (_) => TagEditDialog(
                          viewModel: viewModel,
                          initialType: TagType.gender,
                        ),
                      ),
                    ),

                  // ageRange 태그
                  if (user.ageRange?.isNotEmpty ?? false)
                    UserProfileTag(
                      text: user.ageRange!,
                      color: kTagColors[TagType.ageRange]!,
                      onDelete: () =>
                          viewModel.removeTag(user.ageRange!, TagType.ageRange),
                      onTap: (ctx) => showDialog(
                        context: ctx,
                        builder: (_) => TagEditDialog(
                          viewModel: viewModel,
                          initialType: TagType.ageRange,
                        ),
                      ),
                    ),
                  if (!(user.ageRange?.isNotEmpty ?? false))
                    _LabeledAddButton(
                      label: '연령 추가',
                      onTap: (ctx) => showDialog(
                        context: ctx,
                        builder: (_) => TagEditDialog(
                          viewModel: viewModel,
                          initialType: TagType.ageRange,
                        ),
                      ),
                    ),

                  // interest 태그들
                  ...user.interests.map((interest) => UserProfileTag(
                        text: interest,
                        color: kTagColors[TagType.interest]!,
                        onDelete: () =>
                            viewModel.removeTag(interest, TagType.interest),
                      )),
                  _LabeledAddButton(
                    label: '관심사 추가',
                    onTap: (ctx) => showDialog(
                      context: ctx,
                      builder: (_) => TagEditDialog(
                        viewModel: viewModel,
                        initialType: TagType.interest,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileEditDialog(BuildContext context, HomeViewModel viewModel) {
    showDialog(
      context: context,
      builder: (_) => _ProfileEditDialog(viewModel: viewModel),
    );
  }
}

// ─── _LabeledAddButton ───────────────────────────────────────────────────────
class _LabeledAddButton extends StatelessWidget {
  final String label;
  final void Function(BuildContext) onTap;
  const _LabeledAddButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 12, color: Colors.white),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ─── _TimeTag (편집 아이콘, 삭제 없음) ──────────────────────────────────────
class _TimeTag extends StatelessWidget {
  final void Function(BuildContext) onEdit;
  const _TimeTag({required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onEdit(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: kTagColors[TagType.time]!,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('모임 가능 시간',
                style: TextStyle(color: Colors.white, fontSize: 12)),
            SizedBox(width: 4),
            Icon(Icons.edit, size: 12, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

// ─── UserProfileTag ──────────────────────────────────────────────────────────
class UserProfileTag extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onDelete;
  final void Function(BuildContext)? onTap; // 탭 시 편집 (시간 태그용)

  const UserProfileTag({
    super.key,
    required this.text,
    this.color = const Color(0xFFE05C5C),
    required this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap != null ? () => onTap!(context) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── _ProfileEditDialog (빈 팝업) ────────────────────────────────────────────
class _ProfileEditDialog extends StatelessWidget {
  final HomeViewModel viewModel;
  const _ProfileEditDialog({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('프로필 편집'),
      content: const SizedBox(
        height: 80,
        child: Center(
          child: Text('편집 기능 준비 중입니다.', style: TextStyle(color: Colors.grey)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}

// ─── TagEditDialog ───────────────────────────────────────────────────────────
/// 성별/연령/관심사 선택 다이얼로그
class TagEditDialog extends StatefulWidget {
  final HomeViewModel viewModel;
  final TagType initialType;

  const TagEditDialog({
    super.key,
    required this.viewModel,
    this.initialType = TagType.interest,
  });

  @override
  State<TagEditDialog> createState() => _TagEditDialogState();
}

class _TagEditDialogState extends State<TagEditDialog> {
  late TagType _selectedType;

  // 성별
  String? _selectedGender;

  // 연령
  int? _selectedAge;

  // 관심사 검색
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredInterests = kInterestPresets;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredInterests = q.isEmpty
          ? kInterestPresets
          : kInterestPresets.where((s) => _matchesQuery(s, q)).toList();
    });
  }

  Future<void> _submit(String value) async {
    await widget.viewModel.addTag(value, _selectedType);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      title: Text(
        _selectedType == TagType.gender
            ? '성별 선택'
            : _selectedType == TagType.ageRange
                ? '연령 선택'
                : '관심사 선택',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _buildContent(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
      ],
    );
  }

  Widget _buildContent() {
    switch (_selectedType) {
      case TagType.gender:
        return _buildGenderPicker();
      case TagType.ageRange:
        return _buildAgePicker();
      case TagType.interest:
        return _buildInterestSearch();
      default:
        return const SizedBox.shrink();
    }
  }

  // 성별 선택
  Widget _buildGenderPicker() {
    const genders = ['남성', '여성'];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        Row(
          children: genders.map((g) {
            final selected = _selectedGender == g;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedGender = g);
                  _submit(g);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFE8A838)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFE8A838)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      g,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: selected ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // 연령 범위 선택
  Widget _buildAgePicker() {
    const ranges = [
      '10대 초반', '10대 후반',
      '20대 초반', '20대 후반',
      '30대 초반', '30대 후반',
      '40대 초반', '40대 후반',
      '50대 초반', '50대 후반',
      '60대 이상',
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 240),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: ranges.length,
            itemBuilder: (ctx, i) {
              final r = ranges[i];
              return ListTile(
                dense: true,
                title: Text(r),
                onTap: () => _submit(r),
              );
            },
          ),
        ),
      ],
    );
  }

  // 관심사 실시간 검색
  Widget _buildInterestSearch() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '관심사 검색...',
            prefixIcon: const Icon(Icons.search, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: _filteredInterests.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('검색 결과 없음', style: TextStyle(color: Colors.grey)),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredInterests.length,
                  itemBuilder: (ctx, i) {
                    final item = _filteredInterests[i];
                    return ListTile(
                      dense: true,
                      title: Text(item),
                      onTap: () => _submit(item),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ─── FilterButton (멀티 셀렉트) ──────────────────────────────────────────────
class FilterButton extends StatelessWidget {
  final String label;
  final InvitationType type;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterButton({
    super.key,
    required this.label,
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD6706D) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(color: Colors.grey.shade400, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ─── InvitationSection (기존 호환용 — 사용 안 함) ───────────────────────────
// home_screen.dart에서 InvitationFilterRow + InvitationListOnly로 분리 사용

// ─── InvitationFilterRow ─────────────────────────────────────────────────────
class InvitationFilterRow extends StatelessWidget {
  const InvitationFilterRow({super.key});

  @override
  Widget build(BuildContext context) {
    // activeFilters Set만 구독 — UserProfile 변경 시 리빌드 없음
    final filters = context.select<HomeViewModel, Set<InvitationType>>(
      (vm) => vm.activeFilters,
    );
    final viewModel = context.read<HomeViewModel>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          FilterButton(
            label: '새 초대장',
            type: InvitationType.newInvitation,
            isSelected: filters.contains(InvitationType.newInvitation),
            onTap: () => viewModel.toggleFilter(InvitationType.newInvitation),
          ),
          const SizedBox(width: 8),
          FilterButton(
            label: '장기 모임',
            type: InvitationType.longTerm,
            isSelected: filters.contains(InvitationType.longTerm),
            onTap: () => viewModel.toggleFilter(InvitationType.longTerm),
          ),
          const SizedBox(width: 8),
          FilterButton(
            label: '만료된 초대장',
            type: InvitationType.expired,
            isSelected: filters.contains(InvitationType.expired),
            onTap: () => viewModel.toggleFilter(InvitationType.expired),
          ),
        ],
      ),
    );
  }
}

// ─── InvitationListOnly ──────────────────────────────────────────────────────
class InvitationListOnly extends StatelessWidget {
  const InvitationListOnly({super.key});

  @override
  Widget build(BuildContext context) {
    // filteredInvitations만 구독 — UserProfile 변경 시 리빌드 없음
    final invitations = context.select<HomeViewModel, List<Invitation>>(
      (vm) => vm.filteredInvitations,
    );
    return _AnimatedInvitationList(invitations: invitations);
  }
}

// ─── InvitationSection (멀티 셀렉트 + 페이드 애니메이션) ─────────────────────
class InvitationSection extends StatelessWidget {
  const InvitationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InvitationFilterRow(),
        SizedBox(height: 10),
        InvitationListOnly(),
      ],
    );
  }
}

class _AnimatedInvitationList extends StatefulWidget {
  final List<Invitation> invitations;
  const _AnimatedInvitationList({required this.invitations});

  @override
  State<_AnimatedInvitationList> createState() => _AnimatedInvitationListState();
}

class _AnimatedInvitationListState extends State<_AnimatedInvitationList> {
  // 이전 목록을 기억해 페이드 처리
  late List<Invitation> _all;
  late Set<String> _visibleIds;

  @override
  void initState() {
    super.initState();
    _all = List.from(widget.invitations);
    _visibleIds = widget.invitations.map((e) => e.id).toSet();
  }

  @override
  void didUpdateWidget(_AnimatedInvitationList old) {
    super.didUpdateWidget(old);
    final newIds = widget.invitations.map((e) => e.id).toSet();
    // 새로 추가된 항목을 _all에 병합
    for (final inv in widget.invitations) {
      if (!_all.any((e) => e.id == inv.id)) _all.add(inv);
    }
    setState(() => _visibleIds = newIds);
  }

  @override
  Widget build(BuildContext context) {
    // 정렬: type 순서 유지
    _all.sort((a, b) => a.type.index.compareTo(b.type.index));
    return Column(
      children: _all.map((inv) {
        final visible = _visibleIds.contains(inv.id);
        return _FadeSlideItem(
          key: ValueKey(inv.id),
          visible: visible,
          child: InvitationCard(invitation: inv),
        );
      }).toList(),
    );
  }
}

class _FadeSlideItem extends StatefulWidget {
  final bool visible;
  final Widget child;
  const _FadeSlideItem({super.key, required this.visible, required this.child});

  @override
  State<_FadeSlideItem> createState() => _FadeSlideItemState();
}

class _FadeSlideItemState extends State<_FadeSlideItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: widget.visible ? 1.0 : 0.0,
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(_FadeSlideItem old) {
    super.didUpdateWidget(old);
    if (widget.visible != old.visible) {
      widget.visible ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        // 높이를 0→full로 클리핑. 스크롤 위치에 영향 없음.
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: _ctrl.value,
            child: Opacity(opacity: _opacity.value, child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}

// ─── InvitationCard (이미지만, 탭 시 로딩 → 상세 팝업) ─────────────────────
class InvitationCard extends StatelessWidget {
  final Invitation invitation;
  const InvitationCard({super.key, required this.invitation});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: invitation.imageUrl != null
            ? Image.network(
                invitation.imageUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => _InvitationDetailDialog(invitation: invitation),
    );
  }

  Widget _placeholder() => Container(
        height: 160,
        width: double.infinity,
        color: Colors.grey.shade300,
        child: const Center(
          child: Text(
            '예시 초대장 이미지',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      );
}

// ─── 초대장 상세 팝업 ────────────────────────────────────────────────────────
class _InvitationDetailDialog extends StatefulWidget {
  final Invitation invitation;
  const _InvitationDetailDialog({required this.invitation});

  @override
  State<_InvitationDetailDialog> createState() =>
      _InvitationDetailDialogState();
}

class _InvitationDetailDialogState extends State<_InvitationDetailDialog>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  late final AnimationController _ctrl;

  // ① 뚜껑 열림: 0.00 ~ 0.48 구간, X축 회전 0 → -π
  late final Animation<double> _lidAngle;
  // ② 편지지 슬라이드: 0.52 ~ 0.92 구간
  late final Animation<double> _paperSlide;
  // ③ 편지지 페이드: 0.52 ~ 0.66 구간
  late final Animation<double> _paperFade;
  // ④ 텍스트 페이드: 0.90 ~ 1.0 구간
  late final Animation<double> _textFade;

  // ── 봉투 치수 ──────────────────────────────────────────────
  // 봉투 몸통 (앞면/뒷면 공통)
  static const double _envW  = 280.0;
  static const double _envH  = 190.0;
  // 뚜껑 삼각형 높이 (봉투 너비의 절반 → 45° 각도)
  static const double _lidH  = 140.0;
  // 편지지 치수
  static const double _paperW = 248.0;
  static const double _paperH = 200.0;
  // 편지지가 봉투 위로 올라오는 최대 거리
  static const double _rise  = 130.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _lidAngle = Tween<double>(begin: 0.0, end: -3.14159).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.00, 0.48, curve: Curves.easeInOut),
      ),
    );
    _paperSlide = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.52, 0.92, curve: Curves.easeInOut),
      ),
    );
    _paperFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.52, 0.66, curve: Curves.easeIn),
      ),
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.90, 1.0, curve: Curves.easeIn),
      ),
    );

    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _ctrl.forward();
    });

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) setState(() => _loading = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _loading ? _buildLoader() : _buildDetail(),
        ),
      ),
    );
  }

  Widget _buildLoader() {
    // 전체 Stack 높이: 뚜껑 + 봉투 몸통 + 편지지 올라올 공간
    const double stackH = _lidH + _envH + _rise;
    // 봉투 앞면이 가리는 영역: top=_lidH, height=_envH
    // 편지지 시작 top: slide=0 → 봉투 내부 바닥 근처, slide=1 → 봉투 위로 _rise만큼
    // 편지지 top(slide=0) = _lidH + _envH - 20  (봉투 바닥 근처, 앞면에 완전히 가려짐)
    // 편지지 top(slide=1) = _lidH - _rise        (봉투 위로 올라옴)
    const double paperTopHidden = _lidH + _envH - 20.0;
    const double paperTopShown  = _lidH - _rise;

    return Container(
      key: const ValueKey('loader'),
      color: const Color(0xFF0F0F1A),
      height: 520,
      child: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final paperTop = paperTopHidden +
                (_paperSlide.value * (paperTopShown - paperTopHidden));

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: _envW,
                  height: stackH,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // ── Layer 1: 봉투 뒷면 배경 ──────────────────────────
                      Positioned(
                        left: 0, top: _lidH,
                        child: CustomPaint(
                          size: const Size(_envW, _envH),
                          painter: _EnvelopeBackPainter(),
                        ),
                      ),

                      // ── Layer 2: 편지지 (봉투 앞면 뒤에 위치) ────────────
                      // 봉투 앞면 영역(_lidH ~ _lidH+_envH)에서는 앞면이 가려줌
                      Positioned(
                        left: (_envW - _paperW) / 2,
                        top: paperTop,
                        child: Opacity(
                          opacity: _paperFade.value,
                          child: _buildPaper(),
                        ),
                      ),

                      // ── Layer 3: 봉투 앞면 (왁스 씰 포함) ────────────────
                      // 편지지가 이 레이어를 절대 뚫고 나올 수 없음
                      Positioned(
                        left: 0, top: _lidH,
                        child: CustomPaint(
                          size: const Size(_envW, _envH),
                          painter: _EnvelopeFrontPainter(),
                        ),
                      ),

                      // ── Layer 4: 봉투 뚜껑 (앞면 상단에서 뒤로 회전) ─────
                      // 뚜껑 하단 = 봉투 상단(_lidH)에 정확히 정렬
                      Positioned(
                        left: 0, top: _lidH,
                        child: Transform(
                          alignment: Alignment.bottomCenter,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0007)
                            ..rotateX(_lidAngle.value),
                          child: CustomPaint(
                            size: const Size(_envW, _lidH),
                            painter: _EnvelopeLidPainter(
                              openProgress: (_ctrl.value / 0.48).clamp(0.0, 1.0),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Opacity(
                  opacity: _textFade.value,
                  child: const Text(
                    '초대장을 확인하고 있습니다...',
                    style: TextStyle(
                      color: Color(0xFFD4C5B0),
                      fontSize: 14,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 완전히 빈 흰색 편지지
  Widget _buildPaper() {
    return Container(
      width: _paperW,
      height: _paperH,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  Widget _buildDetail() {
    final inv = widget.invitation;
    return Stack(
      key: const ValueKey('detail'),
      children: [
        // 배경 이미지
        SizedBox(
          height: 600,
          width: double.infinity,
          child: inv.imageUrl != null
              ? Image.network(inv.imageUrl!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _debugPlaceholder())
              : _debugPlaceholder(),
        ),
        // 어두운 오버레이
        Positioned.fill(
          child: Container(color: Colors.black.withValues(alpha: 0.35)),
        ),
        // 닫기 버튼
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        // 지도 버튼 (디버그용)
        Positioned(
          top: 8,
          left: 8,
          child: _MapButton(location: inv.location),
        ),
        // 하단 정보 (준비 중)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.75),
                  Colors.transparent,
                ],
              ),
            ),
            child: const Text(
              '상세 정보 준비 중입니다.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
  Widget _debugPlaceholder() => Container(
        color: Colors.grey.shade800,
        child: const Center(
          child: Text(
            '예시 초대장 이미지',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ),
      );
}

// ─── 봉투 뒷면 Painter (Layer 1) ────────────────────────────────────────────
class _EnvelopeBackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 외부 그림자
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(3, 6, size.width, size.height),
        const Radius.circular(6),
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(6),
    );

    // 아이보리 배경
    canvas.drawRRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFFF8F4EE), const Color(0xFFEDE8E0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // 테두리
    canvas.drawRRect(
      rect,
      Paint()
        ..color = const Color(0xFFD8D0C4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── 봉투 앞면 Painter (Layer 3) — 왁스 씰 포함 ─────────────────────────────
class _EnvelopeFrontPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(6),
    );

    // 앞면 아이보리 (뒷면과 동일 톤)
    canvas.drawRRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFFF5F1EB), const Color(0xFFEAE4DA)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // 접힘선 — 하단 V (봉투 앞면 특유의 마름모 접힘)
    final foldPaint = Paint()
      ..color = const Color(0xFFCCC4B8).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final cx = size.width / 2;
    final cy = size.height * 0.44;

    canvas.drawPath(
      Path()
        ..moveTo(0, size.height)
        ..lineTo(cx, cy)
        ..lineTo(size.width, size.height),
      foldPaint,
    );
    canvas.drawPath(Path()..moveTo(0, 0)..lineTo(cx, cy), foldPaint);
    canvas.drawPath(Path()..moveTo(size.width, 0)..lineTo(cx, cy), foldPaint);

    // 테두리
    canvas.drawRRect(
      rect,
      Paint()
        ..color = const Color(0xFFD0C8BC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // ── 왁스 씰 (중앙 하단 접힘선 교차점) ──────────────────────────────────
    final sealCx = size.width / 2;
    final sealCy = cy + 8; // 접힘선 교차점 바로 아래
    const sealR = 22.0;

    // 씰 외부 그림자
    canvas.drawCircle(
      Offset(sealCx, sealCy + 3),
      sealR,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // 씰 본체 — 진한 크림슨 레드
    canvas.drawCircle(
      Offset(sealCx, sealCy),
      sealR,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          radius: 1.0,
          colors: [
            const Color(0xFFC0394B), // 하이라이트
            const Color(0xFF8B1A2A), // 기본 크림슨
            const Color(0xFF6B1020), // 어두운 가장자리
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(
          Rect.fromCircle(center: Offset(sealCx, sealCy), radius: sealR),
        ),
    );

    // 씰 테두리 (약간 밝은 테두리로 입체감)
    canvas.drawCircle(
      Offset(sealCx, sealCy),
      sealR,
      Paint()
        ..color = const Color(0xFFB03040).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // 씰 내부 하이라이트 (광택)
    canvas.drawCircle(
      Offset(sealCx - 7, sealCy - 7),
      6.0,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // 씰 내부 텍스처 — 작은 동심원 (왁스 질감)
    final texturePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(Offset(sealCx, sealCy), sealR * 0.65, texturePaint);
    canvas.drawCircle(Offset(sealCx, sealCy), sealR * 0.35, texturePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── 봉투 뚜껑 Painter (Layer 4) ────────────────────────────────────────────
class _EnvelopeLidPainter extends CustomPainter {
  final double openProgress; // 0.0 = 닫힘, 1.0 = 완전히 열림

  _EnvelopeLidPainter({required this.openProgress});

  @override
  void paint(Canvas canvas, Size size) {
    // 열릴수록 약간 밝아지는 아이보리
    final baseColor = Color.lerp(
      const Color(0xFFEDE8E0),
      const Color(0xFFF8F4EE),
      openProgress,
    )!;

    // 삼각형 경로: 좌하 → 꼭대기 → 우하 (뚜껑 하단이 봉투 상단과 정렬)
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();

    // 뚜껑 채우기 (그라디언트)
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(baseColor, const Color(0xFFD8D0C4), 0.2)!,
            baseColor,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // 뚜껑 테두리
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFCCC4B8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(covariant _EnvelopeLidPainter old) =>
      old.openProgress != openProgress;
}

// ─── 하위 호환용 AddTagDialog alias ─────────────────────────────────────────
typedef AddTagDialog = TagEditDialog;

// ─── 지도 버튼 (앱 내 지도) ──────────────────────────────────────────────────
class _MapButton extends StatelessWidget {
  final String location;
  const _MapButton({required this.location});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: const Icon(Icons.map_outlined, color: Colors.white),
        tooltip: '지도 열기',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InAppMapScreen(locationName: location),
          ),
        ),
      ),
    );
  }
}
