import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/providers/app_state_provider.dart';
import 'core/providers/match_provider.dart';
import 'core/providers/wallet_provider.dart';
import 'core/providers/draft_provider.dart';
import 'core/providers/ranking_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'core/providers/auth_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MatchProvider()),
        ChangeNotifierProvider(create: (_) => DraftProvider()),
        ChangeNotifierProvider(create: (_) => RankingProvider()),
        ChangeNotifierProxyProvider<AppStateProvider, WalletProvider>(
          create: (context) => WalletProvider(context.read<AppStateProvider>()),
          update: (_, appState, prev) => prev ?? WalletProvider(appState),
        ),
      ],
      child: const UFLApp(),
    ),
  );
}

class UFLApp extends StatelessWidget {
  const UFLApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UFL',
      theme: AppTheme.darkTheme,
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
