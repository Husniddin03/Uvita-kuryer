import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/order_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'services/api_client.dart';
import 'services/notification_service.dart';
import 'services/push_service.dart';
import 'theme.dart';

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Profil sahifasida kiritilgan API manzilini (ngrok URL kabi) yuklaymiz
  await ApiClient.loadSavedBaseUrl();

  // Android 15+ edge-to-edge: tizim panellari shaffof ko'rsatiladi,
  // kontent SafeArea bilan tizim panellaridan ajratiladi.
  // Status bar ikonkalari: yorug' fonli sahifalar uchun qorong'i (default),
  // qorong'i fonli sahifalar (login, splash, order detail) o'zlari light qiladi.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  // Bildirishnomani bosganda buyurtma sahifasiga o'tish uchun
  NotificationService.navigatorKey = _navigatorKey;
  NotificationService.init();
  // FCM push (Firebase sozlanmagan bo'lsa — xavfsiz o'tib ketadi)
  PushService.init();

  runApp(const UvitaCourierApp());
}

class UvitaCourierApp extends StatelessWidget {
  const UvitaCourierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (ctx) {
            final auth = AuthProvider()..restore();
            // Token eskirganda (401) avtomatik chiqish
            ApiClient.onUnauthorized = () {
              ctx.read<AuthProvider>().forceLogout();
            };
            return auth;
          },
        ),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: MaterialApp(
        title: 'Uvita — Kuryer',
        debugShowCheckedModeBanner: false,
        navigatorKey: _navigatorKey,
        theme: AppTheme.light,
        home: const _RootGate(),
      ),
    );
  }
}

/// Sessiya holatiga qarab kirish yoki asosiy panelni ko'rsatadi.
/// Splash animatsiyasi TO'LIQ o'ynab tugamaguncha ushlab turadi —
/// sekin ishga tushganda ham 'u' pop → kichiklashuv → 'vita' harflar
/// ketma-ketligi kesilmaydi (sahifa erta ochilmaydi).
class _RootGate extends StatefulWidget {
  const _RootGate();

  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  /// Splash animatsiyasi tugadimi (onDone callback orqali belgilanadi).
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    // Cold-start'da notification bosilgan bo'lsa — birinchi frame'dan keyin ochamiz
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.consumePending();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final ready = auth.status != AuthStatus.unknown;

    if (!ready || !_splashDone) {
      return _SplashScreen(
        onDone: () {
          if (mounted) setState(() => _splashDone = true);
        },
      );
    }

    if (!auth.isAuthenticated) {
      // Logout'dan keyin polling to'xtaydi (401 spam bo'lmasligi uchun)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<OrderProvider>().stop();
      });
      return const LoginScreen();
    }

    // Pollingni MainShell'da bir marta boshlanadi (initState)
    return const MainShell();
  }
}

/// Splash — oq fonda jonli Uvita logosi animatsiyasi:
/// 1. Katta U belgisi markazda pop bilan chiqadi (3× kattalikda)
/// 2. Kichiklashib chapga suriladi (o'z joyiga)
/// 3. Shu paytda 'vita' harflari o'ngdan ketma-ket suzib kiradi
/// 4. Pastda KURYER yozuvi paydo bo'ladi
class _SplashScreen extends StatefulWidget {
  const _SplashScreen({this.onDone});

  /// Animatsiya tugaganda chaqiriladi — RootGate keyingi sahifaga o'tadi.
  final VoidCallback? onDone;

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  /// Animatsiya umumiy davomiyligi (sekund).
  static const double _durationSec = 2.4;

  // Final lockup o'lchamlari (mark + vita harflari, pastki chiziqda)
  static const double _markH = 90; // U belgisi balandligi
  static const double _letterH = 38; // harflar balandligi
  static const double _markGap = 8; // mark va 'v' orasi
  static const double _letterGap = 2; // harflar orasi

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    // Animatsiya to'liq tugagach RootGate'ga xabar beramiz — shunda
    // sekin telefonlarda ham sahifa erta ochilib ketmaydi.
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone?.call();
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Harf uchun: [start] soniyada paydo bo'la boshlaydi, 0.16s davom etadi.
  double _letterT(double t, double start) =>
      ((t - start) / 0.16).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            // t — sekundlarda
            final t = _controller.value * _durationSec;

            // --- U belgisi o'lchamlari (187x238 asl, aspect saqlanadi) ---
            const markW = 187 * _markH / 238; // ≈ 71
            // Harflar: wordmark 85px balandlikda — umumiy koeffitsient bilan
            // kichraytiriladi (baseline saqlanadi, nisbatlar buzilmaydi)
            const f = _letterH / 85; // _letterH = 38 → f ≈ 0.447
            const vW = 73 * f, vH = 63 * f;
            const iW = 36 * f, iH = 85 * f;
            const tW = 38 * f, tH = 82 * f;
            const aW = 69 * f, aH = 66 * f;

            const vLeft = markW + _markGap;
            const iLeft = vLeft + vW + _letterGap;
            const tLeft = iLeft + iW + _letterGap;
            const aLeft = tLeft + tW + _letterGap;
            const stackW = aLeft + aW;
            const stackH = _markH;

            // --- Mark animatsiyasi ---
            // Pop: 0.05–0.35 (0 → 2.6, overshoot)
            final popT = ((t - 0.05) / 0.30).clamp(0.0, 1.0);
            final popScale = Curves.easeOutBack.transform(popT) * 2.6;
            // Kichrayish + chapga surilish: 0.35–1.05 (2.6 → 1.0)
            final moveT = ((t - 0.35) / 0.70).clamp(0.0, 1.0);
            final moveEase = Curves.easeInOutCubic.transform(moveT);
            final scale = popT < 1.0 ? popScale : 2.6 + (1.0 - 2.6) * moveEase;
            const centerDx = (stackW - markW) / 2;
            final markDx = centerDx * (1 - moveEase);
            final markOpacity = ((t - 0.03) / 0.15).clamp(0.0, 1.0);

            // --- Harflar: v 0.70, i 0.83, t 0.96, a 1.09 ---
            Widget letter({
              required String asset,
              required double width,
              required double height,
              required double left,
              required double start,
            }) {
              final lt = _letterT(t, start);
              final slide = 30 * (1 - Curves.easeOutCubic.transform(lt));
              final lScale = 0.6 + 0.4 * Curves.easeOutBack.transform(lt);
              return Positioned(
                left: left + slide,
                bottom: 0,
                child: Opacity(
                  opacity: lt,
                  child: Transform.scale(
                    scale: lScale,
                    child: Image.asset(
                      asset,
                      width: width,
                      height: height,
                    ),
                  ),
                ),
              );
            }

            // KURYER: 1.5–1.9
            final subT = ((t - 1.50) / 0.40).clamp(0.0, 1.0);

            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: stackW,
                    height: stackH,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: markDx,
                          bottom: 0,
                          child: Opacity(
                            opacity: markOpacity,
                            child: Transform.scale(
                              scale: scale,
                              child: Image.asset(
                                'assets/logo/parts/u_mark_full.png',
                                width: markW,
                                height: _markH,
                              ),
                            ),
                          ),
                        ),
                        letter(
                          asset: 'assets/logo/parts/v.png',
                          width: vW,
                          height: vH,
                          left: vLeft,
                          start: 0.70,
                        ),
                        letter(
                          asset: 'assets/logo/parts/i.png',
                          width: iW,
                          height: iH,
                          left: iLeft,
                          start: 0.83,
                        ),
                        letter(
                          asset: 'assets/logo/parts/t.png',
                          width: tW,
                          height: tH,
                          left: tLeft,
                          start: 0.96,
                        ),
                        letter(
                          asset: 'assets/logo/parts/a.png',
                          width: aW,
                          height: aH,
                          left: aLeft,
                          start: 1.09,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Opacity(
                    opacity: subT,
                    child: const Text(
                      'KURYER',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0A84FF),
                        letterSpacing: 7,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
