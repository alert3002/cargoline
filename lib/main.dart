import 'package:cargo_line_tj/app.dart';
import 'package:cargo_line_tj/providers/app_provider.dart';
import 'package:cargo_line_tj/providers/cart_provider.dart';
import 'package:cargo_line_tj/providers/parcel_provider.dart';
import 'package:cargo_line_tj/services/local_store.dart';
import 'package:cargo_line_tj/services/push_service.dart';
import 'package:cargo_line_tj/ui/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// Cold start: first frame = cinematic welcome (no await SharedPreferences).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Warm welcome bytes in parallel with first frames (non-blocking).
  // ignore: discarded_futures
  Future.wait([
    rootBundle.load('assets/images/welcome_day.jpg'),
    rootBundle.load('assets/images/welcome_night.jpg'),
    rootBundle.load('assets/images/welcome_logo.png'),
  ]);

  runApp(const _BootApp());
}

class _BootApp extends StatefulWidget {
  const _BootApp();

  @override
  State<_BootApp> createState() => _BootAppState();
}

class _BootAppState extends State<_BootApp> {
  AppProvider? _app;
  ParcelProvider? _parcels;
  CartProvider? _cart;
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    // ignore: discarded_futures
    _openStore();
  }

  Future<void> _openStore() async {
    final store = await LocalStore.open();
    final app = AppProvider(store);
    final parcels = ParcelProvider(store);
    final cart = CartProvider();

    void syncSession() {
      parcels.setSession(
        accessToken: app.accessToken,
        pickupPoint: app.pickupPoint,
      );
    }

    app.addSessionListener(syncSession);
    app.addSessionListener(() {
      PushService.sync(app.accessToken);
    });
    // ignore: unawaited_futures
    Future.wait([app.load(), parcels.load()]).then((_) {
      syncSession();
      if (mounted) setState(() {});
    });

    if (!mounted) return;
    setState(() {
      _app = app;
      _parcels = parcels;
      _cart = cart;
    });
  }

  String? get _splashName {
    final u = _app?.user;
    if (u == null) return null;
    final n = u.displayFirst.trim();
    if (n.isEmpty || n == 'Клиент') return null;
    return n;
  }

  @override
  Widget build(BuildContext context) {
    final providersReady =
        _app != null && _parcels != null && _cart != null;

    if (!_splashDone) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: CargoSplashScreen(
          key: const ValueKey('boot-splash'),
          onReady: () {
            if (mounted) setState(() => _splashDone = true);
          },
          displayNameOverride: _splashName,
        ),
      );
    }

    if (!providersReady) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF0A1020),
          body: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Color(0xFFE10600),
              ),
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _app!),
        ChangeNotifierProvider.value(value: _parcels!),
        ChangeNotifierProvider.value(value: _cart!),
      ],
      child: const CargoApp(splashAlreadyDone: true),
    );
  }
}
