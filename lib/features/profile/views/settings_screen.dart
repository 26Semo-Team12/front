import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/profile_view_model.dart';
import '../../../core/services/mock_api_service.dart';
import '../../../core/viewmodels/theme_view_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _locationConsent = true;
  bool _notificationsEnabled = true;

  void _showLogoutDialog(ProfileViewModel viewModel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('회원 탈퇴',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: const Text(
            '탈퇴 시 모든 데이터가 삭제되며 복구할 수 없습니다.\n정말 탈퇴하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _snack('회원 탈퇴가 처리되었습니다.');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('탈퇴', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final themeVm = context.watch<ThemeViewModel>();

    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel(MockApiService.instance),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('설정', style: TextStyle(fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: Consumer<ProfileViewModel>(
            builder: (context, viewModel, _) {
              return ListView(
                children: [
                  // ── 화면 설정 ──
                  _header('화면 설정'),
                  SwitchListTile(
                    secondary: const Icon(Icons.dark_mode_outlined),
                    title: const Text('다크 모드', style: TextStyle(fontSize: 16)),
                    subtitle: Text(
                      themeVm.isDark ? '다크 모드 사용 중' : '라이트 모드 사용 중',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    ),
                    activeThumbColor: const Color(0xFFD6706D),
                    activeTrackColor:
                        const Color(0xFFD6706D).withValues(alpha: 0.4),
                    value: themeVm.isDark,
                    onChanged: themeVm.toggle,
                  ),
                  const _Divider(),

                  // ── 권한 설정 ──
                  _header('권한 설정'),
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_none),
                    title: const Text('앱 푸시 알림', style: TextStyle(fontSize: 16)),
                    subtitle: Text(
                      _notificationsEnabled ? '알림을 받고 있습니다' : '알림이 꺼져 있습니다',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    ),
                    activeThumbColor: const Color(0xFFD6706D),
                    activeTrackColor:
                        const Color(0xFFD6706D).withValues(alpha: 0.4),
                    value: _notificationsEnabled,
                    onChanged: (val) =>
                        setState(() => _notificationsEnabled = val),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.location_on_outlined),
                    title: const Text('위치 액세스 권한',
                        style: TextStyle(fontSize: 16)),
                    subtitle: Text(
                      _locationConsent
                          ? '위치 기반 서비스 이용 중'
                          : '위치 정보 제공 거부됨',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    ),
                    activeThumbColor: const Color(0xFFD6706D),
                    activeTrackColor:
                        const Color(0xFFD6706D).withValues(alpha: 0.4),
                    value: _locationConsent,
                    onChanged: (val) =>
                        setState(() => _locationConsent = val),
                  ),
                  const _Divider(),

                  // ── 앱 정보 ──
                  _header('앱 정보'),
                  _tile(
                    icon: Icons.description_outlined,
                    title: '이용약관',
                    onTap: () => _snack('이용약관 페이지 준비 중입니다.'),
                  ),
                  _tile(
                    icon: Icons.shield_outlined,
                    title: '개인정보 처리방침',
                    onTap: () => _snack('개인정보 처리방침 페이지 준비 중입니다.'),
                  ),
                  _tile(
                    icon: Icons.child_care_outlined,
                    title: '청소년 보호 정책',
                    onTap: () => _snack('청소년 보호 정책 페이지 준비 중입니다.'),
                  ),
                  _tile(
                    icon: Icons.source_outlined,
                    title: '오픈소스 라이선스',
                    onTap: () => _snack('오픈소스 라이선스 페이지 준비 중입니다.'),
                  ),
                  _tile(
                    icon: Icons.headset_mic_outlined,
                    title: '문의하기',
                    onTap: () => _snack('문의하기 페이지 준비 중입니다.'),
                  ),
                  const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('버전 정보', style: TextStyle(fontSize: 16)),
                    trailing: Text('v1.0.0',
                        style: TextStyle(color: Colors.grey, fontSize: 14)),
                  ),
                  const _Divider(),

                  // ── 계정 ──
                  _header('계정'),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('로그아웃',
                        style: TextStyle(color: Colors.red, fontSize: 16)),
                    onTap: () => _showLogoutDialog(viewModel),
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_remove_outlined,
                        color: Colors.red),
                    title: const Text('회원 탈퇴',
                        style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    onTap: _showDeleteAccountDialog,
                  ),
                  const SizedBox(height: 40),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header(String title) => Padding(
        padding: const EdgeInsets.only(left: 16, top: 24, bottom: 4),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade500,
            letterSpacing: 0.5,
          ),
        ),
      );

  Widget _tile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) =>
      ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontSize: 16)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      );
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.05)
          : const Color(0xFFF5F5F5),
      margin: const EdgeInsets.symmetric(vertical: 4),
    );
  }
}
