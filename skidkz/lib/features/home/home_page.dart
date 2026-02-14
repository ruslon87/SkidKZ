// lib/features/home/home_page.dart
import 'package:flutter/material.dart';
import 'package:skidkz/core/theme/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        const SizedBox(height: 8),
        Text(
          'Витрина',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        Text(
          'Найдите товар по названию или категории',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        const SizedBox(height: 14),

        // Search
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.r16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: AppColors.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Поиск...',
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.tune, color: AppColors.textMuted),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Placeholder block
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.r16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.image_outlined, color: AppColors.textDisabled),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Товары появятся здесь',
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Подключи загрузку товаров из Firestore и отрисовку карточек.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
