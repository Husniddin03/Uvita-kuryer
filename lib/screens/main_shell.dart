import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../services/permission_service.dart';
import '../services/push_service.dart';
import '../theme.dart';
import '../widgets/alert_stack.dart';
import '../widgets/bottom_nav_bar.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _historyKey = GlobalKey<HistoryScreenState>();

  late final List<Widget> _pages = [
    const HomeScreen(),
    HistoryScreen(key: _historyKey),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Pollingni boshlash (start() ichki holatni tozalaydi — takroran xavfsiz)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().start();
      _requestPermissionsOnce();
      // FCM token'ni backend'ga ro'yxatdan o'tkazish (push kelishi uchun)
      PushService.registerToken();
    });
  }

  /// Birinchi kirishda barcha ruxsatlarni (joylashuv + bildirishnoma) so'raydi.
  Future<void> _requestPermissionsOnce() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('permissions_requested') ?? false) return;
    await PermissionService.requestAll();
    await prefs.setBool('permissions_requested', true);
  }

  void _onTap(int i) {
    setState(() => _index = i);
    // Tarix tab ochilganda yangi ma'lumot yuklanadi (stale ro'yxat bo'lmasligi uchun)
    if (i == 1) {
      _historyKey.currentState?.refresh();
    }
    // Profil tab ochilganda profil (shift/avtomobil) yangilanadi
    if (i == 2) {
      context.read<AuthProvider>().refreshProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            IndexedStack(index: _index, children: _pages),
            // Yangi buyurtma banneri (overlay)
            const Align(
              alignment: Alignment.topCenter,
              child: SafeArea(child: AlertStack()),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(index: _index, onTap: _onTap),
    );
  }
}
