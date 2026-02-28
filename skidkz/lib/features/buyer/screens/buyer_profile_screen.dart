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
  int _refreshTick = 0;

  Future<void> _refresh() async {
    // 1) триггерим перестройку (на случай, если auth стрим не эмитнул, а данные в UI устарели)
    setState(() => _refreshTick++);

    // 2) просим FirebaseAuth обновить currentUser (иногда помогает после verify/signin)
    final u = fb.FirebaseAuth.instance.currentUser;
    if (u != null) {
      await u.reload();
    }

    // 3) короткая пауза чтобы RefreshIndicator не “мелькнул”
    await Future.delayed(const Duration(milliseconds: 250));
  }

  void _safePush(BuildContext context, String path) {
    final r = GoRouter.maybeOf(context);
    if (r == null) return;
    r.push(path);
  }

  void _safeGo(BuildContext context, String path) {
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

        // ГОСТЬ
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
                const Text(
                  'Войдите, чтобы видеть профиль, заказы и управлять настройками.',
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _safePush(context, '/login?next=%2Fbuyer%2Fprofile'),
                    child: const Text('Войти / зарегистрироваться'),
                  ),
                ),
              ],
            ),
          );
        }

        // АВТОРИЗОВАН: данные из users/{uid}
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          // refreshTick — чтобы “потянуть вниз” точно перерисовало даже при snapshot-тишине
          key: ValueKey('profile_${user.uid}_$_refreshTick'),
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (context, snap) {
            final data = snap.data?.data() ?? {};
            final displayName = (data['displayName'] ?? '').toString().trim();
            final phoneDb = (data['phone'] ?? '').toString().trim();
            final phone = phoneDb.isNotEmpty ? phoneDb : (user.phoneNumber ?? '-');

            // можешь расширить: roles, activeRole, email, bonuses и т.д.
            final activeRole = (data['activeRole'] ?? '').toString().trim();
            final roles = (data['roles'] is List) ? (data['roles'] as List).join(', ') : '';

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
                  Text('Телефон: $phone'),

                  if (activeRole.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text('Активная роль: $activeRole'),
                  ],
                  if (roles.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('Роли: $roles'),
                  ],

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await fb.FirebaseAuth.instance.signOut();
                        if (mounted) {
                          _safeGo(context, '/buyer/home');
                        }
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
