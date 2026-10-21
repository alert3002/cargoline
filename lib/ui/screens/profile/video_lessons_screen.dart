import 'package:cargo_line_tj/core/brand_constants.dart';
import 'package:cargo_line_tj/parcel_app_theme.dart';
import 'package:cargo_line_tj/providers/app_provider.dart';
import 'package:cargo_line_tj/ui/widgets/cargo_3d_icon.dart';
import 'package:cargo_line_tj/ui/widgets/pull_refresh.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoLessonsScreen extends StatelessWidget {
  const VideoLessonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppProvider>().strings;
    final theme = Theme.of(context);
    final lessons = s.isRu
        ? [
            ('Как скопировать адрес склада', 'Pinduoduo / 1688 / Taobao'),
            ('Как добавить трек-код', 'Экран Заказы → Отправить'),
            ('Как забрать посылку в Худжанде', 'Гафуров, ДИДОР'),
          ]
        : [
            ('Чӣ гуна суроғаи анборро нусха бардорем', 'Pinduoduo / 1688 / Taobao'),
            ('Чӣ гуна трек-код илова кунем', 'Фармоишҳо → Фиристодан'),
            ('Чӣ гуна борро дар Хуҷанд гирем', 'Ғафуров, ДИДОР'),
          ];

    return Scaffold(
      appBar: cargoProfileAppBar(context, Text(s.lessons)),
      body: PullRefresh(
        onRefresh: () async {},
        child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          SoftCard(
            child: Row(
              children: [
                CargoIcon(
                  asset: CargoIconAssets.lessons,
                  icon: Icons.school_rounded,
                  size: 56,
                  gradient: Cargo3DIcon.lessons,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    s.freeCourse,
                    style: theme.textTheme.titleLarge?.copyWith(color: CargoColors.red),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...lessons.asMap().entries.map((e) {
            final i = e.key + 1;
            final lesson = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SoftCard(
                onTap: () => launchUrl(
                  Uri.parse(BrandConstants.lessonsTelegram),
                  mode: LaunchMode.externalApplication,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: CargoColors.red,
                      child: Text('$i', style: const TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(lesson.$1, style: theme.textTheme.titleMedium),
                          Text(lesson.$2, style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    const Icon(Icons.play_circle_fill_rounded, color: CargoColors.red),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
      ),
    );
  }
}
