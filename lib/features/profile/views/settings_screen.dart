import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/profile_view_model.dart';
import '../../../core/services/mock_api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  void _showLogoutDialog(ProfileViewModel viewModel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('로그아웃', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              viewModel.logout(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD6706D),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('확인', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel(MockApiService.instance),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('설정', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Consumer<ProfileViewModel>(
          builder: (context, viewModel, child) {
            return ListView(
              children: [
                // ── 알림 설정 ──
                _buildSectionHeader('알림 설정'),
                SwitchListTile(
                  title: const Text('앱 푸시 알림', style: TextStyle(fontSize: 16)),
                  subtitle: Text(
                    _notificationsEnabled ? '알림을 받고 있습니다' : '알림이 꺼져 있습니다',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                  activeColor: const Color(0xFFD6706D),
                  value: _notificationsEnabled,
                  onChanged: (val) {
                    setState(() {
                      _notificationsEnabled = val;
                    });
                  },
                ),
                const _SectionDivider(),

                // ── 앱 정보 ──
                _buildSectionHeader('앱 정보'),
                ListTile(
                  leading: const Icon(Icons.description_outlined, color: Colors.grey),
                  title: const Text('이용약관', style: TextStyle(fontSize: 16)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('이용약관 페이지 준비 중입니다.')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.shield_outlined, color: Colors.grey),
                  title: const Text('개인정보 처리방침', style: TextStyle(fontSize: 16)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('개인정보 처리방침 페이지 준비 중입니다.')),
                    );
                  },
                ),
                const ListTile(
                  leading: Icon(Icons.info_outline, color: Colors.grey),
                  title: Text('버전 정보', style: TextStyle(fontSize: 16)),
                  trailing: Text('v1.0.0', style: TextStyle(color: Colors.grey, fontSize: 14)),
                ),
                const _SectionDivider(),

                // ── 위험 구역 ──
                _buildSectionHeader('위험 구역'),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('로그아웃', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                  onTap: () => _showLogoutDialog(viewModel),
                ),
                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      color: const Color(0xFFF5F5F5),
      margin: const EdgeInsets.symmetric(vertical: 4),
    );
  }
}
