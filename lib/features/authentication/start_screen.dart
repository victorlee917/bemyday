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
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: Paddings.scaffoldH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              GestureDetector(
                onTap: () => _onStart(context),
                child: AuthButton(
                  icon: FaIcon(FontAwesomeIcons.google),
                  label: "Start with Google",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
