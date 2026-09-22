import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/navigation/ben_page_transitions.dart';
import 'screens/main_screen.dart';
import 'screens/account_entry_screen.dart';
import 'services/auth_service.dart';
import 'core/network/api_client.dart';
import 'screens/ben_particle_splash_screen.dart';

class BENApp extends StatefulWidget {
  const BENApp({super.key});

  @override
  State<BENApp> createState() => _BENAppState();
}

class _BENAppState extends State<BENApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  bool _authenticated = false;
  BenUser? _user;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final restored = await AuthService.restoreSession();
    if (!mounted) return;
    setState(() {
      _authenticated = restored && AuthService.currentUser != null;
      _user = AuthService.currentUser;
    });
  }

  Future<void> _onAuthenticated(BenUser user) async {
    if (!mounted) return;
    FocusManager.instance.primaryFocus?.unfocus(disposition: UnfocusDisposition.scope);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    setState(() {
      _user = user;
      _authenticated = true;
    });
  }

  Future<void> _logout() async {
    await AuthService(ApiClient()).logout();
    if (!mounted) return;
    setState(() {
      _user = null;
      _authenticated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget home;
    if (!_authenticated || _user == null) {
      home = AccountEntryScreen(onAuthenticated: _onAuthenticated);
    } else {
      home = MainScreen(
        themeMode: _themeMode,
        currentUser: _user,
        onLogout: _logout,
        onThemeChanged: (mode) {
          if (mounted) setState(() => _themeMode = mode);
        },
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BEN',
      theme: AppTheme.light().copyWith(pageTransitionsTheme: BENPageTransitionsTheme.value),
      darkTheme: AppTheme.dark().copyWith(pageTransitionsTheme: BENPageTransitionsTheme.value),
      themeMode: _themeMode,
      home: _showSplash
          ? BENParticleSplashScreen(
              onFinished: () {
                if (mounted) setState(() => _showSplash = false);
              },
            )
          : home,
    );
  }
}
