import 'package:flutter/material.dart';
import '../../widgets/appBar.dart';
import '../../widgets/custom_drawer.dart';
import '../../widgets/grid_item.dart';  // Import your GridItem class

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.title});
  final String title;
  @override
  State<DashboardPage> createState() => _DashboardPage();
}

class _DashboardPage extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.title,
        isLoggedIn: true,
        hasSubmittedForm: true,
      ),
      endDrawer: CustomDrawer(), 
      body: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(8),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: <Widget>[
          GridItem(title: "Your Match", imagePath: "assets/image1.jpg", routeName: "/match_chat"),
          GridItem(title: "Your Info", imagePath: "assets/image2.jpg", routeName: "/route2"),
          GridItem(title: "Your Photos", imagePath: "assets/image3.jpg", routeName: "/route3"),
          GridItem(title: "Verifications", imagePath: "assets/image4.jpg", routeName: "/verifications"),
          GridItem(title: "History", imagePath: "assets/image5.jpg", routeName: "/history"),
          GridItem(title: "Your Needs", imagePath: "assets/image6.jpg", routeName: "/route6"),
        ],
      ),
    );
  }
}