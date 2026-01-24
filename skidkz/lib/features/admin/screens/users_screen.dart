// lib/features/admin/screens/users_screen.dart

import 'package:flutter/material.dart';
import 'package:skidkz/data/models/user_model.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final demoUsers = <AppUser>[
      const AppUser(
        id: 'u1',
        name: 'Buyer John',
        phoneNumber: '7771112233',
        role: UserRole.buyer,
      ),
      const AppUser(
        id: 'u2',
        name: 'Wanghong Ivan',
        phoneNumber: '7774445566',
        role: UserRole.wanghong,
        promoCode: 'IVAN25',
      ),
      const AppUser(
        id: 'u3',
        name: 'Seller Shop',
        phoneNumber: '7777778899',
        role: UserRole.seller,
      ),
      const AppUser(
        id: 'u4',
        name: 'Admin Boss',
        phoneNumber: '7770000000',
        role: UserRole.admin,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Пользователи'),
        centerTitle: false,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: demoUsers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final u = demoUsers[index];

          return Card(
            elevation: 0,
            child: ListTile(
              title: Text(u.name ?? 'Без имени'),
              subtitle: Text('${u.phoneNumber}\nРоль: ${u.role?.name ?? '-'}'),
              isThreeLine: true,
              trailing: u.role == UserRole.wanghong
                  ? Text(u.promoCode ?? '')
                  : null,
            ),
          );
        },
      ),
    );
  }
}
