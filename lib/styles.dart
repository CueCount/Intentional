import 'package:flutter/material.dart';

/* - - - - - - - - - - - - - - - - - - - - - 
App Theme Styles 
 - - - - - - - - - - - - - - - - - - - - - */
class AppStyles {
  static const BoxDecoration boxDecoration = BoxDecoration(
    color:  ColorPalette.peach,
  );
}

class AppTextStyles {
  static TextStyle headingLarge = const TextStyle(
    fontFamily: 'Fraunces',
    fontSize: 36,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1,
  );

  static TextStyle headingMedium = const TextStyle(
    fontFamily: 'Fraunces',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.1,
  );

  static TextStyle headingSmall = const TextStyle(
    fontFamily: 'Fraunces',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    height: 1.2,
  );

  static TextStyle bodyMedium = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    height: 1.2,
  );

  static TextStyle bodySmall = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    height: 1.2,
  );
}

class ColorPalette {
  
  static const Color peach = Color(0xFFFF294C);
  static const Color violet = Color(0xFFE349D9);
  static const Color green = Color(0xFF38B6A8);
  static const Color pink = Color(0xFF3F42D76);

  static const Color white = Color(0xFFFFFFFF);
  static const Color lite = Color(0xFFFAEBEB);
  static const Color dark = Color(0xFF250E0E);
  static const Color grey = Color(0xFF867A7A);

  static const Color peachLite = Color(0xFFFFEEF1);
  static const Color violetLite = Color.fromARGB(255, 246, 205, 243);
  static const Color greenLite = Color.fromARGB(255, 212, 251, 247);
  static const Color pinkLite = Color(0xFFFFBFD6);
  
  static const Color peachMedium = Color(0xFFF66078);
  static const Color violetMedium = Color(0xFFF46AEB);
  static const Color greenMedium = Color(0xFF35C6B6);
  static const Color pinkMedium = Color(0xFFFF5895);
  
}

/* - - - - - - - - - - - - - - - - - - - - -  
Slider Theme Styles 
 - - - - - - - - - - - - - - - - - - - - - */

class AppSliderThemes {
  static final SliderThemeData sliderTheme = SliderThemeData(
    trackHeight: 10.0,
    activeTrackColor: ColorPalette.peach,
    inactiveTrackColor: ColorPalette.lite,
    thumbColor: ColorPalette.peach,
    overlayColor: ColorPalette.peachLite,
    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
    trackShape: const RoundedRectSliderTrackShape(),
    overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
    showValueIndicator: ShowValueIndicator.always,
    valueIndicatorColor: ColorPalette.peach,
    valueIndicatorTextStyle: AppTextStyles.bodyMedium.copyWith(
      color: Colors.white,
    ),
  );
}

class SquareSliderThumbShape extends SliderComponentShape {
  final double thumbSize;
  SquareSliderThumbShape({this.thumbSize = 40.0});
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
  RectangularSliderTrackShape({this.trackHeight = 40.0});
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

/* - - - - - - - - - - - - - - - - - - - - -  
RangeSlider Theme Styles 
 - - - - - - - - - - - - - - - - - - - - - */

class AppRangeSliderThemes {
  static final SliderThemeData sliderTheme = SliderThemeData(
    rangeThumbShape: SquareRangeSliderThumbShape(thumbSize: 20.0),
    rangeTrackShape: RectangularRangeSliderTrackShape(trackHeight: 10.0),
    activeTrackColor: ColorPalette.peach,
    inactiveTrackColor: ColorPalette.lite,
    thumbColor: ColorPalette.peach,
    overlayColor: ColorPalette.peachLite,
    trackHeight: 10.0,
    overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
    showValueIndicator: ShowValueIndicator.always,
    valueIndicatorColor: ColorPalette.peach,
    valueIndicatorTextStyle: AppTextStyles.bodyMedium.copyWith(
      color: Colors.white,
    ),
  );
}

class SquareRangeSliderThumbShape extends RangeSliderThumbShape {
  final double thumbSize;
  SquareRangeSliderThumbShape({this.thumbSize = 40.0});

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
    bool isEnabled = true,
    bool isOnTop = false,
    bool isPressed = false,
    required SliderThemeData sliderTheme,
    TextDirection textDirection = TextDirection.ltr,
    Thumb thumb = Thumb.start,
  })  {
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

class RectangularRangeSliderTrackShape extends RangeSliderTrackShape {
  final double trackHeight;
  RectangularRangeSliderTrackShape({this.trackHeight = 40.0});

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
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
    required Offset startThumbCenter,
    required Offset endThumbCenter,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final Paint activePaint = Paint()..color = sliderTheme.activeTrackColor ?? Colors.blue;
    final Paint inactivePaint = Paint()..color = sliderTheme.inactiveTrackColor ?? Colors.grey;

    if (startThumbCenter.dx > trackRect.left) {
      context.canvas.drawRect(
        Rect.fromLTRB(trackRect.left, trackRect.top, startThumbCenter.dx, trackRect.bottom),
        inactivePaint,
      );
    }

    context.canvas.drawRect(
      Rect.fromLTRB(startThumbCenter.dx, trackRect.top, endThumbCenter.dx, trackRect.bottom),
      activePaint,
    );

    if (endThumbCenter.dx < trackRect.right) {
      context.canvas.drawRect(
        Rect.fromLTRB(endThumbCenter.dx, trackRect.top, trackRect.right, trackRect.bottom),
        inactivePaint,
      );
    }
  }
}

/* - - - - - - - - - - - - - - - - - - - - -  
Checkbox Theme Styles 
 - - - - - - - - - - - - - - - - - - - - - */

/* - - - - - - - - - - - - - - - - - - - - -  
Checkbox Theme Styles 
 - - - - - - - - - - - - - - - - - - - - - */

class AppCheckboxThemes {
  static BoxDecoration checkboxDecoration(bool isSelected) {
    return BoxDecoration(
      color: isSelected ? ColorPalette.peach : ColorPalette.lite,
      borderRadius: BorderRadius.circular(16), // More rounded corners for card style  
    );
  }

  static TextStyle checkboxTitle(bool isSelected) {
    return TextStyle(
      color: isSelected ? ColorPalette.white : ColorPalette.peach,
      fontFamily: 'Fraunces',
      fontSize: 18,
      fontWeight: FontWeight.w500,
      height: 1.2,
    );
  }

  static TextStyle checkboxDescription(bool isSelected) {
    return TextStyle(
      color: isSelected ? ColorPalette.white : ColorPalette.grey,
      fontFamily: 'Fraunces',
      fontSize: 18,
      fontWeight: FontWeight.w500,
      height: 1.2,
    );
  }

  // Icon for selected state (checkmark)
  static Icon checkboxSelectedIcon = const Icon(
    Icons.check,
    color: ColorPalette.white,
    size: 24,
  );

  // Icon for unselected state (plus)
  static Icon checkboxUnselectedIcon = const Icon(
    Icons.add,
    color: ColorPalette.peach,
    size: 24,
  );

  // Method to get the appropriate icon based on selection state
  static Icon getCheckboxIcon(bool isSelected) {
    return isSelected ? checkboxSelectedIcon : checkboxUnselectedIcon;
  }

  // Padding for the checkbox content
  static const EdgeInsets checkboxPadding = EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0);
  
  // Height for consistent checkbox sizing
  // static const double checkboxHeight = 160.0;

  // Text style for larger checkbox cards (like in your image)
  static TextStyle checkboxCardTitle(bool isSelected) {
    return TextStyle(
      fontFamily: 'Fraunces',
      fontSize: 18,
      fontWeight: FontWeight.w500,
      height: 1.2,
      color: isSelected ? ColorPalette.white : ColorPalette.peach,
    );
  }
}