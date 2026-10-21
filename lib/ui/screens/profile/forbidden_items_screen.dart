import 'package:cargo_line_tj/parcel_app_theme.dart';
import 'package:cargo_line_tj/ui/widgets/pull_refresh.dart';
import 'package:flutter/material.dart';

class ForbiddenItemsScreen extends StatelessWidget {
  const ForbiddenItemsScreen({super.key});

  static const _items = [
    'Оружие, боеприпасы, взрывчатые вещества',
    'Наркотические и психотропные вещества',
    'Легковоспламеняющиеся жидкости и газы',
    'Аккумуляторы / power bank сверх норм авиаперевозки',
    'Живые животные и растения без разрешения',
    'Деньги, драгоценности без декларации',
    'Поддельные бренды и контрафакт',
    'Продукты с коротким сроком годности / скоропорт',
    'Любые товары, запрещённые законодательством РТ и КНР',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: cargoProfileAppBar(context, const Text('Запрещённые товары')),
      body: PullRefresh(
        onRefresh: () async {},
        child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          SoftCard(
            child: Text(
              'Cargo Line TJ не принимает к перевозке:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 12),
          ..._items.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SoftCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.block, color: CargoColors.accent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(t)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
