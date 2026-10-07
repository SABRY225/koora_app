import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/locale_provider.dart';

import '../home/home_screen.dart';
// Placeholders for other screens
import '../match/match_list_screen.dart';
import '../ranking/ranking_screen.dart';
import '../wallet/wallet_screen.dart';
import '../profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const MatchListScreen(),
    const RankingScreen(),
    const WalletScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return Scaffold(
      extendBody: true,
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF131313).withOpacity(0.9),
          border: const Border(top: BorderSide(color: Colors.white10, width: 1)),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          selectedItemColor: const Color(0xFF00FF41), // primaryGreen
          unselectedItemColor: const Color(0xFFB9CCB2), // textMuted
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 10),
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.home), label: locale.translate('HOME')),
            BottomNavigationBarItem(icon: const Icon(Icons.sports_soccer), label: locale.translate('MATCHES')),
            BottomNavigationBarItem(icon: const Icon(Icons.leaderboard), label: locale.translate('RANKING')),
            BottomNavigationBarItem(icon: const Icon(Icons.account_balance_wallet), label: locale.translate('WALLET')),
            BottomNavigationBarItem(icon: const Icon(Icons.person), label: locale.translate('PROFILE')),
          ],
        ),
      ),
    );
  }
}
