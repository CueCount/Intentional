import 'package:flutter/material.dart';
import '../../widgets/appBar.dart';
import '/router/router.dart';
import '../../styles.dart';
import '../../widgets/navigation.dart';
import '../../functions/airTrafficControler_service.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({Key? key}) : super(key: key);
  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  
  Map<String, dynamic> getInputData() {
    return {
      // Placeholder for subscription data
    };
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> inputData = getInputData();
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const CustomStatusBar(messagesCount: 2, likesCount: 5,),
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text( 
                    'Subscription',
                    style: AppTextStyles.headingLarge.copyWith(
                      color: ColorPalette.peach,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Placeholder content - you can add subscription form fields here later
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey, width: 1),
                    ),
                    child: const Text(
                      'Credit card information and subscription details will go here.',
                      style: TextStyle(
                        color: ColorPalette.peach,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      
      bottomNavigationBar: CustomAppBar(
        onPressed: () async {
          await AirTrafficController().addedNeed(context, inputData);
          if (context.mounted) {
            // Update this route to wherever you want to navigate next
            Navigator.pushNamed(context, AppRoutes.matches, arguments: inputData);
          }
        },
      ),
    );
  }
}