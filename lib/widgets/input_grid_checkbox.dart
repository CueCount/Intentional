import 'package:flutter/material.dart';
import '../inputs/input_config.dart';
import 'input_checkbox.dart';

class CheckboxGrid extends StatefulWidget {
  final String title;
  final bool initialValue;
  final ValueChanged<bool?>? onChanged;

  CheckboxGrid({
    Key? key,
    required this.title,
    this.initialValue = false,
    this.onChanged,
  }) : super(key: key);

  @override
  _CheckboxGrid createState() => _CheckboxGrid();
}

class _CheckboxGrid extends State<CheckboxGrid> {

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
        padding: EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.0,
        ),
        itemCount: inputs.length,
        itemBuilder: (context, index) {
          return CustomCheckbox(
            attribute: inputs[index].possibleValues[index],
            onChanged: (isSelected) {
              setState(() {
                inputs[index].possibleValues[index].isSelected = isSelected;
              });
            },
          );
        },
      );
  }
}