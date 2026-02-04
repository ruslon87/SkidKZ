// lib/features/admin/screens/users_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:skidkz/data/models/user_model.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  UserRole _roleFromString(String? s) {
    final v = (s ?? 'buyer').trim().toLowerCase();
    return UserRole.values.firstWhere(
      (r) => r.name == v,
      orElse: () => UserRole.buyer,
    );
  }

  List<UserRole> _rolesFromAny(dynamic rawRoles, String? rawRoleLegacy) {
    if (rawRoles is List) {
      final out = <UserRole>[];
      for (final x in rawRoles) {
        if (x is String) out.add(_roleFromString(x));
      }
      if (out.isNotEmpty) return out.toSet().toList();
    }

    if (rawRoleLegacy is String && rawRoleLegacy.trim().isNotEmpty) {
      return [_roleFromString(rawRoleLegacy)];
    }

    return [UserRole.buyer];
  }

  String _phoneFromDoc(Map<String, dynamic> data) {
    final p1 = (data['phone'] as String?)?.trim();
    if (p1 != null && p1.isNotEmpty) return p1;

    final p2 = (data['phoneNumber'] as String?)?.trim();
    if (p2 != null && p2.isNotEmpty) return p2;

    return '-';
  }

  @override
  Widget build(BuildContext context) {
    final usersRef = FirebaseFirestore.instance.collection('users');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Пользователи'),
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: usersRef.orderBy('updatedAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Ошибка: ${snap.error}'),
            );
          }

          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('Пользователей нет'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final d = docs[index];
              final data = d.data();

              final uid = (data['uid'] as String?) ?? d.id;
              final phone = _phoneFromDoc(data);

              final activeRoleStr =
                  (data['activeRole'] as String?) ?? (data['role'] as String?);
              final activeRole = _roleFromString(activeRoleStr);

              final roles = _rolesFromAny(data['roles'], data['role'])
                ..sort((a, b) => a.name.compareTo(b.name));

              final rolesText = roles.map((r) => r.name).join(', ');

              final displayName =
                  (data['displayName'] as String?)?.trim().isNotEmpty == true
                      ? (data['displayName'] as String).trim()
                      : (data['name'] as String?)?.trim().isNotEmpty == true
                          ? (data['name'] as String).trim()
                          : 'Без имени';

              return Card(
                elevation: 0,
                child: ListTile(
                  title: Text(displayName),
                  subtitle: Text(
                    'UID: $uid\nТелефон: $phone\nАктивная роль: ${activeRole.name}\nРоли: $rolesText',
                  ),
                  isThreeLine: true,
                  onTap: () {
                    // MVP: пока без подробного экрана
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
