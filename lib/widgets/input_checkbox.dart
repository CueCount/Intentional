import 'package:flutter/material.dart';
import '../styles.dart';

class MateAttribute {
  String title;
  String description;
  bool isSelected;

  MateAttribute({
    required this.title,
    required this.description,
    this.isSelected = false,
  });
}

class CustomCheckbox extends StatefulWidget {
  final MateAttribute attribute;
  final bool isSelected;
  final Function(bool) onChanged;

  const CustomCheckbox({
    Key? key,
    required this.attribute,
    required this.onChanged,
    required this.isSelected, 
  }) : super(key: key);

  @override
  _CustomCheckboxState createState() => _CustomCheckboxState();
}

class _CustomCheckboxState extends State<CustomCheckbox> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          widget.attribute.isSelected = !widget.attribute.isSelected;
        });
        widget.onChanged(widget.attribute.isSelected);
      },
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: widget.attribute.isSelected
              ? ColorPalette.selectedCheckboxColor
              : ColorPalette.unselectedCheckboxColor,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.attribute.title, 
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: widget.attribute.isSelected
                    ? ColorPalette.selectedTextColor
                    : ColorPalette.unselectedTextColor,)            
            ),
            SizedBox(height: 8),
            Text(widget.attribute.description),
            SizedBox(height: 8),
            if (widget.attribute.isSelected)
              Icon(Icons.check_circle, color: Colors.green, size: 24),
          ],
        ),
      ),
    );
  }
}
