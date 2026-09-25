import 'package:flutter/material.dart';

import 'core/di/app_dependencies.dart';
import 'core/navigation/ben_page_transitions.dart';
import 'core/theme/app_theme.dart';
import 'screens/account_entry_screen.dart';
import 'screens/ben_particle_splash_screen.dart';
import 'screens/main_screen.dart';
import 'services/auth_service.dart';

class BENApp extends StatefulWidget {
  const BENApp({super.key});

  @override
  State<BENApp> createState() => _BENAppState();
}

class _BENAppState extends State<BENApp> {
  late final AppDependencies _deps;
  ThemeMode _themeMode = ThemeMode.dark;
  bool _authenticated = false;
  BenUser? _user;
  bool _showSplash = true;
  bool _booting = true;

  @override
  void initState() {
    super.initState();
    _deps = AppDependencies.create();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final restored = await _deps.auth.restoreSession();
    if (!mounted) return;
    setState(() {
      _authenticated = restored && AuthService.currentUser != null;
      _user = AuthService.currentUser;
      _booting = false;
    });
  }

  Future<void> _onAuthenticated(BenUser user) async {
    if (!mounted) return;
    FocusManager.instance.primaryFocus?.unfocus(
      disposition: UnfocusDisposition.scope,
    );
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    setState(() {
      _user = user;
      _authenticated = true;
    });
  }

  Future<void> _logout() async {
    await _deps.auth.logout();
    if (!mounted) return;
    setState(() {
      _user = null;
      _authenticated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget home;
    if (_booting) {
      home = const ColoredBox(
        color: Color(0xFF080B12),
        child: SizedBox.expand(),
      );
    } else if (!_authenticated || _user == null) {
      home = AccountEntryScreen(
        auth: _deps.auth,
        onAuthenticated: _onAuthenticated,
      );
    } else {
      home = MainScreen(
        themeMode: _themeMode,
        currentUser: _user,
        onLogout: _logout,
        onThemeChanged: (mode) {
          if (mounted) setState(() => _themeMode = mode);
        },
        dependencies: _deps,
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BEN',
      theme: AppTheme.light()
          .copyWith(pageTransitionsTheme: BENPageTransitionsTheme.value),
      darkTheme: AppTheme.dark()
          .copyWith(pageTransitionsTheme: BENPageTransitionsTheme.value),
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
