import 'package:flutter/material.dart';
import '../styles.dart';

class CustomRangeSlider extends StatefulWidget {
  final String label;
  final RangeValues initialValues;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<RangeValues>? onChanged;

  CustomRangeSlider({
    Key? key,
    this.label = '',
    this.initialValues = const RangeValues(0, 100),
    this.min = 0,
    this.max = 100,
    this.divisions = 10,
    this.onChanged,
  }) : super(key: key);

  @override
  _CustomRangeSliderState createState() => _CustomRangeSliderState();
}

class _CustomRangeSliderState extends State<CustomRangeSlider> {
  late RangeValues _currentRangeValues;

  @override
  void initState() {
    super.initState();
    _currentRangeValues = widget.initialValues;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            "${_currentRangeValues.start.toStringAsFixed(1)} - ${_currentRangeValues.end.toStringAsFixed(1)}",
            style: AppTextStyles.bodyMedium.copyWith(
              color: ColorPalette.peach,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SliderTheme(
            data: AppRangeSliderThemes.sliderTheme.copyWith(
              trackHeight: 8.0,
              rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 12.0),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
            ),
            child: RangeSlider(
              values: _currentRangeValues,
              min: widget.min,
              max: widget.max,
              divisions: widget.divisions,
              onChanged: (RangeValues newRangeValues) {
                setState(() {
                  _currentRangeValues = newRangeValues; 
                });
                if (widget.onChanged != null) {
                  widget.onChanged!(newRangeValues);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}