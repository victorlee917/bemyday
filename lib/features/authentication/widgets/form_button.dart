import 'package:bemyday/constants/styles.dart';
import 'package:flutter/material.dart';

class FormButton extends StatelessWidget {
  final String label;
  final bool disabled;

  const FormButton({super.key, required this.label, required this.disabled});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 1,
      child: AnimatedContainer(
        padding: EdgeInsets.symmetric(vertical: Paddings.buttonV),
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(RValues.button),

          color: disabled
              ? Colors.grey.shade300
              : Theme.of(context).primaryColor,
        ),
        child: AnimatedDefaultTextStyle(
          style: TextStyle(
            color: disabled ? Colors.grey.shade400 : Colors.black,
            fontWeight: FontWeight.w600,
          ),
          duration: const Duration(milliseconds: 300),
          child: const Text('Next', textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
