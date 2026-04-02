// lib/features/home/views/invitation_opening_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class InvitationOpeningScreen extends StatefulWidget {
  final VoidCallback? onAnimationComplete;

  const InvitationOpeningScreen({super.key, this.onAnimationComplete});

  @override
  State<InvitationOpeningScreen> createState() =>
      _InvitationOpeningScreenState();
}

class _InvitationOpeningScreenState extends State<InvitationOpeningScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    // Flutter Web에서는 video_player가 불안정 → 바로 다음 화면으로 이동
    if (kIsWeb) {
      // initState 중 Navigator 호출 불가 → 첫 프레임 후 실행
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onAnimationComplete?.call();
      });
      return;
    }

    try {
      _controller = VideoPlayerController.asset(
        'assets/videos/왁스_실링_종이_열림_영상.mp4',
      );

      await _controller.initialize();

      _controller.addListener(() {
        // 영상이 끝까지 재생되면 콜백 호출
        if (_controller.value.position >= _controller.value.duration &&
            !_controller.value.isPlaying) {
          widget.onAnimationComplete?.call();
        }
      });

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }

      // 자동 재생 (무음)
      await _controller.setVolume(0.0);
      await _controller.play();
    } catch (e) {
      // 영상 재생 실패 시 (코덱 미지원, 파일 없음 등) 바로 다음 화면으로 이동
      debugPrint('Video init failed: $e');
      widget.onAnimationComplete?.call();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_circle_outline,
                    color: Colors.white,
                    size: 60,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '초대장을 열고 있습니다...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
      ),
    );
  }
}
