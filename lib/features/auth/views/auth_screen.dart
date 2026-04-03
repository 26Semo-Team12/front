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
  final _confirmController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _onAuthSuccess(bool isSignup) {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => isSignup ? const OnboardingScreen() : const HomeScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                const _Logo(),
                const SizedBox(height: 48),

                // 이메일 단계
                _EmailStep(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  vm: vm,
                ),

                // 비밀번호 / 회원가입 단계 (애니메이션으로 등장)
                AnimatedSize(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  child: vm.step == AuthStep.email
                      ? const SizedBox.shrink()
                      : _PasswordStep(
                          passwordController: _passwordController,
                          confirmController: _confirmController,
                          passwordFocus: _passwordFocus,
                          confirmFocus: _confirmFocus,
                          vm: vm,
                          onSuccess: _onAuthSuccess,
                        ),
                ),

                const SizedBox(height: 20),

                // 메인 버튼
                _MainButton(vm: vm, onSuccess: _onAuthSuccess),

                const SizedBox(height: 32),

                // 이용약관
                _TermsText(),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 로고 ──────────────────────────────────────────────────────────────────────
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/images/logo_2.png', height: 60, fit: BoxFit.contain);
  }
}

// ── 이메일 입력 단계 ──────────────────────────────────────────────────────────
class _EmailStep extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final AuthViewModel vm;

  const _EmailStep({
    required this.controller,
    required this.focusNode,
    required this.vm,
  });

  @override
  Widget build(BuildContext context) {
    final submitted = vm.step != AuthStep.email;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            submitted
                ? (vm.step == AuthStep.password ? '다시 만나서 반가워요 👋' : '처음 오셨군요!')
                : '시작하기',
            key: ValueKey(vm.step),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            submitted
                ? (vm.step == AuthStep.password ? '비밀번호를 입력해 주세요.' : '비밀번호를 설정해 주세요.')
                : '이메일을 입력해 주세요.',
            key: ValueKey('sub_${vm.step}'),
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ),
        const SizedBox(height: 24),
        _InputField(
          controller: controller,
          focusNode: focusNode,
          hint: 'email@domain.com',
          readOnly: submitted,
          keyboardType: TextInputType.emailAddress,
          onChanged: vm.updateEmail,
          errorText: vm.emailError,
          suffix: submitted
              ? GestureDetector(
                  onTap: () {
                    vm.goBackToEmail();
                    controller.clear();
                  },
                  child: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFFD6706D)),
                )
              : null,
        ),
      ],
    );
  }
}

// ── 비밀번호 단계 (AnimatedSize로 펼쳐짐) ─────────────────────────────────────
class _PasswordStep extends StatefulWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final FocusNode passwordFocus;
  final FocusNode confirmFocus;
  final AuthViewModel vm;
  final void Function(bool) onSuccess;

  const _PasswordStep({
    required this.passwordController,
    required this.confirmController,
    required this.passwordFocus,
    required this.confirmFocus,
    required this.vm,
    required this.onSuccess,
  });

  @override
  State<_PasswordStep> createState() => _PasswordStepState();
}

class _PasswordStepState extends State<_PasswordStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
    // 자동 포커스
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.passwordFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSignup = widget.vm.step == AuthStep.signup;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Column(
          children: [
            const SizedBox(height: 16),
            _InputField(
              controller: widget.passwordController,
              focusNode: widget.passwordFocus,
              hint: '비밀번호',
              obscureText: widget.vm.obscurePassword,
              onChanged: widget.vm.updatePassword,
              errorText: widget.vm.passwordError,
              suffix: GestureDetector(
                onTap: widget.vm.toggleObscurePassword,
                child: Icon(
                  widget.vm.obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: Colors.grey,
                ),
              ),
              onSubmitted: isSignup
                  ? (_) => widget.confirmFocus.requestFocus()
                  : (_) => widget.vm.submitPassword(widget.onSuccess),
            ),
            if (isSignup) ...[
              const SizedBox(height: 14),
              _InputField(
                controller: widget.confirmController,
                focusNode: widget.confirmFocus,
                hint: '비밀번호 확인',
                obscureText: widget.vm.obscureConfirm,
                onChanged: widget.vm.updateConfirmPassword,
                suffix: GestureDetector(
                  onTap: widget.vm.toggleObscureConfirm,
                  child: Icon(
                    widget.vm.obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: Colors.grey,
                  ),
                ),
                onSubmitted: (_) => widget.vm.submitPassword(widget.onSuccess),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 메인 버튼 ─────────────────────────────────────────────────────────────────
class _MainButton extends StatelessWidget {
  final AuthViewModel vm;
  final void Function(bool) onSuccess;

  const _MainButton({required this.vm, required this.onSuccess});

  @override
  Widget build(BuildContext context) {
    final label = switch (vm.step) {
      AuthStep.email => '계속',
      AuthStep.password => '로그인',
      AuthStep.signup => '가입하기',
    };

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: ElevatedButton(
          key: ValueKey(vm.step),
          onPressed: vm.isLoading
              ? null
              : () {
                  if (vm.step == AuthStep.email) {
                    vm.submitEmail();
                  } else {
                    vm.submitPassword(onSuccess);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD6706D),
            disabledBackgroundColor: Colors.grey.shade300,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: vm.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Text(label,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

// ── 공통 입력 필드 ────────────────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final bool readOnly;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? errorText;
  final Widget? suffix;

  const _InputField({
    required this.controller,
    this.focusNode,
    required this.hint,
    this.readOnly = false,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      readOnly: readOnly,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      style: TextStyle(
        color: readOnly
            ? Colors.grey.shade500
            : Theme.of(context).colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
        filled: true,
        fillColor: readOnly
            ? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100)
            : (isDark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade50),
        suffixIcon: suffix != null
            ? Padding(padding: const EdgeInsets.only(right: 12), child: suffix)
            : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isDark ? Colors.white12 : Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD6706D), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        errorText: errorText,
      ),
    );
  }
}

// ── 이용약관 ──────────────────────────────────────────────────────────────────
class _TermsText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text.rich(
        TextSpan(
          style: TextStyle(
              fontSize: 12, color: Colors.grey.shade500, height: 1.6),
          children: const [
            TextSpan(text: '계속하면 '),
            TextSpan(
                text: '서비스 이용약관',
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: ' 및 '),
            TextSpan(
                text: '개인정보 처리방침',
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: '에 동의하는 것으로 간주됩니다.'),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
