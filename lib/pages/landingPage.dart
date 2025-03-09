import 'package:flutter/material.dart';
import '/router/router.dart';
import '../styles.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    void noOperation() {}
    return Scaffold(
      body: Center(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromRGBO(255, 93, 93, 1),
                Color.fromRGBO(255, 93, 198, 1),
              ],
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 0),
          child: Column(
            children: <Widget>[
              Container(
                width: 60,  
                height: 60,
                margin: const EdgeInsets.only(
                  top: 20,    
                  bottom: 60, 
                ),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(255, 213, 213, 1), 
                  borderRadius: BorderRadius.circular(16), 
                ),
                child: SvgPicture.asset(
                  'lib/assets/Int.svg',
                  color: const Color.fromRGBO(255, 93, 93, 1),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 20,),
                child: Text(
                  'Let Us Sort\n Through the Mess,\n and Find You\n Your Person',
                  style: AppTextStyles.headingLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 60,),
                child: Text(
                  'Start Dating Intentionally.',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 150, 
                    height: 150,
                    margin: const EdgeInsets.all(10),
                    child: MaterialButton(
                      onPressed: () {Navigator.pushNamed(context, AppRoutes.qual);},
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4),),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 150, 
                    height: 150, 
                    margin: const EdgeInsets.all(10),
                    child: MaterialButton(
                      onPressed: () {Navigator.pushNamed(context, AppRoutes.register);},
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4),),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8), 
                          Icon(Icons.login, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}