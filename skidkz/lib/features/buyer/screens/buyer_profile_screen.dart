import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BuyerProfileScreen extends StatelessWidget {
  const BuyerProfileScreen({super.key});

  Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Не авторизован'));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userStream(user.uid),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snap.data!.data();
        final buyer = data?['profiles']?['buyer'];

        if (buyer == null) {
          return const Center(child: Text('Профиль не заполнен'));
        }

        final name = buyer['fullName'] ?? '—';
        final phone = buyer['contactPhone'] ?? '—';
        final address =
            '${buyer['city']}, ${buyer['street']} ${buyer['house']}'
            '${buyer['apartment'] != null && buyer['apartment'] != '' ? ', кв. ${buyer['apartment']}' : ''}';

        return Scaffold(
          appBar: AppBar(title: const Text('Профиль')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Row(title: 'Имя', value: name),
              _Row(title: 'Телефон', value: phone),
              _Row(title: 'Адрес', value: address),
              if ((buyer['comment'] ?? '').toString().isNotEmpty)
                _Row(
                  title: 'Комментарий',
                  value: buyer['comment'],
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  context.push('/buyer/onboarding?next=/buyer/profile');
                },
                child: const Text('Редактировать данные'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  final String title;
  final String value;

  const _Row({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(value,
              style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
