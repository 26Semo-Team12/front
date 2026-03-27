// lib/features/home/views/home_screen_widgets.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    final viewModel = Provider.of<HomeViewModel>(context);
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

                  // time 태그 — 슬롯이 있으면 단일 태그, 없으면 추가 버튼
                  if (user.availableTimes.isNotEmpty)
                    UserProfileTag(
                      text: '모임 가능 시간',
                      color: kTagColors[TagType.time]!,
                      onDelete: () =>
                          viewModel.updateAvailableTimes([]),
                      // 탭하면 편집 다이얼로그
                      onTap: (ctx) => showDialog(
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
      title: _buildTypeSelector(),
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

  Widget _buildTypeSelector() {
    const types = [TagType.gender, TagType.ageRange, TagType.interest];
    const labels = ['성별', '연령', '관심사'];
    return Row(
      children: List.generate(types.length, (i) {
        final selected = _selectedType == types[i];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedType = types[i]),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFD6706D) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
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

// ─── FilterButton ────────────────────────────────────────────────────────────
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
      child: Container(
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

// ─── InvitationSection ───────────────────────────────────────────────────────
class InvitationSection extends StatelessWidget {
  const InvitationSection({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<HomeViewModel>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              FilterButton(
                label: '새 초대장',
                type: InvitationType.newInvitation,
                isSelected:
                    viewModel.activeFilter == InvitationType.newInvitation,
                onTap: () =>
                    viewModel.toggleFilter(InvitationType.newInvitation),
              ),
              const SizedBox(width: 8),
              FilterButton(
                label: '장기 모임',
                type: InvitationType.longTerm,
                isSelected: viewModel.activeFilter == InvitationType.longTerm,
                onTap: () => viewModel.toggleFilter(InvitationType.longTerm),
              ),
              const SizedBox(width: 8),
              FilterButton(
                label: '만료된 초대장',
                type: InvitationType.expired,
                isSelected: viewModel.activeFilter == InvitationType.expired,
                onTap: () => viewModel.toggleFilter(InvitationType.expired),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: viewModel.filteredInvitations.length,
          itemBuilder: (context, index) =>
              InvitationCard(invitation: viewModel.filteredInvitations[index]),
        ),
      ],
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
  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
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
    return Container(
      key: const ValueKey('loader'),
      color: Colors.black,
      height: 520,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RotationTransition(
              turns: _spinController,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.8),
                    width: 2.5,
                  ),
                ),
                child: const Icon(Icons.mail_outline,
                    color: Colors.white, size: 28),
              ),
            ),
            const SizedBox(height: 16),
            const Text('초대장을 열고 있습니다...',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
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

// ─── 하위 호환용 AddTagDialog alias ─────────────────────────────────────────
typedef AddTagDialog = TagEditDialog;
