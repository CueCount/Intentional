import 'package:flutter/material.dart';
import '../../widgets/appBar.dart';
import '../../widgets/custom_drawer.dart';
import '../../widgets/grid_item.dart';  // Import your GridItem class
import '/router/router.dart';

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
        route: AppRoutes.home,
      ),
      endDrawer: CustomDrawer(), 
      body: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(8),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: <Widget>[
          Text('This is the match page')
        ],
      ),
    );
  }
}