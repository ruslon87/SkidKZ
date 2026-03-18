// lib/features/notifications/screens/notifications_screen.dart
// In-app центр уведомлений — общий для всех ролей
// Читает коллекцию notifications/{uid}/items из Firestore

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:skidkz/core/theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Необходима авторизация')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('Уведомления',
            style: TextStyle(color: AppTheme.textPrimary)),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        actions: [
          TextButton(
            onPressed: () => _markAllRead(uid),
            child: const Text('Прочитать все',
                style: TextStyle(color: AppTheme.primary, fontSize: 13)),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .doc(uid)
            .collection('items')
            .orderBy('createdAt', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_outlined,
                      size: 64, color: AppTheme.textDisabled),
                  const SizedBox(height: 16),
                  const Text('Уведомлений пока нет',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Здесь появятся уведомления о заказах,\nначислениях и обновлениях',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppTheme.textDisabled, fontSize: 13)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: AppTheme.divider,
              indent: 72,
            ),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              return _NotificationTile(
                docId: doc.id,
                uid: uid,
                data: data,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _markAllRead(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}

// ─── Тайл уведомления ────────────────────────────────────────────────────────
class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.docId,
    required this.uid,
    required this.data,
  });

  final String docId;
  final String uid;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final title = data['title']?.toString() ?? '';
    final body = data['body']?.toString() ?? '';
    final isRead = data['isRead'] == true;
    final ts = data['createdAt'];
    final createdAt = ts is Timestamp ? ts.toDate() : null;

    return InkWell(
      onTap: () => _markRead(),
      child: Container(
        color: isRead ? Colors.transparent : AppTheme.primary.withOpacity(0.05),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Иконка / индикатор непрочитанного
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.elevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _iconEmoji(title),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Текст
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: isRead
                                ? FontWeight.normal
                                : FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(createdAt),
                      style: const TextStyle(
                          color: AppTheme.textDisabled, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markRead() async {
    if (data['isRead'] == true) return;
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .doc(docId)
        .update({'isRead': true});
  }

  String _iconEmoji(String title) {
    if (title.contains('🛒') || title.contains('заказ')) return '🛒';
    if (title.contains('💰') || title.contains('Промокод')) return '💰';
    if (title.contains('✅') || title.contains('подтверждён')) return '✅';
    if (title.contains('🚚') || title.contains('отправлен')) return '🚚';
    if (title.contains('📦') || title.contains('доставлен')) return '📦';
    if (title.contains('❌') || title.contains('отменён')) return '❌';
    if (title.contains('🎉') || title.contains('выполнен')) return '🎉';
    return '🔔';
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Только что';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин. назад';
    if (diff.inHours < 24) return '${diff.inHours} ч. назад';
    if (diff.inDays < 7) return '${diff.inDays} дн. назад';
    return '${dt.day}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}

// ─── Бейдж непрочитанных уведомлений ─────────────────────────────────────────
class NotificationBadge extends StatelessWidget {
  const NotificationBadge({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return child;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .doc(uid)
          .collection('items')
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        if (count == 0) return child;

        return Badge(
          label: Text(count > 99 ? '99+' : '$count',
              style: const TextStyle(fontSize: 10)),
          backgroundColor: Colors.red,
          child: child,
        );
      },
    );
  }
}
