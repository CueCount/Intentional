import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({Key? key}) : super(key: key);

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

            StreamBuilder<User?>( 
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) { 
                final isLoggedIn = snapshot.hasData;
                return Column(
                  children: [
                    if (isLoggedIn) ...[
                    ListTile(
                        leading: const Icon(Icons.account_circle),
                        title: const Text('Your Profile'),
                        onTap: () {
                          Navigator.pushNamed(context, '/profile');
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.analytics),
                        title: const Text('Your Match'),
                        onTap: () {
                          Navigator.pushNamed(context, '/dashboard');
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.analytics),
                        title: const Text('Your Needs'),
                        onTap: () {
                          Navigator.pushNamed(context, '/needs');
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.exit_to_app),
                        title: const Text('Logout'),
                        onTap: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                      ),
                    ] else ...[
                      ListTile(
                        leading: const Icon(Icons.login),
                        title: const Text('Login'),
                        onTap: () {
                          Navigator.pushNamed(context, '/login');
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.person_add),
                        title: const Text('Register'),
                        onTap: () {
                          Navigator.pushNamed(context, '/register');
                        },
                      ),
                    ],
                  ],
                );
              }
            ),
          ],
        ),
    );
  }
}