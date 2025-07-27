import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../functions/login_service.dart';
import '../styles.dart';
import 'menu.dart';

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
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              AppMenuOverlay.show(context);
            },
          ), 
          Text(
            'Intentional',
            style: GoogleFonts.roboto(fontSize: 16, color: ColorPalette.peach),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black),
            onPressed: () {
              AccountService.logout(context);
            },
          )
        ],
      ),
    );
  }
}
