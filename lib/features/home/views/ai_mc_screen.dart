// lib/features/home/views/ai_mc_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class AiMcScreen extends StatefulWidget {
  const AiMcScreen({super.key});

  @override
  State<AiMcScreen> createState() => _AiMcScreenState();
}

class _AiMcScreenState extends State<AiMcScreen> with TickerProviderStateMixin {
  late final List<AnimationController> _waveControllers;
  late final List<Animation<double>> _waveAnims;
  Timer? _timer;
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    _waveControllers = List.generate(3, (i) => AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800 + i * 200),
    ));
    _waveAnims = _waveControllers
        .map((c) => Tween<double>(begin: 0, end: 1)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeOut)))
        .toList();
    _scheduleNext();
  }

  void _scheduleNext() {
    _timer = Timer(Duration(milliseconds: 1200 + Random().nextInt(2000)), () {
      if (!mounted) return;
      _speak();
    });
  }

  void _speak() {
    setState(() => _speaking = true);
    for (var i = 0; i < _waveControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 140), () {
        if (mounted) _waveControllers[i].forward(from: 0);
      });
    }
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) {
        setState(() => _speaking = false);
        _scheduleNext();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _waveControllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('AI MC', style: TextStyle(color: Colors.white70)),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ..._waveAnims.map((anim) => AnimatedBuilder(
                        animation: anim,
                        builder: (_, __) => Opacity(
                          opacity: (1 - anim.value).clamp(0.0, 1.0),
                          child: Container(
                            width: 100 + anim.value * 110,
                            height: 100 + anim.value * 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF7B68EE).withValues(alpha: 0.6),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      )),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _speaking ? 108 : 100,
                    height: _speaking ? 108 : 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _speaking ? const Color(0xFF9B8FFF) : const Color(0xFF7B68EE),
                          const Color(0xFF4A3FBF),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7B68EE)
                              .withValues(alpha: _speaking ? 0.6 : 0.3),
                          blurRadius: _speaking ? 30 : 15,
                          spreadRadius: _speaking ? 8 : 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      _speaking ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            AnimatedOpacity(
              opacity: _speaking ? 1.0 : 0.4,
              duration: const Duration(milliseconds: 200),
              child: Text(
                _speaking ? 'AI MC가 말하고 있습니다...' : '대기 중',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () { _timer?.cancel(); _speak(); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: const Text('말하기 테스트 (디버그)',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
