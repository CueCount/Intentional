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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty)
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Text(
              "${_currentRangeValues.start.toStringAsFixed(1)} - ${_currentRangeValues.end.toStringAsFixed(1)}",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: ColorPalette.dark,
              ),
            ),
          ),
        ),
        SliderTheme(
          data: AppRangeSliderThemes.sliderTheme,
          child: RangeSlider(
            values: _currentRangeValues,
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            labels: RangeLabels(
              _currentRangeValues.start.toStringAsFixed(1),
              _currentRangeValues.end.toStringAsFixed(1),
            ),
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
    );
  }
}
