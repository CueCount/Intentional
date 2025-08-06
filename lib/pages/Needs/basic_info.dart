import 'package:flutter/material.dart';
import '../../widgets/bottomNavigationBar.dart';
import '/router/router.dart';
import '../../widgets/inputText.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../styles.dart';
import '../../widgets/navigation.dart';
import '../../functions/onboardingService.dart';
import '../../functions/userActionsService.dart';

class BasicProfilePage extends StatefulWidget {
 const BasicProfilePage({Key? key}) : super(key: key);
 @override
 State<BasicProfilePage> createState() => _BasicProfilePageState();
}

class _BasicProfilePageState extends State<BasicProfilePage> {
 final TextEditingController _nameController = TextEditingController();
 final TextEditingController _careerController = TextEditingController();
 final TextEditingController _schoolController = TextEditingController();
 DateTime? _selectedDate;

 @override
 void dispose() {
   _nameController.dispose();
   super.dispose();
 }

 Map<String, dynamic> getInputData() {
   return {
     'firstName': _nameController.text,
     'school': _schoolController.text,
     'career': _careerController.text,
   };
 }

 @override
 Widget build(BuildContext context) {
  
    return Scaffold(
      body: SafeArea(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const CustomStatusBar(),
            const SizedBox(height: 20),
        
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text( 
                    'You',
                    style: AppTextStyles.headingLarge.copyWith(
                      color: ColorPalette.peach,
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: ColorPalette.peach),
                    decoration: InputDecoration(
                      labelText: 'First Name',
                      labelStyle: const TextStyle(color: ColorPalette.peach),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                      ),
                      suffixIcon: const Icon(Icons.mail, color: Colors.grey),
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: _careerController,
                    style: const TextStyle(color: ColorPalette.peach),
                    decoration: InputDecoration(
                      labelText: 'Career',
                      labelStyle: const TextStyle(color: ColorPalette.peach),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                      ),
                      suffixIcon: const Icon(Icons.mail, color: Colors.grey),
                    ),
                  ),
                  
                  const SizedBox(height: 10),

                  TextField(
                    controller: _schoolController,
                    style: const TextStyle(color: ColorPalette.peach),
                    decoration: InputDecoration(
                      labelText: 'School',
                      labelStyle: const TextStyle(color: ColorPalette.peach),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                      ),
                      suffixIcon: const Icon(Icons.mail, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: () {
        return FutureBuilder<bool>(
          future: () async {
            String? userId = await UserActions.getCurrentUserId(); // ← Use same function
            if (userId != null) {
              return await UserActions.isInfoIncomplete(userId);
            }
            return true;
          }(),
          builder: (context, snapshot) {
            bool infoIncomplete = snapshot.data ?? true;
            return CustomAppBar(
              buttonText: infoIncomplete ? 'Continue' : 'Update',
              buttonIcon: infoIncomplete ? Icons.arrow_forward : Icons.edit,
              onPressed: () async {
                Map<String, dynamic> inputData = getInputData();
                if (infoIncomplete) {
                  await AirTrafficController().saveAccountInputRegistrationFlow(context, inputData);
                  if (context.mounted) {
                    Navigator.pushNamed(context, AppRoutes.photos, arguments: inputData);
                  }
                } else {
                  await UserActions().saveNeedLocally(context, inputData);
                  if (context.mounted) {
                    Navigator.pushNamed(context, AppRoutes.editNeeds, arguments: inputData);
                  }
                }
              },
            );
          },
        );
      }(),
    );
  }
}