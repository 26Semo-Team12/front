// lib/features/home/views/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_view_model.dart';
import '../../auth/services/auth_service.dart';
import '../../gathering/services/invite_service.dart';
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
      create: (_) => HomeViewModel(AuthService(), InviteService())..init(),
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
      body: SafeArea(
        bottom: false,
        child: Stack(
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
        SliverAppBar(
          floating: true,
          snap: true,
          pinned: false,
          elevation: 0,
          toolbarHeight: kToolbarHeight,
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          title: Image.asset(
            'assets/images/logo_2.png',
            height: 32,
            fit: BoxFit.contain,
          ),
          centerTitle: false,
          actions: const [_AppBarActions()],
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
        // 하단 시스템 바 공간 확보
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ),
      ],
    );
  }
}

/// AppBar actions를 별도 위젯으로 분리 (SliverAppBar actions는 List<Widget> 필요)
class _AppBarActions extends StatelessWidget {
  const _AppBarActions();

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).colorScheme.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.notifications_none, color: iconColor),
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
          icon: Icon(Icons.settings, color: iconColor),
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

  static const double _rowHeight = 56.0;

  @override
  double get minExtent => _rowHeight;
  @override
  double get maxExtent => _rowHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
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
