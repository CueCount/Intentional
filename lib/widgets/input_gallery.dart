import 'package:flutter/material.dart';

class CustomCheckbox extends StatefulWidget {
  final String title;
  final bool initialValue;
  final ValueChanged<bool?>? onChanged;

  CustomCheckbox({
    Key? key,
    required this.title,
    this.initialValue = false,
    this.onChanged,
  }) : super(key: key);

  @override
  _CustomCheckboxState createState() => _CustomCheckboxState();
}

class _CustomCheckboxState extends State<CustomCheckbox> {
  late bool _isChecked;

  @override
  void initState() {
    super.initState();
    _isChecked = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: Text(widget.title),
      value: _isChecked,
      onChanged: (bool? newValue) {
        setState(() {
          _isChecked = newValue ?? false;
        });
        if (widget.onChanged != null) {
          widget.onChanged!(newValue);
        }
      },
      controlAffinity: ListTileControlAffinity.leading,  // Position the checkbox at the start of the tile
    );
  }
}