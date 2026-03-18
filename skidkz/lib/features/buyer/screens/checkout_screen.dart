// lib/features/buyer/screens/checkout_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:skidkz/core/theme/app_theme.dart';
import 'package:skidkz/data/order_repository.dart';
import 'package:skidkz/data/services/pricing_service.dart';
import 'package:skidkz/features/buyer/providers/cart_provider.dart';
import 'package:skidkz/core/router/app_router.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _promoController = TextEditingController();
  bool _isLoading = false;

  // Состояние промокода
  bool _promoChecking = false;
  String? _promoError;
  String? _promoOwnerName;
  double? _promoWanghongPercent;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  String _formatMoney(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final pos = s.length - i;
      buf.write(s[i]);
      if (pos > 1 && pos % 3 == 1) buf.write(' ');
    }
    return '${buf.toString()} ₸';
  }

  Future<void> _checkPromo() async {
    final code = _promoController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _promoError = null;
        _promoOwnerName = null;
        _promoWanghongPercent = null;
      });
      return;
    }

    setState(() {
      _promoChecking = true;
      _promoError = null;
      _promoOwnerName = null;
      _promoWanghongPercent = null;
    });

    try {
      final snap = await FirebaseFirestore.instance
          .collection('promoCodes')
          .doc(code)
          .get();

      if (!snap.exists || snap.data()?['isActive'] == false) {
        setState(() {
          _promoError = 'Промокод не найден или неактивен';
          _promoChecking = false;
        });
        return;
      }

      final data = snap.data()!;
      final ownerUid = data['ownerUid']?.toString();
      final ownerName = data['ownerName']?.toString() ?? 'Партнёр';

      double wPct = 30.0;
      if (ownerUid != null) {
        final ownerSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(ownerUid)
            .get();
        final ownerData = ownerSnap.data() ?? {};
        final profilesRaw = ownerData['profiles'];
        final profiles = (profilesRaw is Map)
            ? profilesRaw.cast<String, dynamic>()
            : <String, dynamic>{};
        final wanghongRaw = profiles['wanghong'];
        final wanghong = (wanghongRaw is Map)
            ? wanghongRaw.cast<String, dynamic>()
            : <String, dynamic>{};
        wPct = ((wanghong['wanghongPercent'] as num?) ?? 30.0).toDouble();
      }

      setState(() {
        _promoOwnerName = ownerName;
        _promoWanghongPercent = wPct;
        _promoChecking = false;
      });
    } catch (e) {
      setState(() {
        _promoError = 'Ошибка проверки промокода';
        _promoChecking = false;
      });
    }
  }

  Future<void> _submitOrder() async {
    final cart = ref.read(cartProvider);
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Корзина пуста')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final orderRepo = OrderRepository(
        ref.read(firestoreProvider),
        ref.read(firebaseAuthProvider),
      );

      final promoCode = _promoController.text.trim().isEmpty
          ? null
          : _promoController.text.trim();

      final orderId = await orderRepo.createOrder(
        items: cart.items,
        storeId: 'default-store',
        promoCode: promoCode,
      );

      if (!mounted) return;

      ref.read(cartProvider.notifier).clearCart();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Заказ создан: $orderId'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) context.go('/buyer/profile/orders');
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    // Рассчитываем распределение маржи, если промокод применён
    MarginSplit? split;
    if (_promoWanghongPercent != null && cart.totalMargin > 0) {
      split = PricingService.splitMargin(
        margin: cart.totalMargin,
        wanghongPercent: _promoWanghongPercent!,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Оформление заказа'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Товары ────────────────────────────────────────────────
            Text(
              'Товары в заказе',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...cart.items.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.divider),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.qty} шт. × ${_formatMoney(item.retailPrice)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatMoney(item.totalPrice),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),

            // ── Промокод ──────────────────────────────────────────────
            Text(
              'Промокод партнёра',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Введите промокод партнёра, который вас пригласил',
              style: TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoController,
                    enabled: !_isLoading,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (_) {
                      // Сбрасываем результат при изменении
                      if (_promoOwnerName != null || _promoError != null) {
                        setState(() {
                          _promoOwnerName = null;
                          _promoError = null;
                          _promoWanghongPercent = null;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Например: SKIDALI1234',
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: AppTheme.primary, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _promoChecking ? null : _checkPromo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _promoChecking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Проверить'),
                ),
              ],
            ),

            // Результат проверки промокода
            if (_promoError != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.shade400, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_promoError!,
                          style: TextStyle(
                              color: Colors.red.shade700, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
            if (_promoOwnerName != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: Colors.green.shade600, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Промокод партнёра «$_promoOwnerName» применён',
                        style: TextStyle(
                            color: Colors.green.shade700, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // ── Итоги ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.elevated,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryRow(
                    label: 'Сумма товаров:',
                    value: _formatMoney(cart.totalPrice),
                  ),
                  const SizedBox(height: 8),

                  // Если промокод применён — показываем распределение маржи
                  if (split != null) ...[
                    _SummaryRow(
                      label: 'Маржа (всего):',
                      value: _formatMoney(cart.totalMargin),
                      valueColor: AppTheme.primary,
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Column(
                        children: [
                          _SummaryRow(
                            label:
                                '  └ Партнёру (${split.wanghongPercent.toStringAsFixed(0)}%):',
                            value:
                                '${split.wanghongAmount.toStringAsFixed(0)} ₸',
                            valueColor: Colors.purple,
                            fontSize: 12,
                          ),
                          const SizedBox(height: 2),
                          _SummaryRow(
                            label:
                                '  └ Платформе (${(100 - split.wanghongPercent).toStringAsFixed(0)}%):',
                            value:
                                '${split.platformAmount.toStringAsFixed(0)} ₸',
                            valueColor: AppTheme.primary,
                            fontSize: 12,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    _SummaryRow(
                      label: 'Маржа:',
                      value: _formatMoney(cart.totalMargin),
                      valueColor: AppTheme.primary,
                    ),
                  ],

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1),
                  ),
                  _SummaryRow(
                    label: 'Итого:',
                    value: _formatMoney(cart.totalPrice),
                    labelStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800),
                    valueStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Кнопка оформления ─────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Создать заказ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final double fontSize;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.fontSize = 14,
    this.labelStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: labelStyle ??
              TextStyle(
                  color: AppTheme.textSecondary, fontSize: fontSize),
        ),
        Text(
          value,
          style: valueStyle ??
              TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
        ),
      ],
    );
  }
}
