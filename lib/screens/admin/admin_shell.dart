import 'package:flutter/material.dart';
import 'admin_bookings_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_destinations_screen.dart';
import 'admin_packages_screen.dart';
import 'admin_users_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  // Bumped every time the Dashboard tab is selected so its stats/popular
  // destinations reload fresh instead of showing whatever IndexedStack kept
  // alive from before other tabs made edits (same pattern used for the
  // customer-facing My Trips tab).
  int _dashboardReloadKey = 0;

  void _onTabTapped(int i) {
    setState(() {
      if (i == 0) _dashboardReloadKey++;
      _index = i;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      AdminDashboardScreen(key: ValueKey(_dashboardReloadKey)),
      const AdminPackagesScreen(),
      const AdminDestinationsScreen(),
      const AdminBookingsScreen(),
      const AdminUsersScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_travel_outlined),
            activeIcon: Icon(Icons.card_travel),
            label: 'Packages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Destinations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Users',
          ),
        ],
      ),
    );
  }
}
