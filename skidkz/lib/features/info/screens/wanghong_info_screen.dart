import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skidkz/core/theme/app_theme.dart';

class WanghongInfoScreen extends StatelessWidget {
  const WanghongInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.primary,
            elevation: 0,
            title: const Text(
              'Подключиться как ванхун',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroCard(
                    title: 'Ванхун в SkidKZ',
                    subtitle:
                        'Получайте промокоды и зарабатывайте с покупок, которые сделаны по вашим рекомендациям.',
                    icon: Icons.campaign_outlined,
                  ),
                  const SizedBox(height: 14),

                  _Block(
                    title: 'Кто такой ванхун?',
                    text:
                        'Ванхун — это автор/инфлюенсер, который делится товарами и получает доход по промокодам.',
                  ),
                  const SizedBox(height: 12),

                  _Block(
                    title: 'Как заработать',
                    bullets: const [
                      'Получаете промокод',
                      'Делитесь ссылкой/кодом в соцсетях',
                      'Покупатели применяют промокод',
                      'Вы получаете начисления по условиям программы',
                    ],
                  ),
                  const SizedBox(height: 12),

                  _Block(
                    title: 'Важно',
                    bullets: const [
                      'Не вводить покупателей в заблуждение',
                      'Не публиковать запрещённые товары',
                      'Соблюдать правила платформы и законодательства',
                    ],
                  ),
                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        context.go('/cabinet');
                      },
                      child: const Text(
                        'Начать',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Center(
                    child: TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Позже'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(color: Colors.black54, height: 1.25)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  final String title;
  final String? text;
  final List<String>? bullets;

  const _Block({required this.title, this.text, this.bullets});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          if (text != null)
            Text(text!, style: const TextStyle(height: 1.35)),
          if (bullets != null) ...[
            for (final b in bullets!) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(height: 1.35)),
                  Expanded(child: Text(b, style: const TextStyle(height: 1.35))),
                ],
              ),
              const SizedBox(height: 4),
            ]
          ],
        ],
      ),
    );
  }
}
