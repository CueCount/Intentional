import 'package:flutter/material.dart';
import '../styles.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onPressed;
  final String buttonText;
  final IconData buttonIcon;
  final bool isEnabled;

  const CustomAppBar({
    Key? key, 
    required this.onPressed,
    this.buttonText = 'Continue',
    this.buttonIcon = Icons.arrow_forward,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [ 
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                color: ColorPalette.peach,
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                //onPressed: onPressed,
                onPressed: isEnabled ? onPressed : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      buttonText,
                      style: AppTextStyles.headingMedium.copyWith(
                        //color: ColorPalette.peach,
                        color: isEnabled ? ColorPalette.peach : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(buttonIcon, color: isEnabled ? ColorPalette.peach : Colors.grey.shade500, size: 24),
                  ],
                ),
              ),
            ],
          ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(88);
}