import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  final bool isLoggedIn;
  final bool hasSubmittedForm;

  CustomDrawer({this.isLoggedIn = true, this.hasSubmittedForm = true,});

  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            if (isLoggedIn)
              ListTile(
                leading: Icon(Icons.account_circle),
                title: Text('Profile'),
                onTap: () {
                  // Handle Profile tap
                  Navigator.pop(context);  // Close the drawer
                },
              ),
            if (isLoggedIn && hasSubmittedForm)
              ListTile(
                leading: Icon(Icons.analytics),
                title: Text('View Results'),
                onTap: () {
                  // Handle Results tap
                  Navigator.pop(context);  // Close the drawer
                },
              ),
            if (isLoggedIn)
              ListTile(
                leading: Icon(Icons.exit_to_app),
                title: Text('Logout'),
                onTap: () {
                  // Handle logout
                  Navigator.pop(context);  // Close the drawer
                },
              ),
          ],
        ),
    );
  }
}