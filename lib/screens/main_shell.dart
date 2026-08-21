import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'search/search_screen.dart';
import 'trips/trips_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  // Bumped every time the "My Trips" tab is selected so that tab gets a
  // fresh TripsScreen (and thus a fresh load) instead of the stale one
  // IndexedStack would otherwise keep alive for the whole session.
  int _tripsReloadKey = 0;

  @override
  void initState() {
    super.initState();
    final token = context.read<AuthProvider>().token;
    if (token != null) context.read<FavoritesProvider>().load(token);
  }

  void _goToSearch() => setState(() => _index = 1);

  void _onTabTapped(int i) {
    setState(() {
      if (i == 2) _tripsReloadKey++;
      _index = i;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onNavigateToSearch: _goToSearch),
      const SearchScreen(),
      TripsScreen(key: ValueKey(_tripsReloadKey)),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.card_travel_outlined), activeIcon: Icon(Icons.card_travel), label: 'My Trips'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
