import 'package:bemyday/common/widgets/avatar/avatar_group_stack.dart';
import 'package:bemyday/common/widgets/avatar/avatar_package.dart';
import 'package:bemyday/common/widgets/sheet/sheet_weekday_picker.dart';
import 'package:bemyday/features/group/utils.dart';
import 'package:bemyday/features/post/models/post.dart';
import 'package:bemyday/features/post/post_screen.dart';
import 'package:bemyday/features/post/providers/post_provider.dart';
import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/data/weekdays.dart';
import 'package:bemyday/features/group/models/group.dart';
import 'package:bemyday/features/group/providers/group_provider.dart';
import 'package:bemyday/features/invite/invite_utils.dart';
import 'package:bemyday/features/posting/viewmodels/posting_viewmodel.dart';
import 'dart:io';

import 'package:bemyday/generated/l10n/app_localizations.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:photo_manager/photo_manager.dart';

class PostingDecorateScreen extends ConsumerStatefulWidget {
  final AssetEntity asset;
  final Uint8List? thumbnail;
  final int? selectedWeekdayIndex;
  final bool replaceOnPostSuccess;

  /// [PostScreen]이 특정 `weekIndex`로 열려 있을 때 포스팅 후 동일 주 목록으로 복귀.
  final int? postScreenWeekIndex;

  const PostingDecorateScreen({
    super.key,
    required this.asset,
    this.thumbnail,
    this.selectedWeekdayIndex,
    this.replaceOnPostSuccess = false,
    this.postScreenWeekIndex,
  });

  static const routeName = "postingDecorate";
  static const routeUrl = "/posting/decorate";

  @override
  ConsumerState<PostingDecorateScreen> createState() =>
      _PostingDecorateScreenState();
}

class _PostingDecorateScreenState extends ConsumerState<PostingDecorateScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  late String _selectedWeekday;
  int? _selectedWeekdayIndex;
  bool _isPosting = false;
  bool _hasScheduledRedirect = false;
  bool _hasSyncedWeekdayFromGroups = false;
  Uint8List? _highResImage;

  int _currentWeekdayIndex(List<Group> groups) {
    return _selectedWeekdayIndex ??
        effectivePostingWeekdayIndex(groups, widget.selectedWeekdayIndex);
  }

  @override
  void initState() {
    super.initState();
    _selectedWeekday =
        weekdays[widget.selectedWeekdayIndex ??
                (DateTime.now().weekday - 1) % 7]
            .name;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    // Hero 애니메이션이 끝난 후 UI 요소들 fade in
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _animationController.forward();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHighResImage());
  }

  Future<void> _loadHighResImage() async {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    var w = (size.width * pixelRatio).round();
    var h = (size.height * pixelRatio).round();
    const maxEdge = 2048;
    if (w > maxEdge || h > maxEdge) {
      final scale = maxEdge / (w > h ? w : h);
      w = (w * scale).round();
      h = (h * scale).round();
    }
    try {
      final data =
          await widget.asset.thumbnailDataWithSize(ThumbnailSize(w, h));
      if (data != null && mounted) {
        setState(() => _highResImage = data);
      }
    } on PlatformException catch (_) {
      if (mounted) setState(() => _highResImage = widget.thumbnail);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onCloseTap() {
    _animationController.value = 0;
    Navigator.of(context).pop();
  }

  void _onWeekdayTap(List<Group> groups) {
    final items = buildWeekdayPickerItems(groups, postingOnly: true);
    showWeekdayPicker(
      context: context,
      items: items,
      isDarkOnly: false,
      displayMode: WeekdayPickerDisplayMode.posting,
      onWeekdaySelected: (index) {
        setState(() {
          _selectedWeekdayIndex = index;
          _selectedWeekday = weekdays[index].name;
        });
      },
    );
  }

  Future<void> _onPostTap(List<Group> groups) async {
    if (_isPosting) return;
    if (groups.isEmpty) return;

    final weekdayIndex = _currentWeekdayIndex(groups);
    final group = groupForWeekday(groups, weekdayIndex);
    if (group == null) return;

    setState(() => _isPosting = true);
    File? file;
    try {
      file ??= await widget.asset.loadFile(isOrigin: false);
      file ??= await widget.asset.loadFile(isOrigin: true);
    } on PlatformException catch (e) {
      final isIcloudError = e.code.contains('1006') ||
          e.code.contains('CloudPhotoLibraryErrorDomain') ||
          (e.message?.contains('CloudPhotoLibraryErrorDomain') ?? false);
      if (isIcloudError && mounted) {
        setState(() => _isPosting = false);
        showAppSnackBar(
          context,
          AppLocalizations.of(context)!.postingPhotoLoadFailed,
        );
        return;
      }
      rethrow;
    }
    if (file == null || !mounted) {
      if (mounted) setState(() => _isPosting = false);
      return;
    }

    try {
      final newPostId = await ref.read(postingViewModelProvider).createPost(
            group,
            file,
          );
      if (mounted) {
        ref.invalidate(hasCurrentWeekPostsProvider(group));
        ref.invalidate(currentWeekPostsProvider(group));
        ref.invalidate(weekPostSummariesProvider(group));
        ref.invalidate(currentUserGroupsProvider);
        final weekIdx = widget.postScreenWeekIndex;
        if (weekIdx != null) {
          ref.invalidate(
            weekPostsProvider((group: group, weekIndex: weekIdx)),
          );
        }
        // 최신 목록을 먼저 가져와야 PostScreen이 올바른 index / focusPostId 사용
        await ref
            .read(currentWeekPostsProvider(group).future)
            .timeout(const Duration(seconds: 5), onTimeout: () => <Post>[]);
        if (weekIdx != null) {
          await ref
              .read(
                weekPostsProvider((group: group, weekIndex: weekIdx)).future,
              )
              .timeout(const Duration(seconds: 5), onTimeout: () => <Post>[]);
        }
        if (!mounted) return;
        // 첫 pop 이후 Decorate context가 무효화될 수 있으므로 Navigator는 한 번만 잡아서 두 번 pop
        final navigator = Navigator.of(context);
        final router = GoRouter.of(context);
        navigator.pop(); // Decorate
        navigator.pop(); // Album
        final extra = <String, dynamic>{
          'group': group,
          'startFromLatest': true,
          'focusPostId': newPostId,
          if (weekIdx != null) 'weekIndex': weekIdx,
        };
        if (widget.replaceOnPostSuccess) {
          router.pushReplacement(
            PostScreen.routeUrl,
            extra: extra,
          );
        } else {
          router.push(PostScreen.routeUrl, extra: extra);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPosting = false);
        showAppSnackBar(context, '포스트 저장 실패: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(currentUserGroupsProvider).valueOrNull ?? [];

    ref.listen(currentUserGroupsProvider, (prev, next) {
      final g = next.valueOrNull ?? [];
      if (g.isNotEmpty &&
          _selectedWeekdayIndex == null &&
          !_hasSyncedWeekdayFromGroups) {
        _hasSyncedWeekdayFromGroups = true;
        final idx = effectivePostingWeekdayIndex(
          g,
          widget.selectedWeekdayIndex,
        );
        if (weekdays[idx].name != _selectedWeekday) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedWeekday = weekdays[idx].name);
          });
        }
      }
      if (g.isEmpty && !_hasScheduledRedirect) {
        _hasScheduledRedirect = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          redirectToInviteIfNoGroups(context, ref, popCount: 2);
        });
      }
    });

    final weekdayIndex = _currentWeekdayIndex(groups);
    final group = groupForWeekday(groups, weekdayIndex);
    final displayNameAsync = group != null
        ? ref.watch(groupDisplayNameProvider(group.id))
        : null;
    final memberNicknamesAsync = group != null
        ? ref.watch(groupMemberNicknamesProvider(group.id))
        : null;
    final info = groupDisplayInfo(group, memberNicknamesAsync?.valueOrNull);
    final nickname = displayNameAsync?.valueOrNull ?? info.nickname;
    final subTitle = info.subTitle;
    final childTitle = group != null ? "Week ${groupWeekNumber(group)}" : null;

    final isDataReady =
        group != null &&
        (group.name?.trim().isNotEmpty == true ||
            memberNicknamesAsync?.valueOrNull != null);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: Hero(
                  tag: 'photo_${widget.asset.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(RValues.island),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (widget.thumbnail != null)
                          Image.memory(widget.thumbnail!, fit: BoxFit.cover),
                        if (_highResImage != null)
                          Image.memory(_highResImage!, fit: BoxFit.cover),
                      ],
                    ),
                  ),
                ),
              ),
              if (isDataReady) ...[
                Positioned(
                  right: Paddings.scaffoldH,
                  top: Paddings.scaffoldV,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: GestureDetector(
                      onTap: _onCloseTap,
                      child: _IconWithShadow(
                        child: FaIcon(
                          FontAwesomeIcons.circleXmark,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  left: 0,
                  bottom: 0,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Paddings.scaffoldH,
                        vertical: Paddings.scaffoldV,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _onWeekdayTap(groups),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  RValues.button,
                                ),
                                child: BackdropFilter(
                                  filter: Blurs.backdrop,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: Paddings.buttonH,
                                      vertical: Paddings.buttonV,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Blurs.overlayColor,
                                      borderRadius: BorderRadius.circular(
                                        RValues.button,
                                      ),
                                      border: Border.all(
                                        color: CustomColors.borderDark,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        AvatarPackage(
                                          nickname: nickname,
                                          avatarWidget: AvatarGroupStack(
                                            groupId: group.id,
                                            radius: CustomSizes.avatarComment,
                                          ),
                                          title: _selectedWeekday,
                                          isDarkOnly: true,
                                          subTitle: subTitle,
                                          childTitle: childTitle,
                                        ),
                                        Gaps.h6,
                                        FaIcon(
                                          FontAwesomeIcons.chevronDown,
                                          color: Colors.white,
                                          size: Sizes.size12,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          CustomSizes.commentTrailingGap,
                          GestureDetector(
                            onTap: _isPosting ? null : () => _onPostTap(groups),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(Sizes.size36),
                              child: BackdropFilter(
                                filter: Blurs.backdrop,
                                child: Container(
                                  alignment: Alignment.center,
                                  width: Sizes.size48,
                                  height: Sizes.size48,
                                  decoration: BoxDecoration(
                                    color: Blurs.overlayColor,
                                    borderRadius: BorderRadius.circular(
                                      Sizes.size36,
                                    ),
                                    border: Border.all(
                                      color: CustomColors.borderDark,
                                    ),
                                  ),
                                  child: _isPosting
                                      ? SizedBox(
                                          width: Sizes.size24,
                                          height: Sizes.size24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : FaIcon(
                                          FontAwesomeIcons.circleArrowRight,
                                          color: Colors.white,
                                          size: Sizes.size24,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _IconWithShadow extends StatelessWidget {
  const _IconWithShadow({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}
