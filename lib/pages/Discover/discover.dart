import 'package:flutter/material.dart';
import '../../widgets/ProfileCarousel.dart';
import '../../router/router.dart';
import '../../styles.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../functions/fetchData.dart';
import '../../widgets/navigation.dart';

class Matches extends StatefulWidget {
  const Matches({super.key, required this.title});
  final String title;
  @override
  State<Matches> createState() => _Matches();
}

class _Matches extends State<Matches> {
  String? photoUrl;
  String? firstName;
  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      firstName = await fetchUserField("firstName");
      setState(() {
        firstName = firstName;
      });
    } catch (e) {
      print("Error loading user name: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(20), // 20px padding on all sides
        decoration: const BoxDecoration(
          gradient: ColorPalette.brandGradient,
        ),
        child: Column(
          children: [
              
            const CustomStatusBar(
              messagesCount: 2,
              likesCount: 5,
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 600, // Ensures the carousel has space to render
              child: ProfileCarousel(),
            ),

            const SizedBox(height: 20),

          ],
        ),
      ),
    );
  }
}