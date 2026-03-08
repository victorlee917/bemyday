import 'package:bemyday/common/widgets/avatar/avatar_group_stack.dart';
import 'package:bemyday/common/widgets/close_app_bar_button.dart';
import 'package:bemyday/common/widgets/confirm_dialog.dart';
import 'package:bemyday/common/widgets/tile/tile_act.dart';
import 'package:bemyday/common/widgets/tile/tile_avatar.dart';
import 'package:bemyday/common/widgets/tile/tiles_section.dart';
import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/data/weekdays.dart';
import 'package:bemyday/features/group/models/group.dart';
import 'package:bemyday/features/group/providers/group_provider.dart';
import 'package:bemyday/features/group/utils.dart';
import 'package:bemyday/features/invite/invite_utils.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class PartyDetailScreen extends ConsumerStatefulWidget {
  static const routeName = "partydetail";
  static const routeUrl = "/partydetail";
  const PartyDetailScreen({super.key, this.group});

  final Group? group;

  @override
  ConsumerState<PartyDetailScreen> createState() => _PartyDetailScreenState();
}

class _PartyDetailScreenState extends ConsumerState<PartyDetailScreen> {
  late final TextEditingController _nameController;
  late final FocusNode _nameFocusNode;
  bool _isEditing = false;
  String? _userEditedName;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _nameFocusNode = FocusNode();
    _nameFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_nameFocusNode.hasFocus && _isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isEditing) {
          setState(() => _isEditing = false);
        }
      });
    }
  }

  @override
  void dispose() {
    _nameFocusNode.removeListener(_onFocusChange);
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _onCloseTap() {
    context.pop();
  }

  void _onLeaveTap() async {
    final group = widget.group;
    if (group == null) return;

    final weekdayName = weekdays[group.weekday - 1].name;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Leave My $weekdayName',
      message: '정말로 떠날 건가요?',
      cancelLabel: '취소',
      confirmLabel: '떠나기',
      isDestructive: true,
    );
    if (confirmed == true) {
      await ref.read(groupRepositoryProvider).leaveGroup(group.id);
      ref.invalidate(currentUserGroupsProvider);
      if (mounted) context.pop();
    }
  }

  void _onInviteTap() {
    showInviteSheet(
      context,
      ref,
      selectedWeekdayIndex:
          widget.group != null ? widget.group!.weekday - 1 : 0,
    );
  }

  void _onEditTap(String displayText) {
    setState(() {
      _isEditing = true;
      _nameController.text = displayText;
      _nameController.selection = TextSelection.collapsed(
        offset: displayText.length,
      );
    });
    _nameFocusNode.requestFocus();
  }

  void _onEditSubmit() async {
    final text = _nameController.text.trim();
    setState(() => _isEditing = false);
    _nameFocusNode.unfocus();

    final group = widget.group;
    if (text.isEmpty) {
      setState(() => _userEditedName = null);
      if (group != null) {
        await ref.read(groupRepositoryProvider).updateGroupName(group.id, "");
        ref.invalidate(currentUserGroupsProvider);
        ref.invalidate(groupDisplayNameProvider(group.id));
      }
      return;
    }

    setState(() => _userEditedName = text);
    if (group != null) {
      await ref.read(groupRepositoryProvider).updateGroupName(group.id, text);
      ref.invalidate(currentUserGroupsProvider);
      ref.invalidate(groupDisplayNameProvider(group.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final memberNicknamesAsync = group != null
        ? ref.watch(groupMemberNicknamesProvider(group.id))
        : null;
    final memberAvatarsAsync =
        group != null ? ref.watch(groupMemberAvatarsProvider(group.id)) : null;

    final info = groupDisplayInfo(group, memberNicknamesAsync?.valueOrNull);
    final displayText = _userEditedName ?? info.subTitle ?? info.nickname;

    final editInitialText = group?.name?.trim() ?? "";

    return GestureDetector(
      onTap: () {
        if (_isEditing) {
          _nameFocusNode.unfocus();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            group != null
                ? "About My ${weekdays[group.weekday - 1].name}"
                : "About My Monday",
          ),
          actions: [
            CloseAppBarButton(onTap: _onCloseTap),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.only(top: Paddings.profileV),
          child: Padding(
            padding: EdgeInsetsGeometry.symmetric(
              horizontal: Paddings.scaffoldH,
            ),
            child: Column(
              children: [
                group != null
                    ? AvatarGroupStack(groupId: group.id)
                    : AvatarGroupStack(groupId: ''),
                Gaps.v16,
                GestureDetector(
                  onTap: _isEditing ? null : () => _onEditTap(editInitialText),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _isEditing
                          ? SizedBox(
                              width: 200,
                              child: TextField(
                                controller: _nameController,
                                focusNode: _nameFocusNode,
                                autocorrect: false,
                                enableSuggestions: false,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                ),
                                onSubmitted: (_) => _onEditSubmit(),
                              ),
                            )
                          : Container(
                              constraints: BoxConstraints(maxWidth: 200),
                              child: Text(
                                displayText,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.fade,
                                maxLines: 1,
                                softWrap: false,
                              ),
                            ),
                      if (!_isEditing) ...[
                        Gaps.h6,
                        GestureDetector(
                          onTap: () => _onEditTap(editInitialText),
                          child: FaIcon(
                            FontAwesomeIcons.pencil,
                            size: Sizes.size10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Gaps.v24,
                Column(
                  spacing: CustomSizes.sectionGap,
                  children: [
                    TilesSection(
                      title: "Members",
                      items: [
                        ...(memberAvatarsAsync?.valueOrNull
                                ?.map(
                                  (m) => TileAvatar(
                                    nickname: m.nickname,
                                    avatarUrl: m.avatarUrl,
                                  ),
                                ) ??
                            memberNicknamesAsync?.valueOrNull
                                ?.map((n) => TileAvatar(nickname: n)) ??
                            [TileAvatar(nickname: "…")]),
                        GestureDetector(
                          onTap: _onInviteTap,
                          child: Column(
                            children: [
                              Container(
                                width: double.infinity,
                                height: Sizes.size1,
                                decoration: BoxDecoration(
                                  color: isDarkMode(context)
                                      ? CustomColors.borderDark
                                      : CustomColors.borderLight,
                                ),
                              ),
                              SizedBox(height: CustomSizes.tileSpacing),
                              Text(
                                "Invite Friends",
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    TilesSection(
                      title: "Danger Zone",
                      items: [
                        TileAct(
                          action: _onLeaveTap,
                          title: group != null
                              ? "Leave My ${weekdays[group.weekday - 1].name}"
                              : "Leave My Monday",
                          isDestructive: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
