// lib/features/buyer/screens/buyer_profile_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BuyerProfileScreen extends StatefulWidget {
  const BuyerProfileScreen({super.key});

  @override
  State<BuyerProfileScreen> createState() => _BuyerProfileScreenState();
}

class _BuyerProfileScreenState extends State<BuyerProfileScreen> {
  Future<void> _refresh() async {
    // важно: RefreshIndicator должен приводить к rebuild
    await Future.delayed(const Duration(milliseconds: 250));
    if (mounted) setState(() {});
  }

  void _safePush(String path) {
    final r = GoRouter.maybeOf(context);
    if (r == null) return;
    r.push(path);
  }

  void _safeGo(String path) {
    final r = GoRouter.maybeOf(context);
    if (r == null) return;
    r.go(path);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<fb.User?>(
      stream: fb.FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        final user = authSnap.data;

        if (user == null) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Профиль',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                const Text('Войдите, чтобы видеть профиль, заказы и управлять настройками.'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _safePush('/login?next=%2Fbuyer%2Fprofile'),
                    child: const Text('Войти / зарегистрироваться'),
                  ),
                ),
              ],
            ),
          );
        }

        // ✅ автhed: тянем данные из users/{uid}
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (context, userSnap) {
            final data = userSnap.data?.data();
            final displayName = (data?['displayName'] ?? '').toString().trim();
            final phone = (data?['phone'] ?? user.phoneNumber ?? '').toString().trim();

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Профиль',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),

                  if (displayName.isNotEmpty) ...[
                    Text('Имя: $displayName'),
                    const SizedBox(height: 6),
                  ],

                  Text('UID: ${user.uid}'),
                  const SizedBox(height: 6),
                  Text('Телефон: ${phone.isEmpty ? '-' : phone}'),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await fb.FirebaseAuth.instance.signOut();
                        if (!mounted) return;
                        _safeGo('/buyer/home');
                      },
                      child: const Text('Выйти'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
