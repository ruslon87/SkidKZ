// lib/features/buyer/screens/buyer_profile_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BuyerProfileScreen extends StatelessWidget {
  const BuyerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<fb.User?>(
      stream: fb.FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        final user = authSnap.data;
        if (user == null) {
          return _NotLoggedIn();
        }
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snap.data?.data() ?? {};
            final buyer = (data['profiles'] as Map?)?.cast<String, dynamic>()?['buyer'] as Map<String, dynamic>? ?? {};
            final roles = (data['roles'] as List?)?.cast<String>() ?? [];
            return _ProfileBody(user: user, data: data, buyer: buyer, roles: roles);
          },
        );
      },
    );
  }
}

class _NotLoggedIn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Войдите в аккаунт', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Чтобы видеть профиль, заказы и управлять настройками',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => GoRouter.of(context).push('/login?next=%2Fbuyer%2Fprofile'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text('Войти / зарегистрироваться'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final fb.User user;
  final Map<String, dynamic> data;
  final Map<String, dynamic> buyer;
  final List<String> roles;

  const _ProfileBody({
    required this.user,
    required this.data,
    required this.buyer,
    required this.roles,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstName = buyer['firstName']?.toString() ?? '';
    final lastName = buyer['lastName']?.toString() ?? '';
    final fullName = buyer['fullName']?.toString().trim() ?? '';
    final displayName = fullName.isNotEmpty ? fullName : (firstName.isNotEmpty ? '$firstName $lastName'.trim() : data['displayName']?.toString() ?? '');
    final phone = data['phone']?.toString() ?? user.phoneNumber ?? '';
    final city = buyer['city']?.toString() ?? '';
    final street = buyer['street']?.toString() ?? '';
    final apartment = buyer['apartment']?.toString() ?? '';
    final kaspiPhone = buyer['kaspiPhone']?.toString() ?? '';
    final contactPhone = buyer['contactPhone']?.toString() ?? '';
    final isCompleted = buyer['completed'] == true;
    final isWanghong = roles.contains('wanghong');
    final isSeller = roles.contains('seller');

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => await Future.delayed(const Duration(milliseconds: 300)),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // Шапка профиля
            Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName.isNotEmpty ? displayName : 'Пользователь',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(phone, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14)),
                  const SizedBox(height: 12),
                  // Роли
                  Wrap(
                    spacing: 8,
                    children: [
                      _RoleChip(label: 'Покупатель', color: Colors.white),
                      if (isWanghong) _RoleChip(label: 'Партнер', color: Colors.amber),
                      if (isSeller) _RoleChip(label: 'Продавец', color: Colors.green.shade200),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Предупреждение если анкета не заполнена
                  if (!isCompleted) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_outlined, color: Colors.orange.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Профиль не заполнен',
                                    style: TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                const Text('Заполните данные для оформления заказов',
                                    style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => GoRouter.of(context).push('/onboarding/buyer'),
                            child: const Text('Заполнить'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Личные данные
                  _SectionCard(
                    title: 'Личные данные',
                    icon: Icons.person_outlined,
                    onEdit: () => GoRouter.of(context).push('/onboarding/buyer'),
                    children: [
                      _InfoRow(label: 'Имя', value: firstName.isNotEmpty ? firstName : '-'),
                      _InfoRow(label: 'Фамилия', value: lastName.isNotEmpty ? lastName : '-'),
                      _InfoRow(label: 'Телефон', value: phone.isNotEmpty ? phone : '-'),
                      if (contactPhone.isNotEmpty)
                        _InfoRow(label: 'Контактный тел.', value: contactPhone),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Адрес
                  _SectionCard(
                    title: 'Адрес доставки',
                    icon: Icons.location_on_outlined,
                    onEdit: () => GoRouter.of(context).push('/onboarding/buyer'),
                    children: [
                      _InfoRow(label: 'Город', value: city.isNotEmpty ? city : '-'),
                      _InfoRow(label: 'Улица и дом', value: street.isNotEmpty ? street : '-'),
                      if (apartment.isNotEmpty)
                        _InfoRow(label: 'Квартира', value: apartment),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Kaspi
                  _SectionCard(
                    title: 'Kaspi',
                    icon: Icons.account_balance_wallet_outlined,
                    onEdit: () => GoRouter.of(context).push('/onboarding/buyer'),
                    children: [
                      _InfoRow(
                        label: 'Номер Kaspi',
                        value: kaspiPhone.isNotEmpty ? kaspiPhone : 'Не указан',
                        valueColor: kaspiPhone.isEmpty ? Colors.orange : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Мои заказы
                  _ActionTile(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Мои заказы',
                    subtitle: 'История всех покупок',
                    onTap: () => GoRouter.of(context).push('/buyer/orders'),
                  ),
                  const SizedBox(height: 8),

                  // Избранное
                  _ActionTile(
                    icon: Icons.favorite_outline,
                    title: 'Избранное',
                    subtitle: 'Сохраненные товары',
                    onTap: () => GoRouter.of(context).push('/buyer/favorites'),
                  ),
                  const SizedBox(height: 8),

                  // Стать партнером
                  if (!isWanghong) ...[
                    _ActionTile(
                      icon: Icons.star_outline,
                      title: 'Стать партнером',
                      subtitle: 'Делитесь промокодами и зарабатывайте',
                      color: Colors.amber.shade700,
                      onTap: () => GoRouter.of(context).push('/become-partner'),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Стать продавцом
                  if (!isSeller) ...[
                    _ActionTile(
                      icon: Icons.storefront_outlined,
                      title: 'Открыть магазин',
                      subtitle: 'Продавайте товары на платформе',
                      color: Colors.green.shade700,
                      onTap: () => GoRouter.of(context).push('/onboarding/seller'),
                    ),
                    const SizedBox(height: 8),
                  ],

                  const SizedBox(height: 16),

                  // Выход
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await fb.FirebaseAuth.instance.signOut();
                        if (context.mounted) GoRouter.of(context).go('/buyer/home');
                      },
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text('Выйти из аккаунта', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final Color color;
  const _RoleChip({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onEdit;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.icon, this.onEdit, required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Icon(icon, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const Spacer(),
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: onEdit,
                    color: Colors.grey.shade500,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({required this.label, required this.value, this.valueColor});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;
  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.onTap, this.color});
  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: c.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: c, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
