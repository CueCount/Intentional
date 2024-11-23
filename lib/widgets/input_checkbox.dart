import 'package:flutter/material.dart';
import '../styles.dart';
import 'package:google_fonts/google_fonts.dart';

class CheckboxAttribute {
  String title;
  String description;
  bool isSelected;

  CheckboxAttribute({
    required this.title,
    required this.description,
    this.isSelected = false,
  });
}

class CustomCheckbox extends StatefulWidget {
  final CheckboxAttribute attribute;
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: widget.attribute.isSelected
              ? ColorPalette.peach
              : ColorPalette.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.attribute.title, 
            textAlign: TextAlign.center,
            style: GoogleFonts.bitter(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: widget.attribute.isSelected
                    ? ColorPalette.white
                    : ColorPalette.dark,)            
            ),
            const SizedBox(height: 8),
            Text(widget.attribute.description),
            const SizedBox(height: 8),
            if (widget.attribute.isSelected)
              const Icon(Icons.check, color: ColorPalette.white, size: 20),
          ],
        ),
      ),
    );
  }
}
