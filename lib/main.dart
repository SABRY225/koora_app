import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/providers/ad_provider.dart';
import 'core/providers/app_state_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/draft_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/match_provider.dart';
import 'core/providers/ranking_provider.dart';
import 'core/providers/wallet_provider.dart';
import 'core/services/sound_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/token_manager.dart';
import 'features/admin/admin_dashboard_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/main/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  final localeProvider = await LocaleProvider.create();
  await SoundService().init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AdProvider()),
        ChangeNotifierProvider(create: (_) => MatchProvider()),
        ChangeNotifierProvider(create: (_) => DraftProvider()),
        ChangeNotifierProvider(create: (_) => RankingProvider()),
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProxyProvider<AppStateProvider, WalletProvider>(
          create: (context) => WalletProvider(context.read<AppStateProvider>()),
          update: (_, appState, prev) => prev ?? WalletProvider(appState),
        ),
      ],
      child: const UFLApp(),
    ),
  );
}

class UFLApp extends StatefulWidget {
  const UFLApp({super.key});

  @override
  State<UFLApp> createState() => _UFLAppState();
}

class _UFLAppState extends State<UFLApp> {
  late Future<Map<String, dynamic>> _initAuthFuture;

  @override
  void initState() {
    super.initState();
    _initAuthFuture = _checkAuth();
  }

  Future<Map<String, dynamic>> _checkAuth() async {
    final isLoggedIn = await TokenManager.isLoggedIn();
    final role = await TokenManager.getRole();
    return {
      'isLoggedIn': isLoggedIn,
      'role': role,
    };
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    return MaterialApp(
      title: 'UFL',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      locale: localeProvider.locale,
      builder: (context, child) {
        return Directionality(
          textDirection: localeProvider.locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        );
      },
      home: FutureBuilder<Map<String, dynamic>>(
        future: _initAuthFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: AppTheme.backgroundBlack,
              body: Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
            );
          }
          final data = snapshot.data ?? {};
          final isLoggedIn = data['isLoggedIn'] == true;
          final role = (data['role'] ?? '').toString().toLowerCase();

          if (isLoggedIn) {
            if (role == 'admin') {
              return const AdminDashboardScreen();
            }
            return const MainScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
