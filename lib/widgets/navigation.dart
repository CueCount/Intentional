import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../functions/login_service.dart';

class CustomStatusBar extends StatelessWidget {
  final int messagesCount;
  final int likesCount;

  const CustomStatusBar({
    Key? key,
    required this.messagesCount,
    required this.likesCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Image.asset(
              'assets/int.png',
            ),
            const SizedBox(width: 16),
            Row(
              children: [
                const Icon(Icons.send, color: Colors.white, size: 20),
                const SizedBox(width: 4),
                Text(
                  messagesCount.toString(),
                  style: GoogleFonts.roboto(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Row(
              children: [
                const Icon(Icons.favorite_border, color: Colors.white, size: 20),
                const SizedBox(width: 4),
                Text(
                  likesCount.toString(),
                  style: GoogleFonts.roboto(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.more_horiz, color: Colors.white),
          onPressed: () {
            LogoutService.logout(context);
          },
        ),
      ],
    );
  }
}
