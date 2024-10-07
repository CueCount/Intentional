import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/router/router.dart';
import '../user.dart';
import '../widgets/appBar.dart';
import '../widgets/custom_drawer.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    
    void noOperation() {
      // This is an intentionally empty function that does nothing.
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return Scaffold(
      appBar: CustomAppBar(
        title: "Intentional",
        isLoggedIn: UserProvider.instance.isLoggedIn,
      ),
      endDrawer: CustomDrawer(), 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'The only dating app with 87% relationship success rate within the first 3 months for both men and women.'
            ),
            MaterialButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.qualRelDate);
              },
              child: const Text('Begin'),
              color: const Color.fromARGB(255, 226, 33, 243),
            ),
            MaterialButton(
              onPressed: () {
                userProvider.toggleLogin();
                print(userProvider.isLoggedIn); 
                Navigator.pushNamed(context, AppRoutes.home);
              },
              child: const Text('Login'),
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}