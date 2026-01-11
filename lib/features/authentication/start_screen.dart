import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/authentication/nickname_screen.dart';
import 'package:bemyday/features/authentication/widgets/auth_button.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  void _onStart(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => NicknameScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SizedBox.expand(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: Paddings.scaffoldH),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 20,
                  child: Column(
                    children: [
                      Text(
                        "Sign Up For Be My Day",
                        style: TextStyle(
                          fontSize: Sizes.size20,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Gaps.v12,
                      Text("Create a Profile", textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Paddings.scaffoldH,
            vertical: Sizes.size16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _onStart(context),
                child: AuthButton(
                  icon: FaIcon(FontAwesomeIcons.google),
                  label: "Start with Google",
                ),
              ),
              Gaps.v12,
              Text(
                'consdklfjs',
                style: TextStyle(),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
