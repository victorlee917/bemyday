import 'dart:ui';
import 'package:bemyday/constants/sizes.dart';
import 'package:flutter/material.dart';

class Paddings {
  static const scaffoldH = Sizes.size16;
  static const scaffoldV = Sizes.size16;
  static const profileV = Sizes.size32;
  static const tileH = Sizes.size24;
  static const tileV = Sizes.size20;
  static const buttonH = Sizes.size16;
  static const buttonV = Sizes.size14;
  static const bannerH = Sizes.size20;
  static const bannerV = Sizes.size14;
  static const dropdownH = Sizes.size20;
  static const dropdownV = Sizes.size12;
}

class RValues {
  static const button = Sizes.size36;
  static const island = Sizes.size24;
  static const thumbnail = Sizes.size24;
  static const bottomsheet = Sizes.size24;
}

class ARatio {
  static const common = 2 / 3;
}

class Widths {
  static const devider = Sizes.size1;
}

class Heights {
  static const tileItem = Sizes.size12;
}

class CustomColors {
  static const primaryColorLight = Color.fromRGBO(235, 235, 235, 1.0);
  static const primaryColorDark = Color.fromRGBO(20, 20, 20, 1.0);
  static const backgroundColorLight = Color.fromRGBO(255, 255, 255, 1.0);
  static const backgroundColorDark = Color.fromRGBO(0, 0, 0, 1.0);
  static const sheetColorLight = Color.fromRGBO(250, 250, 250, 1.0);
  static const sheetColorDark = Color.fromRGBO(5, 5, 5, 1.0);
  static const clickableAreaLight = Color.fromRGBO(242, 242, 242, 1.0);
  static const clickableAreaDark = Color.fromRGBO(13, 13, 13, 1.0);
  static const nonClickableAreaLight = Color.fromRGBO(245, 245, 245, 1.0);
  static const nonClickableAreaDark = Color.fromRGBO(10, 10, 10, 1.0);
  static const borderLight = Color.fromRGBO(13, 13, 13, 0.05);
  static const borderDark = Color.fromRGBO(242, 242, 242, 0.05);
  static const hintColorDark = Color.fromRGBO(255, 255, 255, 0.3);
  static const hintColorLight = Color.fromRGBO(0, 0, 0, 0.3);
  static const destructiveColorDark = Color.fromRGBO(255, 73, 64, 1.0);
  static const destructiveColorLight = Color.fromRGBO(255, 73, 64, 1.0);
  static const positiveColorDark = Color.fromRGBO(52, 199, 89, 1.0);
  static const positiveColorLight = Color.fromRGBO(52, 199, 89, 1.0);
  static const postCardBorderDark = Color.fromRGBO(32, 32, 32, 1.0);
  static const postCardBorderLight = Color.fromRGBO(242, 242, 242, 1.0);
}

class Blurs {
  /// BackdropFilter용 (드롭다운, 배지, 시트 등 UI 오버레이)
  static const sigma = 10.0;
  static final backdrop = ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);

  /// PostStack blur container 등 가벼운 오버레이
  static const sigmaStackOverlay = 8.0;
  static final stackOverlay = ImageFilter.blur(
    sigmaX: sigmaStackOverlay,
    sigmaY: sigmaStackOverlay,
  );

  /// 포스트 카드/그리드 등 콘텐츠 가리기용
  static const sigmaContent = 20.0;
  static final content = ImageFilter.blur(
    sigmaX: sigmaContent,
    sigmaY: sigmaContent,
  );

  /// 포스트 상세 화면 전체 blur
  static const sigmaFullScreen = 30.0;
  static final fullScreen = ImageFilter.blur(
    sigmaX: sigmaFullScreen,
    sigmaY: sigmaFullScreen,
  );

  static const overlayColor = Color.fromRGBO(0, 0, 0, 0.2);
  static const overlayColorLight = Color.fromRGBO(255, 255, 255, 0.3);
  static const overlayColorDark = Color.fromRGBO(0, 0, 0, 0.3);
}

class CustomSizes {
  static const avatarDefault = Sizes.size32;
  static const avatarComment = Sizes.size20;
  static const avatarTile = Sizes.size16;
  static const tileLeadingIcon = Sizes.size16;
  static const tileTrailingIcon = Sizes.size14;
  static const tileSpacing = Sizes.size16;
  static const sectionGap = Sizes.size20;
  static const sectionTitleGap = SizedBox(height: Sizes.size12);
  static const profileBSpacing = SizedBox(height: Sizes.size8);
  static const commentLeadingGap = SizedBox(width: Sizes.size14);
  static const commentTrailingGap = SizedBox(width: Sizes.size14);
  static const commentDateGap = SizedBox(width: Sizes.size4);
}
