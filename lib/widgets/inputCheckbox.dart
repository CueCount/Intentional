import 'package:flutter/material.dart';
import '../styles.dart';

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
  final bool isHorizontal;
  final bool shrinkWrap; // New attribute to control width behavior

  const CustomCheckbox({
    Key? key,
    required this.attribute,
    required this.onChanged,
    required this.isSelected,
    this.isHorizontal = false, // defaults to vertical layout
    this.shrinkWrap = true, // defaults to content-hugging
  }) : super(key: key);

  @override
  _CustomCheckboxState createState() => _CustomCheckboxState();
}

class _CustomCheckboxState extends State<CustomCheckbox> {
  @override
  Widget build(BuildContext context) {
    Widget checkboxContent = GestureDetector(
      onTap: () {
        setState(() {
          widget.attribute.isSelected = !widget.attribute.isSelected;
        });
        widget.onChanged(widget.attribute.isSelected);
      },
      child: widget.isHorizontal
      ? Container(
          padding: AppCheckboxThemes.checkboxPadding,
          decoration: AppCheckboxThemes.checkboxDecoration(widget.attribute.isSelected),
          child: Row(
            mainAxisSize: MainAxisSize.min, // This is key - makes row only as wide as needed
            children: [
              Text(
                widget.attribute.title,
                style: AppTextStyles.headingSmall.copyWith(
                  color: widget.attribute.isSelected ? ColorPalette.white : ColorPalette.peach,
                ),
              ),
              const SizedBox(width: 10),
              AppCheckboxThemes.getCheckboxIcon(widget.attribute.isSelected),
            ],
          ),
        )
      : Container(
          padding: AppCheckboxThemes.checkboxPadding,
          decoration: AppCheckboxThemes.checkboxDecoration(widget.attribute.isSelected),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.attribute.title,
                textAlign: TextAlign.center,
                style: AppCheckboxThemes.checkboxCardTitle(widget.attribute.isSelected),
              ),
              if (widget.attribute.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  widget.attribute.description,
                  textAlign: TextAlign.center,
                  style: AppCheckboxThemes.checkboxDescription(widget.attribute.isSelected),
                ),
              ],
              const SizedBox(height: 4),
              AppCheckboxThemes.getCheckboxIcon(widget.attribute.isSelected),
            ],
          ),
        ),
    );
    
    // If horizontal and shrinkWrap is true, wrap in UnconstrainedBox to prevent parent expansion
    if (widget.isHorizontal && widget.shrinkWrap) {
      return UnconstrainedBox(
        alignment: Alignment.centerLeft, // Align to left by default
        child: checkboxContent,
      );
    }
    
    return checkboxContent;
  }
}