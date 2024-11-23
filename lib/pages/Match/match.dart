import 'package:flutter/material.dart';
import '../../widgets/appBar.dart';
import '../../widgets/custom_drawer.dart';
import '../../router/router.dart';
import '../../functions/functions_photo.dart';
import '../../styles.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../functions/fetchData.dart';

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
      final photos = await PhotoUploadHelper.fetchExistingPhotos(selection: 0);
      firstName = await fetchUserField("firstName");
      setState(() {
        photoUrl = photos[0];
        firstName = firstName;
      });
    } catch (e) {
      print("Error loading photo: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const CustomDrawer(), 
      body: Container(
        child: Column(
          children: [ 
            Container(
              decoration: const BoxDecoration(
                gradient: ColorPalette.peachGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30.0),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(60.0),
                      child: photoUrl != null
                      ? Image.network(
                          photoUrl!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.error),
                        )
                      : const CircularProgressIndicator(),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "You’re Currently Open",
                                style: GoogleFonts.bitter(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                firstName ?? "Loading...",
                                style: GoogleFonts.barlow(
                                  fontSize: 32.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomAppBar(
        route: AppRoutes.logisticNeeds, 
      ),
    );
    
  }
}