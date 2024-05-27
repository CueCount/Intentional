import 'package:flutter/material.dart';

class AppStyles {
  static const TextStyle headlineStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 18,
  );

  static BoxDecoration boxDecoration = BoxDecoration(
    color: const Color.fromARGB(255, 255, 160, 160),
  );
}

class ColorPalette {
  static const Color unselectedCheckboxColor = Color(0xFFFFE0CC); // Light orange
  static const Color selectedCheckboxColor = Color(0xFFFB8C00); // Deeper orange
  static const Color unselectedTextColor = Colors.grey;
  static const Color selectedTextColor = Colors.white;
}

// Slider Theme Data
class AppSliderThemes {
  static SliderThemeData sliderTheme = SliderThemeData(
    thumbShape: SquareSliderThumbShape(),
    trackShape: RectangularSliderTrackShape(),
    activeTrackColor: const Color.fromRGBO(255, 227, 217, 1),
    inactiveTrackColor: Colors.grey,
    thumbColor: const Color.fromRGBO(241, 143, 106, 1),
    overlayColor: Colors.blue.withAlpha(32),
    //thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12.0),
    //overlayShape: RoundSliderOverlayShape(overlayRadius: 28.0),
  );
}
class SquareSliderThumbShape extends SliderComponentShape {
  final double thumbSize;

  SquareSliderThumbShape({this.thumbSize = 20.0});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(thumbSize, thumbSize);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    TextPainter? labelPainter,
    RenderBox? parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    final Paint paint = Paint()
      ..color = sliderTheme.thumbColor ?? Colors.black
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromCenter(center: center, width: thumbSize, height: thumbSize),
      paint,
    );
  }
}
class RectangularSliderTrackShape extends SliderTrackShape {
  final double trackHeight;

  RectangularSliderTrackShape({this.trackHeight = 20.0});

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    SliderThemeData? sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackLeft = offset.dx;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    bool isEnabled = false,
    bool isDiscrete = false,
    Offset? secondaryOffset,
  }) {
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final Paint paint = Paint()
      ..color = sliderTheme.activeTrackColor ?? Colors.blue
      ..style = PaintingStyle.fill;

    context.canvas.drawRect(trackRect, paint);
  }
}

// Checkbox Theme Data

