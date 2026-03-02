import 'package:bemyday/common/widgets/close_app_bar_button.dart';
import 'package:bemyday/common/widgets/dropdown_button.dart' as common;
import 'package:bemyday/common/widgets/sheet/sheet_weekday_picker.dart';
import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/data/weekdays.dart';
import 'package:bemyday/features/group/providers/group_provider.dart';
import 'package:bemyday/features/group/utils.dart';
import 'package:bemyday/features/invite/providers/invitation_provider.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key, this.selectedWeekdayIndex});
  static const routeName = "invite";
  static const routeUrl = "/invite";

  final int? selectedWeekdayIndex;

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  late final PageController _pageController;
  int? _overriddenWeekdayIndex;
  int _selectedCardIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.6);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onCloseTap() {
    context.pop();
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedCardIndex = index;
    });
  }

  void _onWeekdayChanged(int index) {
    setState(() => _overriddenWeekdayIndex = index);
  }

  void _showWeekdayPicker() {
    final groups = ref.read(currentUserGroupsProvider).valueOrNull ?? [];
    showWeekdayPicker(
      context: context,
      items: buildWeekdayPickerItems(groups),
      onWeekdaySelected: _onWeekdayChanged,
    );
  }

  Future<void> _onInviteTap() async {
    final groups = ref.read(currentUserGroupsProvider).valueOrNull ?? [];
    final preferredIndex =
        _overriddenWeekdayIndex ?? widget.selectedWeekdayIndex;
    final effectiveIndex = await ref
        .read(effectiveInviteWeekdayIndexProvider(preferredIndex).future);
    final group = groupForWeekday(groups, effectiveIndex);
    final dbWeekday = effectiveIndex + 1;

    String token;
    try {
      token = await ref.read(invitationRepositoryProvider).createInvitation(
            groupId: group?.id,
            dbWeekday: dbWeekday,
          );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('초대 생성에 실패했습니다: $e')),
        );
      }
      return;
    }

    if (!context.mounted) return;
    final inviteUrl = 'https://bemyday.app/invite/$token';
    final weekdayName = weekdays[effectiveIndex].name;
    final size = MediaQuery.sizeOf(context);
    final shareOrigin = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 10,
      height: 10,
    );
    await Share.share(
      'Would you be my $weekdayName? $inviteUrl',
      subject: 'Be My Day - Invitation',
      sharePositionOrigin: shareOrigin,
    );
  }

  @override
  Widget build(BuildContext context) {
    final preferredIndex =
        _overriddenWeekdayIndex ?? widget.selectedWeekdayIndex;
    final effectiveAsync = ref.watch(
      effectiveInviteWeekdayIndexProvider(preferredIndex),
    );
    final groups = ref.watch(currentUserGroupsProvider).valueOrNull ?? [];
    final effectiveIndex = effectiveAsync.valueOrNull ?? 0;
    final group = groupForWeekday(groups, effectiveIndex);
    final memberCountAsync = group != null
        ? ref.watch(groupMemberCountProvider(group.id))
        : null;

    final isAlreadyFull =
        memberCountAsync?.valueOrNull != null &&
        memberCountAsync!.valueOrNull! >= 2;

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(RValues.bottomsheet),
          topRight: Radius.circular(RValues.bottomsheet),
        ),
      ),
      child: Scaffold(
        backgroundColor: isDarkMode(context)
            ? CustomColors.sheetColorDark
            : CustomColors.sheetColorLight,
        appBar: AppBar(
          title: Text("Invite Friends"),
          automaticallyImplyLeading: false,
          backgroundColor: isDarkMode(context)
              ? CustomColors.sheetColorDark
              : CustomColors.sheetColorLight,
          actions: [CloseAppBarButton(onTap: _onCloseTap)],
        ),
        body: Column(
          children: [
            Gaps.v24,
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: 2,
                itemBuilder: (context, index) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final width = screenWidth * 0.7;
                  final height = width * (3 / 2); // 2:3 비율 (가로:세로)

                  return RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, child) {
                      // 초기 페이지 기준으로 차이 계산
                      final initialPage = 0;
                      final currentPage =
                          _pageController.position.haveDimensions
                          ? _pageController.page!
                          : initialPage.toDouble();
                      final diff = currentPage - index;

                      final opacity = (1 - (diff.abs() * 0.3)).clamp(0.0, 1.0);
                      final rotationValue = diff * 0.3; // Y축 회전
                      final scale = (1 - diff.abs() * 0.2).clamp(
                        0.8,
                        1.0,
                      ); // 선택된 카드가 더 큼

                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(rotationValue)
                          ..scaleByDouble(scale, scale, 1.0, 1.0),
                        child: Opacity(opacity: opacity, child: child),
                      );
                    },
                    child: Center(
                      child: Container(
                        height: height,
                        width: width,
                        decoration: BoxDecoration(
                          color: isDarkMode(context)
                              ? CustomColors.nonClickableAreaDark
                              : CustomColors.nonClickableAreaLight,
                          borderRadius: BorderRadius.circular(RValues.island),
                          border: Border.all(
                            color: isDarkMode(context)
                                ? CustomColors.borderDark
                                : CustomColors.borderLight,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Would You Be My ${weekdays[effectiveIndex].name}?",
                              textAlign: TextAlign.center,
                            ),
                            Column(
                              children: [
                                Text("From."),
                                Row(children: []),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
                },
              ),
            ),
            Gaps.v24,
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: Paddings.scaffoldH,
              right: Paddings.scaffoldH,
              bottom: Paddings.scaffoldV,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                common.DropdownButton(
                  label: weekdays[effectiveIndex].name,
                  onTap: _showWeekdayPicker,
                ),
                Gaps.v16,
                GestureDetector(
                  onTap: isAlreadyFull ? null : _onInviteTap,
                  child: Opacity(
                    opacity: isAlreadyFull ? 0.5 : 1.0,
                    child: Container(
                      width: double.infinity,
                      height: Sizes.size48,
                      decoration: BoxDecoration(
                        color: isDarkMode(context)
                            ? Colors.white
                            : Colors.black,
                        borderRadius: BorderRadius.circular(RValues.button),
                      ),
                      child: Center(
                        child: Text(
                          isAlreadyFull ? "Already Full" : "Share Invitation",
                          style: Theme.of(context).textTheme.labelLarge!
                              .copyWith(
                                color: isDarkMode(context)
                                    ? Colors.black
                                    : Colors.white,
                              ),
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
    );
  }
}
