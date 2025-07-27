import 'package:flutter/material.dart';
import '../styles.dart';

class PillText extends StatelessWidget {
  final String text;

  const PillText({
    Key? key,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ColorPalette.peach.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: AppTextStyles.headingSmall.copyWith(
          color: ColorPalette.peach,
        ),
      ),
    );
  }
}