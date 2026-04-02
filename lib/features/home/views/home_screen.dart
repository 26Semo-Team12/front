// lib/features/home/views/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/mock_api_service.dart';
import '../viewmodels/home_view_model.dart';
import '../../../core/models/user_profile.dart';
import 'home_screen_widgets.dart';
import 'ai_mc_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(MockApiService.instance)..init(),
      child: const _HomeScreenContent(),
    );
  }
}

class _HomeScreenContent extends StatefulWidget {
  const _HomeScreenContent();

  @override
  State<_HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<_HomeScreenContent> {
  bool _showAiMcButton = false;

  @override
  Widget build(BuildContext context) {
    // currentUser가 null인지 아닌지만 감시 — 필터 변경 시 이 위젯은 리빌드되지 않음
    final isLoaded = context.select<HomeViewModel, bool>(
      (vm) => vm.currentUser != null,
    );

    if (!isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: const CustomAppBar(),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // UserProfileCard: UserProfile 데이터가 바뀔 때만 리빌드
              Selector<HomeViewModel, UserProfile>(
                selector: (_, vm) => vm.currentUser!,
                builder: (_, user, __) => UserProfileCard(user: user),
              ),
              const SizedBox(height: 20),
              // 필터 버튼: activeFilters가 바뀔 때만 리빌드
              const InvitationFilterRow(),
              const SizedBox(height: 10),
              // 초대장 목록: filteredInvitations가 바뀔 때만 리빌드
              const Expanded(child: _InvitationScrollArea()),
            ],
          ),
          if (_showAiMcButton)
            Positioned(
              left: 8, right: 8, bottom: 20,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AiMcScreen()),
                ),
                child: Container(
                  height: 68,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B68EE), Color(0xFF4A3FBF)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7B68EE).withValues(alpha: 0.45),
                        blurRadius: 16,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.smart_toy_outlined, color: Colors.white, size: 26),
                      SizedBox(width: 12),
                      Text(
                        'AI MC 시작하기',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: _showAiMcButton
            ? const Color(0xFF7B68EE)
            : Colors.grey.shade400,
        tooltip: 'AI MC 버튼 토글 (디버그)',
        onPressed: () => setState(() => _showAiMcButton = !_showAiMcButton),
        child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 20),
      ),
    );
  }
}

/// 초대장 목록 스크롤 영역 — filteredInvitations가 바뀔 때만 리빌드
class _InvitationScrollArea extends StatelessWidget {
  const _InvitationScrollArea();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Column(
        children: [
          InvitationListOnly(),
          SizedBox(height: 40),
        ],
      ),
    );
  }
}
