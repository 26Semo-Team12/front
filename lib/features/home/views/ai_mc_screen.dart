// lib/features/home/views/ai_mc_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../../../core/network/api_client.dart';

enum _McState { connecting, connected, error }

class AiMcScreen extends StatefulWidget {
  const AiMcScreen({super.key});

  @override
  State<AiMcScreen> createState() => _AiMcScreenState();
}

class _AiMcScreenState extends State<AiMcScreen> with TickerProviderStateMixin {
  late final List<AnimationController> _waveControllers;
  late final List<Animation<double>> _waveAnims;
  late final WebViewController _webViewController;

  _McState _state = _McState.connecting;
  bool _speaking = false;
  bool _recording = false;
  String? _errorMessage;
  String _debugInfo = '';

  // 백엔드와 WebRTC 협상을 처리하는 HTML+JS (브라우저 내장 WebRTC 사용)
  static const String _sessionHtml = '''
<!DOCTYPE html>
<html>
<head><meta name="viewport" content="width=device-width,initial-scale=1.0"></head>
<body>
<script>
'use strict';
var _pc = null;
var _stream = null;
var _dc = null;
var _speaking = false;

async function startSession(baseUrl) {
  try {
    _stream = await navigator.mediaDevices.getUserMedia({audio: true, video: false});

    // 마이크를 처음에는 음소거 상태로 시작 (푸시투톡)
    _stream.getAudioTracks().forEach(function(t) { t.enabled = false; });

    _pc = new RTCPeerConnection({
      iceServers: [{urls: 'stun:stun.l.google.com:19302'}]
    });

    // 1) 로컬 마이크 트랙 추가
    _stream.getTracks().forEach(function(t) { _pc.addTrack(t, _stream); });

    // 2) 클라이언트가 데이터 채널을 먼저 생성 (offer SDP에 포함됨)
    _dc = _pc.createDataChannel('oai-events');

    _dc.onopen = function() {
      FlutterChannel.postMessage('debug:dc open');
      // AI의 첫 인사를 트리거
      _dc.send(JSON.stringify({ type: 'response.create' }));
    };

    _dc.onmessage = function(msg) {
      try {
        var evt = JSON.parse(msg.data);
        // AI가 말하기 시작
        if (evt.type === 'response.audio.delta' && !_speaking) {
          _speaking = true;
          FlutterChannel.postMessage('speaking:true');
        }
        // AI 응답 완료
        if (evt.type === 'response.done') {
          _speaking = false;
          FlutterChannel.postMessage('speaking:false');
        }
        // 오류
        if (evt.type === 'error') {
          FlutterChannel.postMessage('debug:api error: ' + JSON.stringify(evt.error));
        }
      } catch(e) {}
    };

    // 3) 원격 오디오 트랙 수신 → <audio> 요소로 재생
    _pc.ontrack = function(ev) {
      if (ev.track.kind !== 'audio') return;
      FlutterChannel.postMessage('debug:ontrack fired');
      var audio = document.getElementById('ra') || document.createElement('audio');
      audio.id = 'ra';
      audio.autoplay = true;
      audio.srcObject = ev.streams[0];
      if (!audio.parentNode) document.body.appendChild(audio);
      audio.play().catch(function(e) {
        FlutterChannel.postMessage('debug:audio.play error: ' + e.message);
      });
    };

    // 4) Offer 생성 (데이터 채널 + 오디오 트랙 포함)
    var offer = await _pc.createOffer();
    await _pc.setLocalDescription(offer);

    await new Promise(function(resolve) {
      if (_pc.iceGatheringState === 'complete') { resolve(); return; }
      var onState = function() {
        if (_pc.iceGatheringState === 'complete') {
          _pc.removeEventListener('icegatheringstatechange', onState);
          resolve();
        }
      };
      _pc.addEventListener('icegatheringstatechange', onState);
      setTimeout(resolve, 6000);
    });

    var resp = await fetch(baseUrl + '/realtime/session', {
      method: 'POST',
      headers: {'Content-Type': 'text/plain'},
      body: _pc.localDescription.sdp
    });

    if (!resp.ok) throw new Error('HTTP ' + resp.status);

    var answer = await resp.text();
    await _pc.setRemoteDescription({type: 'answer', sdp: answer});

    _pc.oniceconnectionstatechange = function() {
      FlutterChannel.postMessage('ice:' + _pc.iceConnectionState);
    };
    _pc.onconnectionstatechange = function() {
      FlutterChannel.postMessage('conn:' + _pc.connectionState);
    };

    FlutterChannel.postMessage('connected');
  } catch(e) {
    FlutterChannel.postMessage('error:' + (e.message || String(e)));
  }
}

function startTalking() {
  if (_stream) {
    _stream.getAudioTracks().forEach(function(t) { t.enabled = true; });
  }
}

function stopTalking() {
  if (_stream) {
    _stream.getAudioTracks().forEach(function(t) { t.enabled = false; });
  }
  if (_dc && _dc.readyState === 'open') {
    _dc.send(JSON.stringify({ type: 'input_audio_buffer.commit' }));
    _dc.send(JSON.stringify({ type: 'response.create' }));
  }
}

function stopSession() {
  if (_stream) { _stream.getTracks().forEach(function(t) { t.stop(); }); _stream = null; }
  if (_dc) { _dc.close(); _dc = null; }
  if (_pc) { _pc.close(); _pc = null; }
  FlutterChannel.postMessage('stopped');
}
</script>
</body>
</html>
''';

  @override
  void initState() {
    super.initState();
    _waveControllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 800 + i * 200),
      ),
    );
    _waveAnims = _waveControllers
        .map(
          (c) => Tween<double>(begin: 0, end: 1)
              .animate(CurvedAnimation(parent: c, curve: Curves.easeOut)),
        )
        .toList();
    _setupWebView();
  }

  void _setupWebView() {
    _webViewController = WebViewController();

    // Android: 미디어 자동 재생 허용 + 마이크 권한 자동 승인
    final platform = _webViewController.platform;
    if (platform is AndroidWebViewController) {
      platform.setMediaPlaybackRequiresUserGesture(false);
      platform.setOnPlatformPermissionRequest((request) {
        request.grant();
      });
    }

    _webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (msg) => _handleMessage(msg.message),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            _webViewController.runJavaScript(
              'startSession("${ApiClient.baseUrl}")',
            );
          },
        ),
      )
      ..loadHtmlString(_sessionHtml, baseUrl: 'http://localhost');
  }

  void _handleMessage(String message) {
    if (!mounted) return;
    if (message == 'connected') {
      setState(() => _state = _McState.connected);
      _startWaves();
    } else if (message.startsWith('error:')) {
      final detail = message.substring(6);
      debugPrint('[AI MC] error: $detail');
      setState(() {
        _state = _McState.error;
        _errorMessage = 'AI MC 연결에 실패했습니다.\n($detail)';
      });
    } else if (message == 'speaking:true') {
      if (_state == _McState.connected) {
        setState(() {
          _speaking = true;
          _recording = false; // AI가 말하기 시작하면 녹음 상태 해제
        });
      }
    } else if (message == 'speaking:false') {
      setState(() => _speaking = false);
    } else if (message.startsWith('ice:') ||
        message.startsWith('conn:') ||
        message.startsWith('debug:')) {
      debugPrint('[AI MC] $message');
      setState(() {
        _debugInfo = message.length > 80 ? message.substring(0, 80) : message;
      });
    }
  }

  void _startWaves() {
    for (var i = 0; i < _waveControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 300), () {
        if (mounted && _state == _McState.connected) {
          _waveControllers[i].repeat();
        }
      });
    }
  }

  Future<void> _stopSession() async {
    await _webViewController.runJavaScript('stopSession()');
    for (final c in _waveControllers) {
      c.stop();
      c.reset();
    }
  }

  void _restartSession() {
    setState(() {
      _state = _McState.connecting;
      _errorMessage = null;
      _speaking = false;
    });
    for (final c in _waveControllers) {
      c.stop();
      c.reset();
    }
    _webViewController.runJavaScript('stopSession()').then((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _webViewController.runJavaScript(
            'startSession("${ApiClient.baseUrl}")',
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _webViewController.runJavaScript('stopSession()');
    for (final c in _waveControllers) {
      c.dispose();
    }
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
          onPressed: () async {
            await _stopSession();
            if (mounted) Navigator.of(context).pop();
          },
        ),
        title: const Text('AI MC', style: TextStyle(color: Colors.white70)),
      ),
      body: Stack(
        children: [
          // WebRTC 세션을 처리하는 숨겨진 WebView (투명, 터치 무시)
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0,
                child: WebViewWidget(controller: _webViewController),
              ),
            ),
          ),
          Center(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return switch (_state) {
      _McState.connecting => _buildConnecting(),
      _McState.connected => _buildConnected(),
      _McState.error => _buildError(),
    };
  }

  Widget _buildConnecting() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: Color(0xFF7B68EE)),
        SizedBox(height: 24),
        Text(
          'AI MC 연결 중...',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildConnected() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ..._waveAnims.map(
                (anim) => AnimatedBuilder(
                  animation: anim,
                  builder:
                      (_, __) => Opacity(
                        opacity: (1 - anim.value).clamp(0.0, 1.0),
                        child: Container(
                          width: 100 + anim.value * 110,
                          height: 100 + anim.value * 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF7B68EE).withValues(
                                alpha: 0.6,
                              ),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _speaking ? 108 : 100,
                height: _speaking ? 108 : 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _speaking
                          ? const Color(0xFF9B8FFF)
                          : const Color(0xFF7B68EE),
                      const Color(0xFF4A3FBF),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7B68EE).withValues(
                        alpha: _speaking ? 0.6 : 0.3,
                      ),
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
          opacity: (_speaking || _recording) ? 1.0 : 0.4,
          duration: const Duration(milliseconds: 200),
          child: Text(
            _recording
                ? '듣고 있습니다... 버튼을 눌러 전송'
                : _speaking
                    ? 'AI MC가 말하고 있습니다...'
                    : '아래 버튼을 눌러 말해보세요',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
        const SizedBox(height: 48),

        // 말하기 토글 버튼
        GestureDetector(
          onTap: _speaking
              ? null
              : () {
                  if (_recording) {
                    // 녹음 중 → 전송
                    _webViewController.runJavaScript('stopTalking()');
                    setState(() => _recording = false);
                  } else {
                    // 대기 중 → 녹음 시작
                    _webViewController.runJavaScript('startTalking()');
                    setState(() => _recording = true);
                  }
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _recording ? 80 : 72,
            height: _recording ? 80 : 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: _recording
                    ? [const Color(0xFFFF6B6B), const Color(0xFFEE5A24)]
                    : [const Color(0xFF7B68EE), const Color(0xFF4A3FBF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: (_recording
                          ? const Color(0xFFFF6B6B)
                          : const Color(0xFF7B68EE))
                      .withValues(alpha: _recording ? 0.5 : 0.3),
                  blurRadius: _recording ? 24 : 12,
                  spreadRadius: _recording ? 4 : 1,
                ),
              ],
            ),
            child: Icon(
              _recording ? Icons.send_rounded : Icons.mic,
              color: Colors.white,
              size: _recording ? 32 : 30,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _recording ? '전송' : '말하기',
          style: TextStyle(
            color: _recording ? Colors.redAccent : Colors.white38,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Colors.redAccent, size: 56),
        const SizedBox(height: 20),
        Text(
          _errorMessage ?? '연결 오류가 발생했습니다.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: _restartSession,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7B68EE), Color(0xFF4A3FBF)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Text(
              '다시 시도',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
