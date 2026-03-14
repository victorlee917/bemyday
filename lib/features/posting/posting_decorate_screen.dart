import 'package:bemyday/common/widgets/avatar/avatar_group_stack.dart';
import 'package:bemyday/common/widgets/avatar/avatar_package.dart';
import 'package:bemyday/common/widgets/sheet/sheet_weekday_picker.dart';
import 'package:bemyday/features/group/utils.dart';
import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/data/weekdays.dart';
import 'package:bemyday/features/group/providers/group_provider.dart';
import 'package:bemyday/features/invite/invite_utils.dart';
import 'package:bemyday/features/posting/viewmodels/posting_viewmodel.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:photo_manager/photo_manager.dart';

class PostingDecorateScreen extends ConsumerStatefulWidget {
  final AssetEntity asset;
  final Uint8List? thumbnail;
  final int? selectedWeekdayIndex;

  const PostingDecorateScreen({
    super.key,
    required this.asset,
    this.thumbnail,
    this.selectedWeekdayIndex,
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

  int _currentWeekdayIndex() {
    final groups = ref.read(currentUserGroupsProvider).valueOrNull ?? [];
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
    final data = await widget.asset.thumbnailDataWithSize(ThumbnailSize(w, h));
    if (data != null && mounted) {
      setState(() => _highResImage = data);
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

  void _onWeekdayTap() {
    final groups = ref.read(currentUserGroupsProvider).valueOrNull ?? [];
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

  Future<void> _onPostTap() async {
    if (_isPosting) return;
    final groups = ref.read(currentUserGroupsProvider).valueOrNull ?? [];
    if (groups.isEmpty) return;

    final weekdayIndex = _currentWeekdayIndex();
    final group = groupForWeekday(groups, weekdayIndex);
    if (group == null) return;

    final file = await widget.asset.file;
    if (file == null || !mounted) return;

    setState(() => _isPosting = true);
    try {
      await ref.read(postingViewModelProvider).createPost(group, file);
      if (mounted) {
        Navigator.of(context).pop(group);
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

    if (groups.isNotEmpty &&
        _selectedWeekdayIndex == null &&
        !_hasSyncedWeekdayFromGroups) {
      _hasSyncedWeekdayFromGroups = true;
      final idx = effectivePostingWeekdayIndex(
        groups,
        widget.selectedWeekdayIndex,
      );
      if (weekdays[idx].name != _selectedWeekday) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _selectedWeekday = weekdays[idx].name);
        });
      }
    }

    if (groups.isEmpty && !_hasScheduledRedirect) {
      _hasScheduledRedirect = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        redirectToInviteIfNoGroups(context, ref, popCount: 2);
      });
    }

    final weekdayIndex = _currentWeekdayIndex();
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
                              onTap: _onWeekdayTap,
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
                            onTap: _isPosting ? null : _onPostTap,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                Sizes.size36,
                              ),
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
