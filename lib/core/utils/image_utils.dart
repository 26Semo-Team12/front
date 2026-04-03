import 'dart:io';
import 'package:flutter/material.dart';

const String _serverBase = 'http://43.201.46.164:3000';

/// URL이 로컬 파일 경로인지 확인
bool isLocalPath(String url) {
  return !url.startsWith('http://') && !url.startsWith('https://');
}

/// 서버 상대 경로(/uploads/...)를 절대 URL로 변환
String resolveImageUrl(String url) {
  if (url.startsWith('/')) {
    return '$_serverBase$url';
  }
  return url;
}

/// 로컬/네트워크 경로를 자동으로 구분해 ImageProvider를 반환
ImageProvider resolveImage(String url) {
  if (isLocalPath(url)) {
    return FileImage(File(url));
  }
  return NetworkImage(resolveImageUrl(url));
}

/// 이미지 로드 실패 시 기본 아이콘을 보여주는 CircleAvatar
class SafeCircleAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final Color? backgroundColor;

  const SafeCircleAvatar({
    super.key,
    required this.imageUrl,
    required this.radius,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? cs.surfaceContainerHighest;

    if (imageUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        child: Icon(Icons.person, size: radius, color: cs.onSurfaceVariant),
      );
    }

    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: isLocalPath(imageUrl)
            ? Image.file(
                File(imageUrl),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(bg, cs, radius),
              )
            : Image.network(
                resolveImageUrl(imageUrl),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(bg, cs, radius),
              ),
      ),
    );
  }

  Widget _fallback(Color bg, ColorScheme cs, double radius) {
    return Container(
      color: bg,
      child: Icon(Icons.person, size: radius, color: cs.onSurfaceVariant),
    );
  }
}
