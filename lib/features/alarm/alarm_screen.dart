import 'package:bemyday/common/widgets/tile/tile_switch.dart';
import 'package:bemyday/common/widgets/tile/tiles_section.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/alarm/providers/alarm_provider.dart';
import 'package:bemyday/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AlarmScreen extends ConsumerWidget {
  const AlarmScreen({super.key});
  static const routeName = "alarm";
  static const routeUrl = "/alarm";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncPrefs = ref.watch(alarmPreferencesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myAlarm)),
      body: asyncPrefs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.profileLoadError),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(alarmPreferencesProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (prefs) => SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              left: Paddings.scaffoldH,
              right: Paddings.scaffoldH,
              top: Paddings.scaffoldV,
            ),
            child: TilesSection(
              items: [
                TileSwitch(
                  title: l10n.alarmTileDailyReminder,
                  subTitle: l10n.alarmTileDailyReminderSubtitle,
                  value: prefs.dailyReminder,
                  action: (v) => ref.read(alarmPreferencesProvider.notifier).setDailyReminder(v),
                ),
                TileSwitch(
                  title: l10n.alarmTileNewPost,
                  subTitle: l10n.alarmTileNewPostSubtitle,
                  value: prefs.newPost,
                  action: (v) => ref.read(alarmPreferencesProvider.notifier).setNewPost(v),
                ),
                TileSwitch(
                  title: l10n.alarmTileNewComment,
                  subTitle: l10n.alarmTileNewCommentSubtitle,
                  value: prefs.newComment,
                  action: (v) => ref.read(alarmPreferencesProvider.notifier).setNewComment(v),
                ),
                TileSwitch(
                  title: l10n.alarmTileNewLike,
                  subTitle: l10n.alarmTileNewLikeSubtitle,
                  value: prefs.newLike,
                  action: (v) => ref.read(alarmPreferencesProvider.notifier).setNewLike(v),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
