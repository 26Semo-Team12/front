// lib/features/home/views/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/mock_api_service.dart';
import '../viewmodels/home_view_model.dart';
import '../../../core/models/user_profile.dart';
import '../models/invitation.dart';
import 'home_screen_widgets.dart';
import 'ai_mc_screen.dart';
import '../../notification/views/notification_screen.dart';
import '../../notification/viewmodels/notification_view_model.dart';
import '../../profile/views/settings_screen.dart';

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
      body: Stack(
        children: [
          _HomeScrollView(),
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

/// CustomScrollView 기반 홈 스크롤 뷰
/// - SliverAppBar(앱 이름+설정): 스크롤 시 위로 사라짐, 올리면 다시 나타남 (floating)
/// - SliverToBoxAdapter(프로필 카드): 스크롤 시 위로 사라짐, 끝까지 올려야 나타남
/// - SliverPersistentHeader(필터 버튼): 스크롤 시 상단에 고정
/// - SliverList(초대장 목록): 일반 스크롤
class _HomeScrollView extends StatelessWidget {
  const _HomeScrollView();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // 앱 이름+설정 — floating: 스크롤 내리면 사라지고, 올리면 바로 나타남
        const SliverAppBar(
          floating: true,
          snap: true,
          pinned: false,
          elevation: 0,
          backgroundColor: Colors.white,
          leading: Padding(
            padding: EdgeInsets.only(left: 16),
            child: Icon(Icons.pets, color: Colors.black),
          ),
          title: Text(
            '앱 이름',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [_AppBarActions()],
        ),
        // 프로필 카드 — 일반 sliver: 끝까지 스크롤해야 나타남
        SliverToBoxAdapter(
          child: Selector<HomeViewModel, UserProfile>(
            selector: (_, vm) => vm.currentUser!,
            builder: (_, user, __) => UserProfileCard(user: user),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        // 필터 버튼 — pinned: 항상 상단에 고정
        const SliverPersistentHeader(
          pinned: true,
          delegate: _FilterRowDelegate(),
        ),
        // 초대장 목록
        const _InvitationSliver(),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}

/// AppBar actions를 별도 위젯으로 분리 (SliverAppBar actions는 List<Widget> 필요)
class _AppBarActions extends StatelessWidget {
  const _AppBarActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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

/// 필터 버튼 행을 상단에 고정시키는 SliverPersistentHeaderDelegate
class _FilterRowDelegate extends SliverPersistentHeaderDelegate {
  const _FilterRowDelegate();

  static const double _height = 56.0;

  @override
  double get minExtent => _height;
  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      alignment: Alignment.centerLeft,
      child: const InvitationFilterRow(),
    );
  }

  @override
  bool shouldRebuild(_FilterRowDelegate old) => false;
}

/// 초대장 목록을 Sliver로 렌더링
class _InvitationSliver extends StatelessWidget {
  const _InvitationSliver();

  @override
  Widget build(BuildContext context) {
    final invitations = context.select<HomeViewModel, List<Invitation>>(
      (vm) => vm.filteredInvitations,
    );
    return _AnimatedInvitationSliver(invitations: invitations);
  }
}

class _AnimatedInvitationSliver extends StatefulWidget {
  final List<Invitation> invitations;
  const _AnimatedInvitationSliver({required this.invitations});

  @override
  State<_AnimatedInvitationSliver> createState() => _AnimatedInvitationSliverState();
}

class _AnimatedInvitationSliverState extends State<_AnimatedInvitationSliver> {
  late List<Invitation> _all;
  late Set<String> _visibleIds;

  @override
  void initState() {
    super.initState();
    _all = List.from(widget.invitations);
    _visibleIds = widget.invitations.map((e) => e.id).toSet();
  }

  @override
  void didUpdateWidget(_AnimatedInvitationSliver old) {
    super.didUpdateWidget(old);
    final newIds = widget.invitations.map((e) => e.id).toSet();
    for (final inv in widget.invitations) {
      if (!_all.any((e) => e.id == inv.id)) _all.add(inv);
    }
    setState(() => _visibleIds = newIds);
  }

  @override
  Widget build(BuildContext context) {
    _all.sort((a, b) => a.type.index.compareTo(b.type.index));
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final inv = _all[index];
          final visible = _visibleIds.contains(inv.id);
          return FadeSlideItem(
            key: ValueKey(inv.id),
            visible: visible,
            child: InvitationCard(invitation: inv),
          );
        },
        childCount: _all.length,
      ),
    );
  }
}
