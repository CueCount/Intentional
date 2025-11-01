import 'package:flutter/material.dart';
import '../styles.dart';

class PillText extends StatelessWidget {
  final String text;
  final String colorVariant;

  const PillText({
    Key? key,
    required this.text,
    required this.colorVariant,
  }) : super(key: key);

  Color _getBackgroundColor() {
    switch (colorVariant) {
      case "white":
        return ColorPalette.white;
      case "peach":
        return ColorPalette.peach;
      case "peachLite":
        return ColorPalette.peachLite;
      case "peachMedium":
        return ColorPalette.peachMedium;
      case "green":
        return ColorPalette.green;
      case "greenLite":
        return ColorPalette.greenLite;
      case "greenMedium":
        return ColorPalette.greenMedium;
      case "violet":
        return ColorPalette.violet;
      case "violetLite":
        return ColorPalette.violetLite;
      case "violetMedium":
        return ColorPalette.violetMedium;
      case "pink":
        return ColorPalette.pink;
      case "pinkLite":
        return ColorPalette.pinkLite;
      case "pinkMedium":
        return ColorPalette.pinkMedium;
      default:
        return ColorPalette.peach;
    }
  }

  Color _getTextColor() {
    switch (colorVariant) {
      case "white":
        return ColorPalette.peach;
      case "peach":
        return ColorPalette.white;
      case "peachLite":
        return ColorPalette.peach;
      case "green":
        return ColorPalette.white;
      case "greenLite":
        return ColorPalette.green;
      case "violet":
        return ColorPalette.white;
      case "violetLite":
        return ColorPalette.violet;
      default:
        return ColorPalette.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: AppTextStyles.headingSmall.copyWith(
          color: _getTextColor(),
        ),
      ),
    );
  }
}