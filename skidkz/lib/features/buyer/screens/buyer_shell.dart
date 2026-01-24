import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:skidkz/features/common/widgets/skid_drawer.dart';

class BuyerShell extends ConsumerWidget {
  const BuyerShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SkidKZ'),
      ),
      drawer: const SkidDrawer(),
      body: child,
    );
  }
}
