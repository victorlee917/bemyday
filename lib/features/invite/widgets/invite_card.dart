import 'dart:async';

import 'package:bemyday/common/widgets/avatar/avatar_default.dart';
import 'package:bemyday/common/widgets/timeleft_chip.dart';
import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tilt/flutter_tilt.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:palette_generator_master/palette_generator_master.dart';

bool _isAssetPath(String url) => url.startsWith('assets/');

/// 이미지에서 그라데이션 색상 [dark, base, light] 추출.
/// [imageUrl]: 네트워크 URL 또는 assets/ 경로.
Future<List<Color>?> extractGradientColors(String imageUrl) async {
  try {
    final ImageProvider provider = _isAssetPath(imageUrl)
        ? AssetImage(imageUrl)
        : CachedNetworkImageProvider(imageUrl);
    final palette = await PaletteGeneratorMaster.fromImageProvider(
      provider,
      maximumColorCount: 12,
      colorSpace: ColorSpace.rgb,
    );
    final base =
        palette.dominantColor?.color ??
        palette.vibrantColor?.color ??
        palette.mutedColor?.color;
    if (base == null) return null;
    final dark = Color.lerp(base, Colors.black, 0.4)!;
    final light = Color.lerp(base, Colors.white, 0.5)!;
    return [dark, base, light];
  } catch (_) {
    return null;
  }
}

/// [extractGradientColors] 결과를 hex 문자열 리스트로 변환 (API 저장용).
Future<List<String>?> extractGradientColorsAsHex(String imageUrl) async {
  final colors = await extractGradientColors(imageUrl);
  if (colors == null) return null;
  return colors
      .map(
        (c) =>
            '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
      )
      .toList();
}

/// 초대장 카드 위젯.
///
/// [InviteCardTheme]에 따라 다른 스타일로 표시 가능.
/// 현재는 [InviteCardTheme.defaultTheme]만 지원.
enum InviteCardTheme { defaultTheme }

/// InviteScreen·InvitationScreen 공통 카드 크기 (가로 60%, 2:3 비율)
/// 바텀시트 내 잘림 방지를 위해 0.6 사용
(double width, double height) inviteCardDimensions(BuildContext context) {
  final w = MediaQuery.of(context).size.width * 0.6;
  return (w, w * (3 / 2));
}

/// InviteScreen·InvitationScreen 공통 카드 섹션 (카드 + 선택적 하단 위젯)
///
/// [child]: 카드 아래 표시 (InvitationScreen: Expires, Already a member 등)
class InviteSheetBody extends StatelessWidget {
  const InviteSheetBody({
    super.key,
    required this.weekdayName,
    required this.inviterNickname,
    this.inviterAvatarUrl,
    this.gradientColors,
    this.child,
  });

  final String weekdayName;
  final String inviterNickname;
  final String? inviterAvatarUrl;
  final List<Color>? gradientColors;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final (width, height) = inviteCardDimensions(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(RValues.island),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Tilt(
            tiltConfig: TiltConfig(
              enableGestureTouch: true,
              enableGestureHover: true,
              enableGestureSensors: true,
              angle: 4,
              sensorFactor: 8,
              enableReverse: true,
            ),
            lightConfig: LightConfig(disable: true),
            shadowConfig: ShadowConfig(disable: true),
            borderRadius: BorderRadius.circular(RValues.island),
            child: InviteCard(
              weekdayName: weekdayName,
              inviterNickname: inviterNickname,
              inviterAvatarUrl: inviterAvatarUrl,
              gradientColors: gradientColors,
              width: width,
              height: height,
            ),
          ),
        ),
        if (child != null) ...[Gaps.v16, child!],
      ],
    );
  }
}

class InviteCard extends StatelessWidget {
  const InviteCard({
    super.key,
    required this.weekdayName,
    required this.inviterNickname,
    this.inviterAvatarUrl,
    this.gradientColors,
    required this.width,
    required this.height,
    this.theme = InviteCardTheme.defaultTheme,
  });

  final String weekdayName;
  final String inviterNickname;
  final String? inviterAvatarUrl;

  /// API에 저장된 [dark, base, light] hex 배열. 있으면 아바타 팔레트 추출 생략
  final List<Color>? gradientColors;
  final double width;
  final double height;
  final InviteCardTheme theme;

  @override
  Widget build(BuildContext context) {
    return switch (theme) {
      InviteCardTheme.defaultTheme => _DefaultInviteCard(
        weekdayName: weekdayName,
        inviterNickname: inviterNickname,
        inviterAvatarUrl: inviterAvatarUrl,
        gradientColors: gradientColors,
        width: width,
        height: height,
      ),
    };
  }
}

/// 초대 유효 기간 카운트다운 (InviteCard 아래 표시용)
class InviteExpiryCountdown extends StatefulWidget {
  const InviteExpiryCountdown({super.key, required this.expiresAt});

  final DateTime expiresAt;

  @override
  State<InviteExpiryCountdown> createState() => _InviteExpiryCountdownState();
}

class _InviteExpiryCountdownState extends State<InviteExpiryCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.expiresAt.difference(DateTime.now());
    final textColor = isDarkMode(context) ? Colors.white : Colors.black87;
    if (remaining.isNegative) {
      return ChipContainer(
        child: Text(
          'Expired',
          style: TextStyle(
            color: textColor,
            fontSize: Sizes.size10,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Opacity(
          opacity: 0.7,
          child: Text(
            'Expires in',
            style: TextStyle(
              color: textColor,
              fontSize: Sizes.size10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Gaps.v4,
        ChipContainer(
          child: Text(
            formatCountdown(remaining),
            style: TextStyle(
              color: textColor,
              fontSize: Sizes.size12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _DefaultInviteCard extends StatelessWidget {
  const _DefaultInviteCard({
    required this.weekdayName,
    required this.inviterNickname,
    this.inviterAvatarUrl,
    this.gradientColors,
    required this.width,
    required this.height,
  });

  final String weekdayName;
  final String inviterNickname;
  final String? inviterAvatarUrl;
  final List<Color>? gradientColors;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final defaultColor = isDarkMode(context)
        ? CustomColors.nonClickableAreaDark
        : CustomColors.nonClickableAreaLight;

    return FutureBuilder<List<Color>?>(
      future: gradientColors == null && inviterAvatarUrl != null
          ? extractGradientColors(inviterAvatarUrl!)
          : null,
      builder: (context, snapshot) {
        final extractedColors = snapshot.data;
        final effectiveColors = gradientColors ?? extractedColors;
        final hasGradient =
            effectiveColors != null &&
            (gradientColors != null || inviterAvatarUrl != null);
        final decoration = BoxDecoration(
          borderRadius: BorderRadius.circular(RValues.island),
          border: Border.all(
            color: isDarkMode(context)
                ? CustomColors.borderDark
                : CustomColors.borderLight,
          ),
          color: !hasGradient ? defaultColor : null,
          boxShadow: hasGradient
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                    spreadRadius: -2,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        );

        return Container(
          height: height,
          width: width,
          decoration: decoration,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(RValues.island),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                if (effectiveColors != null) ...[
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: effectiveColors
                              .map((c) => c.withValues(alpha: 0.9))
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 1.2,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Paddings.scaffoldH,
                      vertical: Paddings.scaffoldV,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Invitation',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Sizes.size12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AvatarDefault(
                                nickname: inviterNickname,
                                avatarUrl: inviterAvatarUrl,
                                radius: Sizes.size32,
                              ),
                              Gaps.v24,
                              Text(
                                "Would You Be\nMy $weekdayName?",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.darumadropOne(
                                  textStyle: TextStyle(
                                    color: Colors.white,
                                    fontSize: Sizes.size24,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Opacity(
                          opacity: 0.5,
                          child: Text(
                            'From.',
                            style: TextStyle(
                              fontSize: Sizes.size10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Gaps.v2,
                        Text(
                          inviterNickname,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Sizes.size14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
