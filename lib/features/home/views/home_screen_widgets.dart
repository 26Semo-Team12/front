// lib/features/home/views/home_screen_widgets.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/user_profile.dart'; // core에서 가져오기
import '../models/invitation.dart'; // home에서 가져오기
import '../viewmodels/home_view_model.dart'; // home 뷰모델 가져오기

// 1. CustomAppBar
class CustomAppBar extends AppBar {
  CustomAppBar({super.key})
    : super(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Icon(Icons.pets, color: Colors.black), // 임시 로고 아이콘
        ),
        title: const Text(
          '앱 이름',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      );
}

// 2. UserProfileCard
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
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 35,
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
                    const SizedBox(height: 5),
                    GestureDetector(
                      onTap: () => viewModel.editProfile(context),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 35,
            child: PageView(
              onPageChanged: viewModel.changePage,
              children: [_buildInterestsPage(user), _buildDetailsPage(user)],
            ),
          ),
          const SizedBox(height: 15),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                2,
                (index) =>
                    _buildPageIndicator(index, viewModel.currentPageIndex),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsPage(UserProfile user) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: user.interests
            .map((interest) => UserProfileTag(text: '$interest X'))
            .toList(),
      ),
    );
  }

  Widget _buildDetailsPage(UserProfile user) {
    return Row(
      children: [
        UserProfileTag(text: '${user.ageRange} X'),
        UserProfileTag(text: user.gender),
      ],
    );
  }

  Widget _buildPageIndicator(int index, int currentPageIndex) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: index == currentPageIndex
            ? Colors.white
            : Colors.white.withOpacity(0.5),
      ),
    );
  }
}

class UserProfileTag extends StatelessWidget {
  final String text;
  const UserProfileTag({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

// 3. InvitationSection
class InvitationSection extends StatelessWidget {
  final List<Invitation> invitations;
  final int selectedTabIndex;
  const InvitationSection({
    super.key,
    required this.invitations,
    required this.selectedTabIndex,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<HomeViewModel>(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '모임 및 초대장',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.map_outlined, color: Colors.black),
                onPressed: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        DefaultTabController(
          length: 3,
          initialIndex: selectedTabIndex,
          child: Column(
            children: [
              TabBar(
                tabs: const [
                  Tab(text: '정기 모임'),
                  Tab(text: '새로운 초대장'),
                  Tab(text: '만료된 초대장'),
                ],
                labelColor: const Color(0xFFD6706D),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFFD6706D),
                onTap: viewModel.changeTab,
              ),
              const SizedBox(height: 15),
              _buildInvitationList(invitations, selectedTabIndex),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInvitationList(List<Invitation> invitations, int tabIndex) {
    List<Invitation> filteredInvitations = invitations;
    if (tabIndex == 0)
      filteredInvitations = invitations.where((i) => i.isRegular).toList();
    else if (tabIndex == 1)
      filteredInvitations = invitations.where((i) => i.isNew).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredInvitations.length,
      itemBuilder: (context, index) {
        return InvitationCard(invitation: filteredInvitations[index]);
      },
    );
  }
}

// 4. InvitationCard
class InvitationCard extends StatelessWidget {
  final Invitation invitation;
  const InvitationCard({super.key, required this.invitation});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 120,
      child: Stack(
        children: [
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width - 32, 120),
            painter: EnvelopePainter(),
          ),
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width - 32, 50),
            painter: EnvelopeFlapPainter(),
          ),
          Positioned(
            left: 20,
            bottom: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  invitation.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                if (invitation.isRegular)
                  const Text(
                    '정기 모임',
                    style: TextStyle(color: Colors.blue, fontSize: 10),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EnvelopePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 50)
      ..lineTo(size.width, 50)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class EnvelopeFlapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 5. BottomActionArea
class BottomActionArea extends StatelessWidget {
  const BottomActionArea({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD6706D),
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: const Text(
            '새로운 모험 시작하기!',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
