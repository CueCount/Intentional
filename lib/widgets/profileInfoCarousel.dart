import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../styles.dart';

class ProfileInfoCarousel extends StatelessWidget {
  final Map<String, dynamic> profileData;
  final double height;
  final double viewportFraction;
  final bool enlargeCenterPage;
  final EdgeInsets margin;

  const ProfileInfoCarousel({
    Key? key,
    required this.profileData,
    this.height = 120,
    this.viewportFraction = 0.85,
    this.enlargeCenterPage = false,
    this.margin = const EdgeInsets.only(bottom: 20),
  }) : super(key: key);

  // Define individual profile info items using actual keys from inputState.dart
  List<Map<String, String>> _getProfileInfoItems() {
    return [
      {'key': 'birthDate', 'label': 'Years Old'},
      {'key': 'How Tall?', 'label': 'Height'},
      {'key': 'nameFirst', 'label': 'Name'},
      {'key': 'Gender', 'label': 'Gender'},
      {'key': 'Location', 'label': 'Location'},
      {'key': 'Seeking', 'label': 'Seeking'},
    ];
  }

  // Build individual profile info cards only if data exists
  List<Widget> _buildProfileInfoCards() {
    final infoItems = _getProfileInfoItems();
    List<Widget> cards = [];

    for (var item in infoItems) {
      final value = _getDisplayValue(item['key']!);
      if (value != null && value.isNotEmpty) {
        cards.add(_buildProfileInfoCard(value, item['label']!));
      }
    }

    return cards;
  }

  // Get display value for a given key, with special formatting for certain fields
  String? _getDisplayValue(String key) {
    final value = profileData[key];
    if (value == null) return null;

    switch (key) {
      case 'birthDate':
        // If birthDate is a number (age), return as-is with age suffix
        if (value is int) {
          return '$value';
        }
        // If it's a date string, you might want to calculate age
        return value.toString();
      
      case 'How Tall?':
        // Height from range slider (0-100), you might want to convert this to actual height
        if (value is int) {
          // Convert slider value to height representation
          // This is just an example - adjust based on your slider logic
          int heightInInches = 60 + (value * 12 / 100).round(); // 5'0" to 6'0" range
          int feet = heightInInches ~/ 12;
          int inches = heightInInches % 12;
          return '$feet\'$inches"';
        }
        return value.toString();
      
      case 'Location':
        // Location might be a complex object from geopoint
        if (value is Map) {
          return value['city'] ?? value['name'] ?? value.toString();
        }
        return value.toString();
      
      case 'Gender':
      case 'Seeking':
        // These come from checkbox selections
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }
        return value.toString();
      
      case 'nameFirst':
        return value.toString();
      
      default:
        // Handle any other fields
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }
        return value.toString();
    }
  }

  Widget _buildProfileInfoCard(String value, String label) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorPalette.lite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          const Icon(
            Icons.arrow_forward,
            color: Colors.black54,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileInfoCards = _buildProfileInfoCards();

    if (profileInfoCards.isEmpty) {
      return Container(height: height, margin: margin);
    }

    // If only one card, show it without carousel
    if (profileInfoCards.length == 1) {
      return Container(
        height: height,
        margin: margin,
        child: profileInfoCards[0],
      );
    }

    return Container(
      height: height,
      margin: margin,
      child: CarouselSlider(
        options: CarouselOptions(
          height: height,
          viewportFraction: viewportFraction,
          enlargeCenterPage: enlargeCenterPage,
          enableInfiniteScroll: false,
          autoPlay: false,
        ),
        items: profileInfoCards,
      ),
    );
  }
}