import 'package:flutter/material.dart';

class WanghongShell extends StatelessWidget {
  final Widget child;

  const WanghongShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(index, context),
        backgroundColor: Colors.white,
        elevation: 0,
        indicatorColor: Colors.purple.shade100,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Colors.purple),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Colors.purple),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    // Simplified for prototype
    return 0; 
  }

  void _onItemTapped(int index, BuildContext context) {
    // context.go('/wanghong/home'); // Single screen for prototype MVP
  }
}
