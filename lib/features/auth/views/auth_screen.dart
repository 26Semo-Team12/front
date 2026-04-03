// lib/features/auth/views/auth_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_view_model.dart';
import '../../home/views/home_screen.dart';
import '../../profile/views/onboarding_screen.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(),
      child: const _AuthScreenContent(),
    );
  }
}

class _AuthScreenContent extends StatefulWidget {
  const _AuthScreenContent();

  @override
  State<_AuthScreenContent> createState() => _AuthScreenContentState();
}

class _AuthScreenContentState extends State<_AuthScreenContent> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onAuthSuccess(bool isSignup) {
    if (!mounted) return;
    if (isSignup) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        (route) => false,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),

              // ── 빨간색 "Venture" 스크립트 로고 ──
              const _VentureScriptLogo(),
              const SizedBox(height: 36),

              // ── 타이틀 "계정 만들기" ──
              const Text(
                '계정 만들기',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),

              // ── 설명 텍스트 ──
              const Text(
                '이 앱에 가입하려면 이메일을 입력하세요',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 32),

              // ── 이메일 입력란 ──
              TextFormField(
                controller: _emailController,
                readOnly: viewModel.isEmailSubmitted,
                keyboardType: TextInputType.emailAddress,
                onChanged: viewModel.updateEmail,
                style: TextStyle(
                  color: viewModel.isEmailSubmitted ? Colors.grey.shade600 : Colors.black87,
                ),
                decoration: InputDecoration(
                  fillColor: viewModel.isEmailSubmitted ? Colors.grey.shade100 : Colors.white,
                  filled: viewModel.isEmailSubmitted,
                  hintText: 'email@domain.com',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 15,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFFD6706D), width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.redAccent),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                  ),
                  errorText: viewModel.emailError,
                ),
              ),
              if (viewModel.isEmailSubmitted) ...[
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  onChanged: viewModel.updatePassword,
                  decoration: InputDecoration(
                    hintText: '비밀번호',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 15,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD6706D), width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.redAccent),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                    ),
                    errorText: viewModel.passwordError,
                  ),
                ),
                
                if (!viewModel.isExistingUser) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    onChanged: viewModel.updateConfirmPassword,
                    decoration: InputDecoration(
                      hintText: '비밀번호 확인',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 15,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFD6706D), width: 1.5),
                      ),
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 20),

              // ── '계속' 버튼 ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: viewModel.isLoading
                      ? null
                      : () =>
                          viewModel.onContinuePressed(_onAuthSuccess),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: viewModel.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          !viewModel.isEmailSubmitted
                              ? '계속'
                              : viewModel.isExistingUser
                                  ? '로그인'
                                  : '가입하기',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 28),

              // ── '또는' 구분선 ──
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '또는',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              const SizedBox(height: 20),

              // ── Google 로그인 버튼 ──
              _SocialLoginButton(
                onTap: (viewModel.isLoading || viewModel.isEmailSubmitted)
                    ? null
                    : () => viewModel.onGoogleSignIn(_onAuthSuccess),
                icon: _GoogleIcon(),
                label: 'Google 계정으로 계속하기',
              ),
              const SizedBox(height: 32),

              // ── 이용약관 안내 텍스트 ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      height: 1.6,
                    ),
                    children: [
                      const TextSpan(text: '계속을 클릭하면 당사의 '),
                      const TextSpan(
                        text: '서비스 이용 약관',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ' 및 '),
                      const TextSpan(
                        text: '개인정보 처리방침',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: '에\n동의하는 것으로 간주됩니다.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────
//  하위 위젯들
// ────────────────────────────────────────────

/// 빨간색 "Venture" 스크립트 로고 (logo_2.png 이미지 사용)
class _VentureScriptLogo extends StatelessWidget {
  const _VentureScriptLogo();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo_2.png',
      height: 60,
      fit: BoxFit.contain,
    );
  }
}

/// 소셜 로그인 버튼 (아웃라인 스타일)
class _SocialLoginButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget icon;
  final String label;

  const _SocialLoginButton({
    required this.onTap,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          foregroundColor: Colors.black87,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Google 'G' 아이콘 — 4색 G를 CustomPaint로 렌더링
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.18
      ..strokeCap = StrokeCap.butt;

    // 파란 (우측 아크) — 330° → 60°
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.72),
      -0.52, // ≈ -30°
      1.57, // ≈ 90°
      false,
      paint,
    );

    // 초록 (하단 아크)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.72),
      1.05, // ≈ 60°
      1.57,
      false,
      paint,
    );

    // 노랑 (좌하단 아크)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.72),
      2.62, // ≈ 150°
      1.05,
      false,
      paint,
    );

    // 빨강 (좌상단 아크)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.72),
      3.67, // ≈ 210°
      1.57,
      false,
      paint,
    );

    // 중앙 가로 바 (파란색)
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(w * 0.5, h * 0.4, w * 0.38, h * 0.2),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
