// lib/features/home/views/in_app_map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// 앱 내 지도 화면 (OpenStreetMap 기반, API 키 불필요)
/// [locationName]: 표시할 장소 이름 (마커 툴팁)
/// [lat], [lng]: 지정 위치 좌표. null이면 서울 중심 기본값 사용
class InAppMapScreen extends StatelessWidget {
  final String locationName;
  final double? lat;
  final double? lng;

  const InAppMapScreen({
    super.key,
    required this.locationName,
    this.lat,
    this.lng,
  });

  @override
  Widget build(BuildContext context) {
    // 좌표가 없으면 서울 시청 기본값
    final center = LatLng(lat ?? 37.5665, lng ?? 126.9780);

    return Scaffold(
      appBar: AppBar(
        title: Text(locationName, style: const TextStyle(fontSize: 15)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(initialCenter: center, initialZoom: 15),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.venture.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: center,
                    width: 48,
                    height: 48,
                    child: const Icon(
                      Icons.location_pin,
                      color: Color(0xFFE05C5C),
                      size: 48,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // 장소 이름 하단 카드
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.place, color: Color(0xFFE05C5C), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      locationName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (lat == null)
                    const Text(
                      '(디버그: 좌표 미설정)',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
