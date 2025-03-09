import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/appBar.dart';
import '/router/router.dart';
import '../../widgets/input_text.dart';
import '../../styles.dart';
import '../../widgets/navigation.dart';

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

 Future<void> _selectDate(BuildContext context) async {
   final DateTime? picked = await showDatePicker(
     context: context,
     initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
     firstDate: DateTime.now().subtract(const Duration(days: 36500)), // 100 years ago
     lastDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
   );
   
   if (picked != null && picked != _selectedDate) {
     setState(() {
       _selectedDate = picked;
     });
   }
 }

 Map<String, dynamic> getInputData() {
   return {
     'firstName': _nameController.text,
     'birthDate': _selectedDate != null ? Timestamp.fromDate(_selectedDate!) : null,
   };
 }

 @override
 Widget build(BuildContext context) {
  Map<String, dynamic> inputData = getInputData();
   
    return Scaffold(
      body: Container (
        padding: const EdgeInsets.all(20), // 20px padding on all sides
        decoration: const BoxDecoration(
          gradient: ColorPalette.brandGradient,
        ),
     child: SafeArea(
      
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // Ensures horizontal alignment remains proper
            mainAxisAlignment: MainAxisAlignment.start,
           children: [

            const CustomStatusBar(
                  messagesCount: 2,
                  likesCount: 5,
                ),

              const SizedBox(height: 20),
              
              Text(
               'Your Information',
               style: AppTextStyles.headingMedium.copyWith(
                  color: ColorPalette.white,
                ),
              ),

             const SizedBox(height: 20),

             CustomTextInput(
              labelText: 'First Name',
              controller: _nameController,
              suffixIcon: Icon(Icons.mail)
             ),

             const SizedBox(height: 10),

             InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                height: 50, // Match the height of text input fields
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white, // Match text field background
                  borderRadius: BorderRadius.circular(10), // Match rounded corners
                  
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDate == null
                          ? 'Birthday'
                          : '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}',
                      style: const TextStyle(
                        fontSize: 16, 
                        color: Colors.black54, // Match text input placeholder color
                      ),
                    ),
                    const Icon(Icons.calendar_today, color: Colors.black54),
                  ],
                ),
              ),
            ),

              const SizedBox(height: 10),

              CustomTextInput(
                labelText: 'Career',
                controller: _nameController,
                suffixIcon: Icon(Icons.mail)
              ),
              
              const SizedBox(height: 10),

              CustomTextInput(
                labelText: 'School',
                controller: _nameController,
                suffixIcon: Icon(Icons.mail)
              ),
           ],
         ),
       
     ),
    ),
     bottomNavigationBar: CustomAppBar(
       route: AppRoutes.match, 
       inputValues: inputData,
     ),
   );
 }
}