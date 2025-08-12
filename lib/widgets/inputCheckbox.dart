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

  const CustomCheckbox({
    Key? key,
    required this.attribute,
    required this.onChanged,
    required this.isSelected,
    this.isHorizontal = false, // defaults to vertical layout
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
        padding: AppCheckboxThemes.checkboxPadding,
        decoration: AppCheckboxThemes.checkboxDecoration(widget.attribute.isSelected),
        child: widget.isHorizontal
        ? Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.attribute.title,
                    style: AppCheckboxThemes.checkboxCardTitle(widget.attribute.isSelected),
                  ),
                  if (widget.attribute.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.attribute.description,
                      style: AppCheckboxThemes.checkboxDescription(widget.attribute.isSelected),
                    ),
                  ],
                ],
              ),
            ),
            AppCheckboxThemes.getCheckboxIcon(widget.attribute.isSelected),
          ],
        )
        : Column(
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
  }
}