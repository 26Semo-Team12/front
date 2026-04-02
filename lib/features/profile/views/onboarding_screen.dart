import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/onboarding_view_model.dart';
import '../../home/views/home_screen.dart';
import '../../../core/models/enums.dart';

const kMockInterests = [
  '코딩', '등산', '독서', '밴드', '게임', 
  '맛집탐방', '영화', '음악', '운동', '여행'
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

  void _onSuccess() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
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
                  _Step2View(viewModel: viewModel, onComplete: () => viewModel.submit(_onSuccess)),
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
            children: GenderType.values.map((type) {
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
          DropdownButtonFormField<String>(
            decoration: _inputDecoration('지역을 선택하세요'),
            items: ['서울', '경기', '인천', '부산', '대구', '광주', '대전', '울산', '세종', '강원', '충북', '충남', '전북', '전남', '경북', '경남', '제주']
                .map((region) => DropdownMenuItem(
                      value: region,
                      child: Text(region),
                    ))
                .toList(),
            onChanged: (val) {
              if (val != null) viewModel.setRegion(val);
            },
          ),
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

class _Step2View extends StatelessWidget {
  final OnboardingViewModel viewModel;
  final VoidCallback onComplete;

  const _Step2View({required this.viewModel, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '관심사를\n선택해주세요',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            '최소 1개 이상 선택해주세요.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 32),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: kMockInterests.map((interest) {
              final isSelected = viewModel.selectedInterests.contains(interest);
              return FilterChip(
                label: Text(interest),
                selected: isSelected,
                selectedColor: const Color(0xFFD6706D),
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: Colors.grey.shade100,
                onSelected: (_) => viewModel.toggleInterest(interest),
              );
            }).toList(),
          ),
          const SizedBox(height: 48),

          if (viewModel.step2Error != null) ...[
            Text(
              viewModel.step2Error!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
            const SizedBox(height: 16),
          ],

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: viewModel.isLoading ? null : onComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD6706D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: viewModel.isLoading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text('시작하기', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
