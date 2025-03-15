import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '/router/router.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../widgets/appBar.dart';
import '../../styles.dart';
import '../../widgets/navigation.dart';

class Match extends StatefulWidget {
  const Match({super.key});
  @override
  State<Match> createState() => _Match();
}

class _Match extends State<Match> {
  Map<String, dynamic>? profile; // Store the selected profile

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final Map<String, dynamic>? profileData = 
      ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

      if (profileData == null) {
        print("❌ Error: Profile data is null!");
        return;
      }

      setState(() {
        profile = profileData;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container (
          padding: const EdgeInsets.all(20), // 20px padding on all sides
          decoration: const BoxDecoration(
            gradient: ColorPalette.brandGradient,
          ),
        child: SingleChildScrollView(
        child: Column(
          children: [
            const CustomStatusBar(
              messagesCount: 2,
              likesCount: 5,
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('${profile!['firstName']}, ${profile!['birthDate']}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), // ✅ Fix: Use widget.name and widget.age
                  /*Text('${profile!['profession']}, ${profile!['university']}', style: const TextStyle(fontSize: 16, color: Colors.grey)),*/ // ✅ Fix: Use widget.profession and widget.university
                ],
              ),
            ),

            // Image Carousel
            CarouselSlider.builder(
              options: CarouselOptions(height: 400.0),
              itemCount: profile!['photos'].length,
              itemBuilder: (context, index, realIndex) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(profile!['photos'][index], fit: BoxFit.cover, width: double.infinity),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: () {},
                      ),
                    ),
                  ],
                );
              },
            ),

            // Profile Info
            const Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('90% Match', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('Based on XX Metrics and XX commonalidies', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            ),

            // Match Metrics Carousel
            /*CarouselSlider.builder(
              options: CarouselOptions(height: 100.0, enableInfiniteScroll: false),
              itemCount: widget.matchMetrics.isNotEmpty ? widget.matchMetrics.length : 3,
              itemBuilder: (context, index, realIndex) {
                if (widget.matchMetrics.isEmpty) {
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    color: Colors.grey[300],
                    child: const SizedBox(height: 80, width: double.infinity),
                  );
                }
                final metric = widget.matchMetrics[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  child: ListTile(
                    leading: const Icon(Icons.favorite, color: Colors.redAccent),
                    title: Text(metric['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${metric['percentage']}% Match'),
                    trailing: IconButton(
                      icon: const Icon(Icons.send, color: Colors.redAccent),
                      onPressed: () {},
                    ),
                  ),
                );
              },
            ),

            // Shared Interests Carousel
            CarouselSlider.builder(
              options: CarouselOptions(height: 100.0, enableInfiniteScroll: false),
              itemCount: widget.sharedInterests.isNotEmpty ? widget.sharedInterests.length : 3,
              itemBuilder: (context, index, realIndex) {
                if (widget.sharedInterests.isEmpty) {
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    color: Colors.grey[300],
                    child: const SizedBox(height: 80, width: double.infinity),
                  );
                }
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  child: ListTile(
                    leading: const Icon(Icons.bookmark, color: Colors.redAccent),
                    title: Text(widget.sharedInterests[index], style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: IconButton(
                      icon: const Icon(Icons.send, color: Colors.redAccent),
                      onPressed: () {},
                    ),
                  ),
                );
              },
            ),*/
          ],
        ),
        ),
      ),
      ),
      bottomNavigationBar: const CustomAppBar(
        route: AppRoutes.chat,
        submitToFirestore: false,
      ),
      );
    
  }
}
