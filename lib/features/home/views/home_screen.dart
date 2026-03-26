// lib/features/home/views/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_view_model.dart';
import 'home_screen_widgets.dart'; // 같은 폴더 내의 위젯 파일

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(),
      child: const _HomeScreenContent(),
    );
  }
}

class _HomeScreenContent extends StatelessWidget {
  const _HomeScreenContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<HomeViewModel>(context);
    final user = viewModel.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: CustomAppBar(),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserProfileCard(user: user),
                const SizedBox(height: 20),
                InvitationSection(
                  invitations: viewModel.invitations,
                  selectedTabIndex: viewModel.selectedTabIndex,
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          const BottomActionArea(),
        ],
      ),
    );
  }
}
