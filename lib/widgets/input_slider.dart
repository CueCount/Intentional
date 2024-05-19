import 'package:flutter/material.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("${widget.label}: ${_currentValue.toStringAsFixed(1)}"),
          ),
        Slider(
          value: _currentValue,
          min: widget.min,
          max: widget.max,
          divisions: widget.divisions,
          label: _currentValue.toStringAsFixed(1),
          onChanged: (double newValue) {
            setState(() {
              _currentValue = newValue;
            });
            if (widget.onChanged != null) {
              widget.onChanged!(newValue);
            }
          },
        ),
      ],
    );
  }
}