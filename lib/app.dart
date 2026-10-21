import 'package:cargo_line_tj/providers/app_provider.dart';
import 'package:cargo_line_tj/ui/screens/auth/phone_auth_screen.dart';
import 'package:cargo_line_tj/ui/screens/auth/profile_complete_screen.dart';
import 'package:cargo_line_tj/ui/screens/main_shell.dart';
import 'package:cargo_line_tj/ui/screens/splash_screen.dart';
import 'package:cargo_line_tj/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

class CargoApp extends StatefulWidget {
  const CargoApp({super.key, this.splashAlreadyDone = false});

  /// When true, boot already played [CargoSplashScreen] in main.dart.
  final bool splashAlreadyDone;

  @override
  State<CargoApp> createState() => _CargoAppState();
}

class _CargoAppState extends State<CargoApp> {
  late bool _splashDone = widget.splashAlreadyDone;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isDark = app.isDark;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark ? CargoColors.darkBg : Colors.white,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
    );

    Widget home;
    if (!_splashDone) {
      final n = app.user?.displayFirst.trim();
      home = CargoSplashScreen(
        onReady: () {
          if (mounted) setState(() => _splashDone = true);
        },
        displayNameOverride:
            (n != null && n.isNotEmpty && n != 'Клиент') ? n : null,
      );
    } else if (!app.isAuthenticated) {
      home = const PhoneAuthScreen();
    } else if (app.needsProfileSetup) {
      home = const ProfileCompleteScreen();
    } else {
      home = const MainShell();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CargoLine.TJ',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: app.themeMode,
      locale: Locale(app.locale.name == 'tj' ? 'ru' : 'ru'),
      supportedLocales: const [Locale('ru')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        if (!_splashDone) return child ?? const SizedBox.shrink();
        return CargoBackground(child: child ?? const SizedBox.shrink());
      },
      home: home,
    );
  }
}
