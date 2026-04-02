// lib/features/splash/viewmodels/splash_view_model.dart

import 'dart:async';
import 'package:flutter/foundation.dart';

/// 스플래시 화면의 비즈니스 로직을 담당하는 ViewModel
/// - 2.5초 타이머 후 콜백 실행 (AuthScreen 이동)
class SplashViewModel extends ChangeNotifier {
  Timer? _timer;

  /// 2.5초 후 [onComplete] 콜백 호출
  void startTimer(VoidCallback onComplete) {
    _timer = Timer(const Duration(milliseconds: 2500), onComplete);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
