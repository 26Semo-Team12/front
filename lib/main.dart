import 'package:flutter/material.dart';
import 'features/home/views/home_screen.dart';
import 'features/home/views/invitation_opening_screen.dart';

void main() {
  runApp(const VentureApp());
}

class VentureApp extends StatelessWidget {
  const VentureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Venture',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD6706D)),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      // 앱 시작 시 오프닝 영상 → 완료 후 HomeScreen으로 전환
      home: const _AppEntry(),
    );
  }
}

/// 앱 최초 진입점: 오프닝 영상을 재생하고 끝나면 HomeScreen으로 이동
class _AppEntry extends StatelessWidget {
  const _AppEntry();

  @override
  Widget build(BuildContext context) {
    return InvitationOpeningScreen(
      onAnimationComplete: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      },
    );
  }
}
