import 'package:bemyday/common/widgets/tile/tile_act.dart';
import 'package:bemyday/common/widgets/tile/tile_switch.dart';
import 'package:bemyday/common/widgets/tile/tiles_section.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/alarm/providers/alarm_provider.dart';
import 'package:bemyday/generated/l10n/app_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class AlarmScreen extends ConsumerStatefulWidget {
  const AlarmScreen({super.key});
  static const routeName = "alarm";
  static const routeUrl = "/alarm";

  @override
  ConsumerState<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends ConsumerState<AlarmScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(notificationPermissionProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final asyncPrefs = ref.watch(alarmPreferencesProvider);
    final permissionAsync = ref.watch(notificationPermissionProvider);

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
        data: (prefs) {
          final notificationsDisabled =
              permissionAsync.valueOrNull == AuthorizationStatus.denied ||
              permissionAsync.valueOrNull == AuthorizationStatus.notDetermined;

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                left: Paddings.scaffoldH,
                right: Paddings.scaffoldH,
                top: Paddings.scaffoldV,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (notificationsDisabled)
                    TilesSection(
                      items: [
                        TileAct(
                          title: l10n.alarmEnableNotifications,
                          subTitle: l10n.alarmOpenSettings,
                          action: () => openAppSettings(),
                        ),
                      ],
                    ),
                  if (!notificationsDisabled)
                    TilesSection(
                      items: [
                        TileSwitch(
                          title: l10n.alarmTileDailyReminder,
                          // subTitle: l10n.alarmTileDailyReminderSubtitle,
                          value: prefs.dailyReminder,
                          action: (v) => ref
                              .read(alarmPreferencesProvider.notifier)
                              .setDailyReminder(v),
                        ),
                        TileSwitch(
                          title: l10n.alarmTileNewPost,
                          // subTitle: l10n.alarmTileNewPostSubtitle,
                          value: prefs.newPost,
                          action: (v) => ref
                              .read(alarmPreferencesProvider.notifier)
                              .setNewPost(v),
                        ),
                        TileSwitch(
                          title: l10n.alarmTileNewComment,
                          // subTitle: l10n.alarmTileNewCommentSubtitle,
                          value: prefs.newComment,
                          action: (v) => ref
                              .read(alarmPreferencesProvider.notifier)
                              .setNewComment(v),
                        ),
                        TileSwitch(
                          title: l10n.alarmTileNewLike,
                          // subTitle: l10n.alarmTileNewLikeSubtitle,
                          value: prefs.newLike,
                          action: (v) => ref
                              .read(alarmPreferencesProvider.notifier)
                              .setNewLike(v),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
