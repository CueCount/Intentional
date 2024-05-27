import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isLoggedIn;
  final bool hasSubmittedForm;
  
  CustomAppBar({required this.title, this.isLoggedIn = true, this.hasSubmittedForm = true,});

  @override
  Widget build(BuildContext context) {
    return AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(title),  
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openEndDrawer(), // if using endDrawer
          ),
        ],
      );// Using the custom drawe
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);  // Default is 56.0
}