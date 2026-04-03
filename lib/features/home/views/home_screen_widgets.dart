// lib/features/home/views/home_screen_widgets.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/models/tag_colors.dart';
import '../models/invitation.dart';
import '../viewmodels/home_view_model.dart';
import '../../gathering/views/gathering_detail_screen.dart';
import '../../profile/views/my_page_screen.dart';
import '../../profile/views/settings_screen.dart';

import '../../notification/views/notification_screen.dart';
import '../../notification/viewmodels/notification_view_model.dart';

// ─── 한글 음절 분해 기반 퍼지 매칭 ─────────────────────────────────────────
// 한글 유니코드 구조: 음절 = 0xAC00 + (초성 * 21 + 중성) * 28 + 종성
// 초성 19개, 중성 21개, 종성 28개(0=없음)

const List<String> _chosungList = [
  'ㄱ','ㄲ','ㄴ','ㄷ','ㄸ','ㄹ','ㅁ','ㅂ','ㅃ','ㅅ',
  'ㅆ','ㅇ','ㅈ','ㅉ','ㅊ','ㅋ','ㅌ','ㅍ','ㅎ',
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
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationScreen()),
                );
              },
            ),
            if (context.select<NotificationViewModel, bool>((vm) => vm.hasUnread))
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD6706D),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.black),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// ─── UserProfileCard (읽기 전용 요약 카드) ────────────────────────────────────
class UserProfileCard extends StatelessWidget {
  final UserProfile user;
  const UserProfileCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFFD6706D);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyPageScreen()),
      ),
      child: Container(
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
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(user.profileImageUrl),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${user.birthYear ?? '연도미상'} · ${user.gender?.displayName ?? '성별미상'}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white70),
              ],
            ),
            const SizedBox(height: 14),
            // ── 태그 요약 (읽기 전용) ──
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...user.locations.map((loc) => _ReadOnlyTag(text: loc.displayLabel, color: kTagColors[TagType.location]!)),
                if (user.availableTimes.isNotEmpty)
                  _ReadOnlyTag(text: '모임 가능 시간', color: kTagColors[TagType.time]!),
                if (user.gender != null)
                  _ReadOnlyTag(text: user.gender!.displayName, color: kTagColors[TagType.gender]!),
                if (user.ageRange?.isNotEmpty ?? false)
                  _ReadOnlyTag(text: user.ageRangeLabel, color: kTagColors[TagType.ageRange]!),
                ...user.interests.map((i) => _ReadOnlyTag(text: i, color: kTagColors[TagType.interest]!)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── _ReadOnlyTag (편집/삭제 없는 순수 표시용 태그) ─────────────────────────────
class _ReadOnlyTag extends StatelessWidget {
  final String text;
  final Color color;
  const _ReadOnlyTag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFD6706D)
              : (isDark ? const Color(0xFF2C2C2C) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFD6706D)
                : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.grey.shade300 : Colors.grey.shade600),
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
        return FadeSlideItem(
          key: ValueKey(inv.id),
          visible: visible,
          child: InvitationCard(invitation: inv),
        );
      }).toList(),
    );
  }
}

class FadeSlideItem extends StatefulWidget {
  final bool visible;
  final Widget child;
  const FadeSlideItem({super.key, required this.visible, required this.child});

  @override
  State<FadeSlideItem> createState() => _FadeSlideItemState();
}

class _FadeSlideItemState extends State<FadeSlideItem>
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
  void didUpdateWidget(FadeSlideItem old) {
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

/// 날짜 포맷 함수 (YYYY년 M월 D일 HH:mm)
String formatDateTime(DateTime dt) {
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  return '${dt.year}년 ${dt.month}월 ${dt.day}일 $hour:$minute';
}

class InvitationCard extends StatelessWidget {
  final Invitation invitation;
  const InvitationCard({super.key, required this.invitation});

  @override
  Widget build(BuildContext context) {
    Widget cardChild;

    switch (invitation.type) {
      case InvitationType.newInvitation:
        cardChild = _buildNewInvitation();
        break;
      case InvitationType.expired:
        cardChild = _buildExpiredInvitation();
        break;
      case InvitationType.longTerm:
        cardChild = _buildLongTermInvitation();
        break;
    }

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: cardChild,
      ),
    );
  }

  Widget _buildContentImage() {
    return invitation.imageUrl != null
        ? Image.network(
            invitation.imageUrl!,
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder(),
          )
        : _placeholder();
  }

  Widget _buildNewInvitation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD6706D), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD6706D).withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.5),
        child: Stack(
          alignment: Alignment.center,
          children: [
            _buildContentImage(),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiredInvitation() {
    return Opacity(
      opacity: 0.6,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            alignment: Alignment.center,
            children: [
               ColorFiltered(
                 colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                 child: _buildContentImage(),
               ),
               Positioned(
                 top: 12, right: 12,
                 child: Container(
                   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                   color: Colors.white70,
                   child: Text('만료됨', style: TextStyle(color: Colors.grey.shade800, fontSize: 10, fontWeight: FontWeight.bold)),
                 ),
               )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLongTermInvitation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            _buildContentImage(),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 12),
                    SizedBox(width: 4),
                    Text('D+12', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GatheringDetailScreen(invitation: invitation),
      ),
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



// ─── 하위 호환용 AddTagDialog alias ─────────────────────────────────────────
typedef AddTagDialog = TagEditDialog;

