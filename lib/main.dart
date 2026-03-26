import 'package:flutter/material.dart';
import 'features/home/views/home_screen.dart'; // 분리해 둔 홈 화면 import

void main() {
  runApp(const VentureApp());
}

class VentureApp extends StatelessWidget {
  const VentureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Venture', // 서비스명
      debugShowCheckedModeBanner: false, // 화면 우측 상단 'DEBUG' 띠 제거
      theme: ThemeData(
        // Figma 디자인의 메인 컬러(#D6706D)를 테마의 시드 컬러로 지정
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD6706D)),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white, // 전체 배경색을 흰색으로 깔끔하게 설정
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black, // 앱바 글자색
          elevation: 0, // 앱바 그림자 제거
        ),
      ),
      // 기본 카운터 앱 대신 우리가 만든 HomeScreen을 진입점으로 설정!
      home: const HomeScreen(),
    );
  }
}
