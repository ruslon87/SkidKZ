import 'package:flutter/material.dart';
import 'package:skidkz/data/models/user_model.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // We don't have a UsersNotifier exposed for list, so we'll use the initial list for demo + static
    // In a real app, we'd have a usersProvider. 
    // For this prototype, I'll just show the static list defined in mock_database.dart
    // But since it's private, I'll Mock it here or expose it. 
    // I'll create a local list for demo.
    
    final users = [
      User(id: 'u1', name: 'Buyer John', phoneNumber: '7771112233', role: UserRole.buyer),
      User(id: 'u2', name: 'Wanghong Ivan', phoneNumber: '7774445566', role: UserRole.wanghong, promoCode: 'IVAN25'),
      User(id: 'u3', name: 'Seller Shop', phoneNumber: '7777778899', role: UserRole.seller),
      User(id: 'u4', name: 'Admin Boss', phoneNumber: '7770000000', role: UserRole.admin),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.2),
                child: Icon(_getRoleIcon(user.role), color: _getRoleColor(user.role)),
              ),
              title: Text(user.name),
              subtitle: Text('${user.phoneNumber} • ${user.role.name.toUpperCase()}'),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'block', child: Text('Block User')),
                  const PopupMenuItem(value: 'reset', child: Text('Reset Password')),
                ],
                onSelected: (value) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action $value simulated')));
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.buyer: return Colors.blue;
      case UserRole.wanghong: return Colors.purple;
      case UserRole.seller: return Colors.orange;
      case UserRole.admin: return Colors.red;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.buyer: return Icons.shopping_bag;
      case UserRole.wanghong: return Icons.campaign;
      case UserRole.seller: return Icons.storefront;
      case UserRole.admin: return Icons.security;
    }
  }
}
