import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../viewmodels/onboarding_view_model.dart';
import '../../home/views/home_screen.dart';
import '../../home/views/location_picker.dart';
import '../../../core/models/enums.dart';

const kMockInterests = [
  // 문화/예술
  '미술 감상', '영화', '연극', '뮤지컬', '독서', '글쓰기', '필사',
  '악기', '콘서트', '페스티벌', '노래방', '레코드 감상',
  // 운동/액티비티
  '러닝', '등산', '클라이밍', '헬스', '배드민턴', '테니스',
  '자전거', '수영', '댄스', '산책',
  // 취미/라이프
  '보드게임', '게임', '애니메이션', '사진 촬영', '영상 편집',
  '요리', '카페 투어', '맛집 탐방', '술', '여행', '캠핑',
  '반려동물', '다이어리', '향수',
  // 자기계발
  '코딩', '외국어 회화', '재테크', '디자인', '창업',
];

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingViewModel(),
      child: const _OnboardingScreenContent(),
    );
  }
}

class _OnboardingScreenContent extends StatefulWidget {
  const _OnboardingScreenContent();

  @override
  State<_OnboardingScreenContent> createState() => _OnboardingScreenContentState();
}

class _OnboardingScreenContentState extends State<_OnboardingScreenContent> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OnboardingViewModel>();

    // PageView를 ViewModel의 currentStep에 맞춰 이동
    if (_pageController.hasClients) {
      if (_pageController.page?.round() != viewModel.currentStep) {
        _pageController.animateToPage(
          viewModel.currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: viewModel.currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: viewModel.previousStep,
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 프로그레스 바 영역
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6706D),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: viewModel.currentStep == 1
                            ? const Color(0xFFD6706D)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Step1View(viewModel: viewModel),
                  const _Step2View(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step1View extends StatelessWidget {
  final OnboardingViewModel viewModel;
  const _Step1View({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '기본 정보를\n입력해주세요',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),

          // 이름 필드
          const Text('이름', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            onChanged: viewModel.setName,
            decoration: _inputDecoration('이름을 입력하세요'),
          ),
          const SizedBox(height: 24),

          // 출생 연도 필드
          const Text('출생 연도', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            keyboardType: TextInputType.number,
            onChanged: (val) => viewModel.setBirthYear(int.tryParse(val)),
            decoration: _inputDecoration('예: 1995'),
          ),
          const SizedBox(height: 24),

          // 성별 필드
          const Text('성별', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [GenderType.male, GenderType.female].map((type) {
              final isSelected = viewModel.gender == type;
              return ChoiceChip(
                label: Text(type.displayName),
                selected: isSelected,
                selectedColor: const Color(0xFFD6706D).withValues(alpha: 0.2),
                backgroundColor: Colors.grey.shade100,
                labelStyle: TextStyle(
                  color: isSelected ? const Color(0xFFD6706D) : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (_) => viewModel.setGender(type),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // 지역 필드
          const Text('주 활동 지역', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _LocationField(viewModel: viewModel),
          const SizedBox(height: 32),

          if (viewModel.step1Error != null) ...[
            Text(
              viewModel.step1Error!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
            const SizedBox(height: 16),
          ],

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: viewModel.nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('다음', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD6706D), width: 1.5),
      ),
    );
  }
}

class _Step2View extends StatefulWidget {
  const _Step2View();

  @override
  State<_Step2View> createState() => _Step2ViewState();
}

class _Step2ViewState extends State<_Step2View> {
  static const _rowCount = 4;

  late List<List<String>> _rows;
  late List<int> _nextDirs;
  // 전체 풀을 순환하기 위한 셔플된 목록과 커서
  late List<String> _pool;
  late int _poolCursor;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 초기 배치: 전체 목록을 섞어서 4행에 배분
    _pool = List<String>.from(kMockInterests)..shuffle();
    _poolCursor = 0;
    _rows = List.generate(_rowCount, (r) => _nextItems([]));
    _nextDirs = [1, -1, 1, -1];
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _rotate());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// 풀에서 최대 8개를 뽑아 반환 (화면 너비에 따라 실제 표시 개수는 _RowChips에서 결정)
  List<String> _nextItems(List<String> exclude) {
    const maxFetch = 8;
    final selected = context.read<OnboardingViewModel>().selectedInterests;
    final skip = {...exclude, ...selected};
    final result = <String>[];
    int attempts = 0;
    while (result.length < maxFetch && attempts < _pool.length * 2) {
      final item = _pool[_poolCursor % _pool.length];
      _poolCursor++;
      if (_poolCursor >= _pool.length) {
        _pool.shuffle();
        _poolCursor = 0;
      }
      if (!skip.contains(item)) result.add(item);
      attempts++;
    }
    if (result.length < maxFetch) {
      final fill = kMockInterests
          .where((s) => !selected.contains(s) && !result.contains(s))
          .take(maxFetch - result.length);
      result.addAll(fill);
    }
    return result;
  }

  void _rotate() {
    if (!mounted) return;
    final selected = context.read<OnboardingViewModel>().selectedInterests;

    // 교체 가능한 행: 선택된 항목이 하나도 없는 행
    final candidates = [
      for (int r = 0; r < _rowCount; r++)
        if (_rows[r].every((item) => !selected.contains(item))) r
    ]..shuffle();

    if (candidates.isEmpty) return;

    final row = candidates.first;
    // 현재 화면에 표시 중인 모든 항목을 exclude로 전달
    final displayed = [for (final r in _rows) ...r];
    final newItems = _nextItems(displayed);
    final dir = _nextDirs[row];

    setState(() {
      _rows[row] = newItems;
      _nextDirs[row] = -dir;
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OnboardingViewModel>();
    final selected = viewModel.selectedInterests;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '관심사를 선택해주세요',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            '최소 1개 이상 선택해주세요.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          for (int r = 0; r < _rowCount; r++)
            _InterestRow(
              rowIndex: r,
              items: _rows[r],
              selected: selected,
              slideDir: -_nextDirs[r],
              onTap: context.read<OnboardingViewModel>().toggleInterest,
            ),

          const Spacer(),

          if (viewModel.step2Error != null) ...[
            Text(
              viewModel.step2Error!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
            const SizedBox(height: 8),
          ],

          const Text(
            '나중에 프로필에서 언제든지 수정할 수 있어요.',
            style: TextStyle(fontSize: 13, color: Color(0xFFD6706D)),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: viewModel.isLoading
                  ? null
                  : () => viewModel.submit(
                        () {
                          if (!context.mounted) return;
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const HomeScreen()),
                            (route) => false,
                          );
                        },
                      ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD6706D),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: viewModel.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text('시작하기',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── 한 행: AnimatedSwitcher로 슬라이드 인/아웃 연결 ─────────────────────────
class _InterestRow extends StatelessWidget {
  final int rowIndex;
  final List<String> items;
  final Set<String> selected;
  final int slideDir;
  final ValueChanged<String> onTap;

  const _InterestRow({
    required this.rowIndex,
    required this.items,
    required this.selected,
    required this.slideDir,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final contentKey = ValueKey(items.join(','));

    return SizedBox(
      height: 48,
      child: ClipRect(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 550),
          // in/out 모두 linear → 동일한 속도로 움직임
          switchInCurve: Curves.linear,
          switchOutCurve: Curves.linear,
          transitionBuilder: (child, animation) {
            final isIncoming = child.key == contentKey;

            if (isIncoming) {
              // 들어오는 위젯: animation 0→1, 왼쪽밖 → 제자리
              return SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(-slideDir.toDouble(), 0),
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              );
            } else {
              // 나가는 위젯: animation 1→0, 제자리 → 오른쪽밖
              // Tween(begin=오른쪽밖, end=Offset.zero).animate(1→0) = Offset.zero → 오른쪽밖
              return SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(slideDir.toDouble(), 0),
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              );
            }
          },
          child: _RowChips(
            key: contentKey,
            items: items,
            selected: selected,
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}

class _RowChips extends StatelessWidget {
  final List<String> items;
  final Set<String> selected;
  final ValueChanged<String> onTap;

  const _RowChips({
    super.key,
    required this.items,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 한 줄에 들어갈 수 있는 칩만 표시
        final chips = _fitChips(context, constraints.maxWidth);
        return Align(
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: chips,
          ),
        );      },
    );
  }

  List<Widget> _fitChips(BuildContext context, double maxWidth) {
    const chipHPad = 12.0;   // FilterChip 내부 좌우 패딩
    const chipSpacing = 8.0; // 칩 사이 간격
    const fontSize = 14.0;
    // FilterChip은 label 외에 내부 Material 패딩이 추가되므로 여유값 포함
    const chipExtraWidth = 16.0;

    final style = TextStyle(fontSize: fontSize);
    final result = <Widget>[];
    double usedWidth = 0;

    for (final item in items) {
      // 텍스트 너비 측정
      final tp = TextPainter(
        text: TextSpan(text: item, style: style),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();
      final chipWidth = tp.width + chipHPad * 2 + chipExtraWidth;
      final needed = result.isEmpty ? chipWidth : chipWidth + chipSpacing;

      if (usedWidth + needed > maxWidth) break;

      if (result.isNotEmpty) {
        result.add(const SizedBox(width: chipSpacing));
        usedWidth += chipSpacing;
      }

      final isSelected = selected.contains(item);
      result.add(FilterChip(
        label: Text(item, style: const TextStyle(fontSize: fontSize)),
        selected: isSelected,
        selectedColor: const Color(0xFFD6706D),
        showCheckmark: false,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: Colors.grey.shade100,
        onSelected: (_) => onTap(item),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ));
      usedWidth += chipWidth;
    }
    return result;
  }
}

// ─── 지역 선택 필드 ───────────────────────────────────────────────────────────
class _LocationField extends StatelessWidget {
  final OnboardingViewModel viewModel;
  const _LocationField({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final selected = viewModel.location;
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => LocationPicker(
          onSelected: (loc) => viewModel.setRegion(loc),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected != null
                ? const Color(0xFFD6706D)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selected != null ? selected.displayLabel : '지역을 선택하세요',
                style: TextStyle(
                  fontSize: 15,
                  color: selected != null
                      ? Colors.black87
                      : Colors.grey.shade400,
                ),
              ),
            ),
            Icon(Icons.chevron_right,
                color: selected != null
                    ? const Color(0xFFD6706D)
                    : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
