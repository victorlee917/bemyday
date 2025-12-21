import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/features/authentication/start_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const BeMyDay());
}

class BeMyDay extends StatelessWidget {
  const BeMyDay({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // 공통 텍스트 스타일 (색상 제외)
    const appBarTitleStyle = TextStyle(
      fontSize: Sizes.size16,
      fontWeight: FontWeight.bold,
    );

    return MaterialApp(
      title: 'Be My Day',
      // 라이트 모드 테마
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black, //아이콘 색상
          elevation: 0,
          titleTextStyle: appBarTitleStyle.copyWith(
            color: Colors.black,
          ),
        ),
      ),
      // 다크 모드 테마
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: appBarTitleStyle.copyWith(
            color: Colors.white,
          ),
        ),
      ),
      // 시스템 설정 따라가기
      themeMode: ThemeMode.system,
      home: StartScreen(),
    );
  }
}
