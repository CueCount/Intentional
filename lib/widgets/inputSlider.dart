import 'package:flutter/material.dart';
import '../styles.dart';

class CustomSlider extends StatefulWidget {
  final String label;
  final double initialValue;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double>? onChanged;

  CustomSlider({
    Key? key,
    this.label = '',
    this.initialValue = 0,
    this.min = 0,
    this.max = 100,
    this.divisions = 10,
    this.onChanged,
  }) : super(key: key);

  @override
  _CustomSliderState createState() => _CustomSliderState();
}

class _CustomSliderState extends State<CustomSlider> {
  late double _currentValue;
  
  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
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
          if (widget.label.isNotEmpty)
            Text(
              widget.label,
              style: AppTextStyles.headingMedium.copyWith(
                color: ColorPalette.peach,
                fontSize: 24,
              ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 12),
          Text(
            "${_currentValue.toStringAsFixed(1)} - ${widget.max.toStringAsFixed(1)}",
            style: AppTextStyles.bodyMedium.copyWith(
              color: ColorPalette.peach,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SliderTheme(      
            data: AppSliderThemes.sliderTheme.copyWith(
              trackHeight: 8.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
            ),
            child: Slider(
              value: _currentValue,
              min: widget.min,
              max: widget.max,
              divisions: widget.divisions,
              onChanged: (double newValue) {
                setState(() {
                  _currentValue = newValue;
                });
                if (widget.onChanged != null) {
                  widget.onChanged!(newValue);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}