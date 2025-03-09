import 'package:flutter/material.dart';

/* - - - - - - - - - - - - - - - - - - - - - 
App Theme Styles 
 - - - - - - - - - - - - - - - - - - - - - */
class AppStyles {
  static const TextStyle headlineStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 18,
  );

  static const BoxDecoration boxDecoration = BoxDecoration(
    color:  ColorPalette.peach,
  );
}

class AppTextStyles {
  static TextStyle headingLarge = const TextStyle(
    fontFamily: 'Bitter',
    fontSize: 32,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    height: 1.2,
  );

  static TextStyle headingMedium = const TextStyle(
    fontFamily: 'Bitter',
    fontSize: 24,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    height: 1.2,
  );

  static TextStyle bodyMedium = const TextStyle(
    fontFamily: 'Barlow',
    fontSize: 18,
    fontWeight: FontWeight.w300,
    color: Colors.white,
    height: 1.2,
  );
}

class ColorPalette {
  static const Color white = Color(0xFFFFFFFF);
  static const Color peach = Color(0xFFFF5D5D);
  static const Color lite = Color(0xFFFAEBEB);
  static const Color dark = Color(0xFF250E0E);
  static const Color grey = Color(0xFF867A7A);
  static const Color peachLite = Color(0xFFFFD5D5);
  static const LinearGradient peachGradient = LinearGradient(
    colors: [Color(0xFFFF324D), Color(0xFFFF5D5D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient brandGradient = LinearGradient(
            colors: [Color(0xFFDC1C56), Color(0xFFFF294C)], // Colors from the screenshot
            begin: Alignment.topLeft, // Adjust as needed
            end: Alignment.bottomRight,
          );
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

class AppCheckboxThemes {
  static BoxDecoration checkboxDecoration(bool isSelected) {
    return BoxDecoration(
      color: isSelected ? ColorPalette.peach : ColorPalette.white,
      borderRadius: BorderRadius.circular(8), // Rounded corners
      boxShadow: isSelected
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ]
          : [],
    );
  }

  static TextStyle checkboxTitle(bool isSelected) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: isSelected ? ColorPalette.white : ColorPalette.dark,
    );
  }

  static TextStyle checkboxDescription(bool isSelected) {
    return TextStyle(
      fontSize: 14,
      color: isSelected ? ColorPalette.white.withOpacity(0.9) : ColorPalette.dark,
    );
  }

  static Icon checkboxIcon = Icon(
    Icons.check,
    color: ColorPalette.white,
    size: 24,
  );
}