import 'package:cargo_line_tj/parcel_app_theme.dart';
import 'package:cargo_line_tj/providers/app_provider.dart';
import 'package:cargo_line_tj/providers/parcel_provider.dart';
import 'package:cargo_line_tj/ui/widgets/animated_widgets.dart';
import 'package:cargo_line_tj/ui/widgets/empty_state.dart';
import 'package:cargo_line_tj/ui/widgets/cargo_3d_icon.dart';
import 'package:cargo_line_tj/ui/widgets/pull_refresh.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final List<_SupportMsg> _support = [];

  @override
  void initState() {
    super.initState();
    _loadSupport();
  }

  Future<void> _loadSupport() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('support_messages') ?? [];
    final now = DateTime.now();
    final kept = <_SupportMsg>[];
    for (final line in raw) {
      final parts = line.split('|');
      if (parts.length < 3) continue;
      final created = DateTime.tryParse(parts[0]);
      if (created == null) continue;
      if (now.difference(created).inDays >= 2) continue;
      kept.add(_SupportMsg(
        id: parts[1],
        text: parts[2],
        created: created,
        fromAdmin: parts.length > 3 && parts[3] == 'admin',
      ));
    }
    if (mounted) setState(() => _support..clear()..addAll(kept));
    await prefs.setStringList(
      'support_messages',
      kept.map((m) => m.toStorage()).toList(),
    );
  }

  Future<void> _saveSupport() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'support_messages',
      _support.map((m) => m.toStorage()).toList(),
    );
  }

  Future<void> _requestSupport() async {
    final s = context.read<AppProvider>().strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.isRu ? 'Поддержка' : 'Дастгирӣ'),
        content: Text(
          s.isRu
              ? 'Оператор свяжется с вами в ближайшее время.'
              : 'Оператор дар наздикӣ бо шумо тамос мегирад.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.isRu ? 'Отмена' : 'Бекор'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.isRu ? 'Отправить' : 'Фиристодан'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _support.insert(
        0,
        _SupportMsg(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: s.isRu
              ? 'Запрос в поддержку отправлен. Ожидайте ответа.'
              : 'Дархост ба дастгирӣ фиристода шуд. Интизори ҷавоб бошед.',
          created: DateTime.now(),
        ),
      );
    });
    await _saveSupport();
  }

  void _deleteSupport(String id) {
    setState(() => _support.removeWhere((m) => m.id == id));
    _saveSupport();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppProvider>().strings;
    final provider = context.watch<ParcelProvider>();
    final notes = provider.notifications;
    final theme = Theme.of(context);

    return SafeArea(
      bottom: false,
      child: PullRefresh(
        onRefresh: () => context.read<ParcelProvider>().syncFromServer(),
        child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(s.messagesTitle, style: theme.textTheme.displayLarge),
                  ),
                  if (provider.unreadCount > 0)
                    TextButton(
                      onPressed: provider.markAllNotificationsRead,
                      child: Text(s.isRu ? 'Прочитать все' : 'Ҳамаро хонед'),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: SoftCard(
                onTap: _requestSupport,
                child: Row(
                  children: [
                    CargoIcon(
                      asset: CargoIconAssets.support,
                      icon: Icons.headset_mic_rounded,
                      size: 48,
                      gradient: Cargo3DIcon.support,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.isRu ? 'Написать в поддержку' : 'Ба дастгирӣ навиштан',
                            style: theme.textTheme.titleMedium,
                          ),
                          Text(
                            s.isRu
                                ? 'Оператор свяжется с вами в ближайшее время'
                                : 'Оператор дар наздикӣ тамос мегирад',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: CargoColors.textSecondary),
                  ],
                ),
              ),
            ),
          ),
          if (_support.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              sliver: SliverList.separated(
                itemCount: _support.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final m = _support[i];
                  return Dismissible(
                    key: ValueKey(m.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => _deleteSupport(m.id),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: CargoColors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete_outline, color: CargoColors.red),
                    ),
                    child: SoftCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            m.fromAdmin
                                ? Icons.support_agent_rounded
                                : Icons.chat_bubble_outline_rounded,
                            color: CargoColors.red,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(m.text, style: theme.textTheme.bodyLarge),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          if (notes.isEmpty && _support.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.mark_email_unread_outlined,
                iconAsset: CargoIconAssets.navMessages,
                title: s.noMessages,
                subtitle: s.isRu
                    ? 'Новости от администрации и уведомления о посылках появятся здесь'
                    : 'Хабарҳо ва огоҳиҳо дар ин ҷо пайдо мешаванд',
              ),
            )
          else if (notes.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              sliver: SliverList.separated(
                itemCount: notes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final n = notes[i];
                  return FadeSlideIn(
                    delay: Duration(milliseconds: 40 * i.clamp(0, 8)),
                    child: PressableScale(
                      onTap: () => provider.markNotificationRead(n.id),
                      child: SoftCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: CargoColors.red.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.campaign_rounded,
                                  color: CargoColors.red),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          n.title,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight:
                                                n.read ? FontWeight.w500 : FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      if (!n.read)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: CargoColors.red,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(n.body, style: theme.textTheme.bodyMedium),
                                  if (n.trackCode != null) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      n.trackCode!,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: CargoColors.red,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      ),
    );
  }
}

class _SupportMsg {
  _SupportMsg({
    required this.id,
    required this.text,
    required this.created,
    this.fromAdmin = false,
  });

  final String id;
  final String text;
  final DateTime created;
  final bool fromAdmin;

  String toStorage() =>
      '${created.toIso8601String()}|$id|$text|${fromAdmin ? 'admin' : 'user'}';
}
