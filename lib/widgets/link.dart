import 'package:flutter/material.dart';
import '../styles.dart';

class LinkWidget extends StatelessWidget {
  final String title;
  final String? description;
  final VoidCallback onTap;

  const LinkWidget({
    Key? key,
    required this.title,
    this.description,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5), // Light grey background
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.headingSmall.copyWith(
                      color: ColorPalette.peach,
                    ),
                  ),
                  if (description != null && description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: ColorPalette.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFFFF6B6B), // Brand peach color
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}