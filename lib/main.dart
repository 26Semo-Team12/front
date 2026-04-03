import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/splash/views/splash_screen.dart';
import 'features/notification/viewmodels/notification_view_model.dart';
import 'features/notification/views/notification_popup_overlay.dart';
import 'features/home/viewmodels/home_view_model.dart';
import 'features/auth/services/auth_service.dart';
import 'features/gathering/services/invite_service.dart';
import 'core/viewmodels/theme_view_model.dart';

void main() {
  runApp(const VentureApp());
}

class VentureApp extends StatelessWidget {
  const VentureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(AuthService(), InviteService())..init(),
        ),
      ],
      child: Consumer<ThemeViewModel>(
        builder: (_, themeVm, __) => MaterialApp(
          title: 'Venture',
          debugShowCheckedModeBanner: false,
          themeMode: themeVm.themeMode,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          builder: (context, child) {
            return NotificationPopupOverlay(child: child!);
          },
          home: const SplashScreen(),
        ),
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFD6706D),
        brightness: brightness,
      ),
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      cardColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      dividerColor: isDark ? Colors.white12 : Colors.grey.shade200,
    );
  }
}
