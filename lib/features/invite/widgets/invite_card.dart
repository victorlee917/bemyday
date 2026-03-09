import 'dart:async';
import 'dart:ui';

import 'package:bemyday/common/widgets/avatar/avatar_default.dart';
import 'package:bemyday/common/widgets/timeleft_chip.dart';
import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:palette_generator_master/palette_generator_master.dart';

/// 프로필 이미지에서 그라데이션 색상 추출 (앱·웹 동일 UI용 저장)
///
/// Returns: [dark, base, light] hex 문자열. 실패 시 null.
Future<List<String>?> extractGradientColorsAsHex(String imageUrl) async {
  try {
    final palette = await PaletteGeneratorMaster.fromImageProvider(
      CachedNetworkImageProvider(imageUrl),
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
    return [dark, base, light]
        .map(
          (c) =>
              '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
        )
        .toList();
  } catch (_) {
    return null;
  }
}

/// 초대장 카드 위젯.
///
/// [InviteCardTheme]에 따라 다른 스타일로 표시 가능.
/// 현재는 [InviteCardTheme.defaultTheme]만 지원.
enum InviteCardTheme { defaultTheme }

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
    final textColor = isDarkMode(context)
        ? Colors.white
        : Colors.black87;
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

  Future<List<Color>?> _extractGradientColors(String imageUrl) async {
    try {
      final palette = await PaletteGeneratorMaster.fromImageProvider(
        CachedNetworkImageProvider(imageUrl),
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

  @override
  Widget build(BuildContext context) {
    final defaultColor = isDarkMode(context)
        ? CustomColors.nonClickableAreaDark
        : CustomColors.nonClickableAreaLight;

    return FutureBuilder<List<Color>?>(
      future: gradientColors == null && inviterAvatarUrl != null
          ? _extractGradientColors(inviterAvatarUrl!)
          : null,
      builder: (context, snapshot) {
        final extractedColors = snapshot.data;
        final effectiveColors = gradientColors ?? extractedColors;
        final hasGradient = effectiveColors != null && (gradientColors != null || inviterAvatarUrl != null);
        final decoration = BoxDecoration(
          borderRadius: BorderRadius.circular(RValues.island),
          border: Border.all(
            color: isDarkMode(context)
                ? CustomColors.borderDark
                : CustomColors.borderLight,
          ),
          color: !hasGradient ? defaultColor : null,
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
                if (inviterAvatarUrl != null)
                  Positioned.fill(
                    child: ClipRect(
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Transform.scale(
                          scale: 1.15,
                          child: Image(
                            image: CachedNetworkImageProvider(
                              inviterAvatarUrl!,
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (effectiveColors != null)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: effectiveColors
                              .map((c) => c.withValues(alpha: 0.85))
                              .toList(),
                        ),
                      ),
                    ),
                  )
                else if (inviterAvatarUrl != null)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
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
