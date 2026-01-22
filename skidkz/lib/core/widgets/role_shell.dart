import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skidkz/core/theme/app_theme.dart';

class RoleShell extends StatefulWidget {
  final Widget child;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;
  final int mainTabIndex;

  const RoleShell({
    super.key,
    required this.child,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.mainTabIndex = 0,
  });

  @override
  State<RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends State<RoleShell> {
  DateTime? _lastBackPressTime;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // 1. If we are on a different tab than Main, switch to Main
        if (widget.selectedIndex != widget.mainTabIndex) {
          widget.onDestinationSelected(widget.mainTabIndex);
          return;
        }

        // 2. If we are on Main tab, handle double press to exit
        final now = DateTime.now();
        if (_lastBackPressTime == null || 
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Нажмите ещё раз для выхода'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }

        // 3. Exit app
        SystemNavigator.pop();
      },
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: widget.selectedIndex,
          onDestinationSelected: widget.onDestinationSelected,
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: AppTheme.secondary,
          destinations: widget.destinations,
        ),
      ),
    );
  }
}
