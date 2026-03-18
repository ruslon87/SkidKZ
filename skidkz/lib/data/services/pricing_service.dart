// lib/data/services/pricing_service.dart
//
// PricingService — ядро системы ценообразования SkidKZ.
//
// Логика:
//   1. Продавец задаёт две цены: costPrice (себестоимость) и retailPrice (витрина).
//   2. Маржа = retailPrice - costPrice.
//   3. Для каждого диапазона розничной цены администратор задаёт минимальный %
//      маржи от retailPrice (например: 0–20 000 ₸ → мин. 15%).
//   4. Если маржа < минимально допустимой — товар не проходит валидацию.
//   5. При применении промокода маржа делится:
//        wanghong получает wanghongPercent% от маржи,
//        платформа оставляет себе (100 - wanghongPercent)%.

import 'package:cloud_firestore/cloud_firestore.dart';

/// Один диапазон ценового порога.
///
/// [maxPrice] — верхняя граница диапазона (₸).
///   Для последнего (неограниченного) диапазона используйте double.infinity.
/// [minMarginPercent] — минимальный % маржи от retailPrice.
class PricingTier {
  /// Верхняя граница диапазона (₸). double.infinity = без ограничения.
  final double maxPrice;

  /// Минимальный % маржи от розничной цены (0–100).
  final double minMarginPercent;

  const PricingTier({
    required this.maxPrice,
    required this.minMarginPercent,
  });

  factory PricingTier.fromMap(Map<String, dynamic> m) {
    final max = m['maxPrice'];
    return PricingTier(
      maxPrice: max == null ? double.infinity : (max as num).toDouble(),
      minMarginPercent: ((m['minMarginPercent'] as num?) ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'maxPrice': maxPrice == double.infinity ? null : maxPrice,
        'minMarginPercent': minMarginPercent,
      };

  /// Человекочитаемое название диапазона.
  String get label {
    if (maxPrice == double.infinity) return 'Свыше';
    return 'До ${_fmt(maxPrice)} ₸';
  }

  static String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(0)} млн';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)} тыс';
    return v.toStringAsFixed(0);
  }
}

/// Результат валидации цен.
class PricingValidationResult {
  final bool isValid;
  final String? errorMessage;

  /// Минимально допустимая маржа (₸) для данного диапазона.
  final int minMarginRequired;

  /// Фактическая маржа (₸).
  final int actualMargin;

  /// Применённый диапазон.
  final PricingTier? tier;

  const PricingValidationResult({
    required this.isValid,
    required this.minMarginRequired,
    required this.actualMargin,
    this.errorMessage,
    this.tier,
  });
}

/// Результат расчёта распределения маржи.
class MarginSplit {
  /// Сумма (₸), которую получает партнёр (Wanghong).
  final double wanghongAmount;

  /// Сумма (₸), которую получает платформа.
  final double platformAmount;

  /// Общая маржа (₸).
  final int totalMargin;

  /// % партнёра (0–100).
  final double wanghongPercent;

  const MarginSplit({
    required this.wanghongAmount,
    required this.platformAmount,
    required this.totalMargin,
    required this.wanghongPercent,
  });

  @override
  String toString() =>
      'MarginSplit(total=$totalMargin ₸, wanghong=${wanghongAmount.toStringAsFixed(2)} ₸ ($wanghongPercent%), platform=${platformAmount.toStringAsFixed(2)} ₸)';
}

class PricingService {
  static final _db = FirebaseFirestore.instance;

  // ─────────────────────────────────────────────────────────────────────────
  // Дефолтные пороги (используются, если в Firestore нет настроек)
  // ─────────────────────────────────────────────────────────────────────────
  static const List<PricingTier> _defaultTiers = [
    PricingTier(maxPrice: 20000, minMarginPercent: 20),
    PricingTier(maxPrice: 50000, minMarginPercent: 15),
    PricingTier(maxPrice: 100000, minMarginPercent: 12),
    PricingTier(maxPrice: 300000, minMarginPercent: 10),
    PricingTier(maxPrice: double.infinity, minMarginPercent: 8),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // Загрузка / сохранение порогов из Firestore
  // ─────────────────────────────────────────────────────────────────────────

  /// Загружает актуальные ценовые пороги из Firestore.
  /// При отсутствии документа возвращает [_defaultTiers].
  static Future<List<PricingTier>> loadTiers() async {
    try {
      final doc = await _db.collection('settings').doc('pricingTiers').get();
      final data = doc.data();
      if (data == null) return _defaultTiers;

      final raw = data['tiers'];
      if (raw is! List || raw.isEmpty) return _defaultTiers;

      final tiers = raw
          .whereType<Map>()
          .map((e) => PricingTier.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      return tiers.isEmpty ? _defaultTiers : tiers;
    } catch (_) {
      return _defaultTiers;
    }
  }

  /// Сохраняет ценовые пороги в Firestore (только для администратора).
  static Future<void> saveTiers(List<PricingTier> tiers) async {
    await _db.collection('settings').doc('pricingTiers').set({
      'tiers': tiers.map((t) => t.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Основная логика
  // ─────────────────────────────────────────────────────────────────────────

  /// Находит подходящий диапазон для [retailPrice].
  ///
  /// Диапазоны должны быть отсортированы по [PricingTier.maxPrice] по возрастанию.
  static PricingTier? findTier(int retailPrice, List<PricingTier> tiers) {
    final sorted = [...tiers]
      ..sort((a, b) => a.maxPrice.compareTo(b.maxPrice));

    for (final tier in sorted) {
      if (retailPrice <= tier.maxPrice) return tier;
    }
    return sorted.isNotEmpty ? sorted.last : null;
  }

  /// Вычисляет минимально допустимую маржу (₸) для [retailPrice] и [tiers].
  static int minMarginRequired(int retailPrice, List<PricingTier> tiers) {
    final tier = findTier(retailPrice, tiers);
    if (tier == null) return 0;
    return (retailPrice * tier.minMarginPercent / 100).ceil();
  }

  /// Валидирует пару цен (costPrice, retailPrice) по заданным порогам.
  ///
  /// Возвращает [PricingValidationResult] с флагом [isValid] и описанием ошибки.
  static PricingValidationResult validate({
    required int costPrice,
    required int retailPrice,
    required List<PricingTier> tiers,
  }) {
    if (retailPrice <= 0) {
      return const PricingValidationResult(
        isValid: false,
        errorMessage: 'Розничная цена должна быть больше нуля',
        minMarginRequired: 0,
        actualMargin: 0,
      );
    }

    if (costPrice < 0) {
      return const PricingValidationResult(
        isValid: false,
        errorMessage: 'Себестоимость не может быть отрицательной',
        minMarginRequired: 0,
        actualMargin: 0,
      );
    }

    if (costPrice >= retailPrice) {
      return PricingValidationResult(
        isValid: false,
        errorMessage: 'Розничная цена должна быть выше себестоимости',
        minMarginRequired: 0,
        actualMargin: retailPrice - costPrice,
      );
    }

    final tier = findTier(retailPrice, tiers);
    final minMargin = minMarginRequired(retailPrice, tiers);
    final actualMargin = retailPrice - costPrice;

    if (actualMargin < minMargin) {
      final pct = tier?.minMarginPercent.toStringAsFixed(0) ?? '?';
      return PricingValidationResult(
        isValid: false,
        errorMessage:
            'Маржа слишком мала. Для диапазона «${tier?.label ?? ""}» '
            'минимальная маржа — $pct% от розничной цены '
            '($minMargin ₸). Текущая: $actualMargin ₸.',
        minMarginRequired: minMargin,
        actualMargin: actualMargin,
        tier: tier,
      );
    }

    return PricingValidationResult(
      isValid: true,
      minMarginRequired: minMargin,
      actualMargin: actualMargin,
      tier: tier,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Распределение маржи
  // ─────────────────────────────────────────────────────────────────────────

  /// Рассчитывает распределение маржи между партнёром и платформой.
  ///
  /// [margin] — общая маржа (₸) = retailPrice - costPrice.
  /// [wanghongPercent] — % партнёра (0–100), задаётся администратором.
  ///
  /// Если промокод не применён (нет партнёра), передайте wanghongPercent = 0.
  static MarginSplit splitMargin({
    required int margin,
    required double wanghongPercent,
  }) {
    assert(wanghongPercent >= 0 && wanghongPercent <= 100,
        'wanghongPercent должен быть в диапазоне 0–100');

    final wanghongAmount = margin * wanghongPercent / 100;
    final platformAmount = margin - wanghongAmount;

    return MarginSplit(
      wanghongAmount: wanghongAmount,
      platformAmount: platformAmount,
      totalMargin: margin,
      wanghongPercent: wanghongPercent,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Вспомогательные методы для UI
  // ─────────────────────────────────────────────────────────────────────────

  /// Возвращает строку с описанием минимальной маржи для [retailPrice].
  ///
  /// Пример: «Мин. маржа: 15% (3 000 ₸)»
  static String marginHint(int retailPrice, List<PricingTier> tiers) {
    final tier = findTier(retailPrice, tiers);
    if (tier == null) return '';
    final minMargin = (retailPrice * tier.minMarginPercent / 100).ceil();
    return 'Мин. маржа: ${tier.minMarginPercent.toStringAsFixed(0)}% ($minMargin ₸)';
  }

  /// Возвращает % маржи от розничной цены (для отображения).
  static double marginPercent(int costPrice, int retailPrice) {
    if (retailPrice <= 0) return 0;
    return (retailPrice - costPrice) / retailPrice * 100;
  }
}
