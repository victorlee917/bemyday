import 'package:bemyday/constants/styles.dart';
import 'package:bemyday/features/authentication/widgets/form_button.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class NicknameScreen extends StatefulWidget {
  const NicknameScreen({super.key});

  @override
  State<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _nickname = "";
  bool _isNicknameValid = false;

  void _onSubmit() {
    if (_formKey.currentState != null) {
      if (_formKey.currentState!.validate()) {
        _formKey.currentState!.save();
      }
    }
  }

  void _onSaved(value) {
    if (value != null) {
      _nickname = value;
    }
  }

  String? _validator(value) {
    if (value != null && value.isEmpty) {
      return 'Please Write your Nickname';
    }
    return null;
  }

  void _onScaffoldTap() {
    FocusScope.of(context).unfocus();
  }

  void _onReset() {
    _formKey.currentState?.reset();
  }

  void _onChange(value) {
    setState(() {
      if (_formKey.currentState != null) {
        if (_formKey.currentState!.validate()) {
          _nickname = value;
          _isNicknameValid = true;
        } else {
          _isNicknameValid = false;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onScaffoldTap,
      child: Scaffold(
        appBar: AppBar(title: Text('Nickname')),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: Paddings.scaffoldH),
          child: Column(
            children: [
              Text("What's Your Name?"),
              Text("Set Up Your Nickname Please"),
              Form(
                key: _formKey,
                child: TextFormField(
                  autocorrect: false,
                  autofocus: true,
                  decoration: InputDecoration(
                    suffix: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: _onReset,
                          child: FaIcon(FontAwesomeIcons.solidCircleXmark),
                        ),
                      ],
                    ),
                    hintText: "write your nickname",
                  ),
                  validator: _validator,
                  onChanged: _onChange,
                  onEditingComplete: _onSubmit,
                  onSaved: _onSaved,
                ),
              ),
              GestureDetector(
                onTap: _onSubmit,
                child: FormButton(disabled: !_isNicknameValid, label: "Done"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
