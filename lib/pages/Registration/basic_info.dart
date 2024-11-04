import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/appBar.dart';
import '../../widgets/custom_drawer.dart';
import '/router/router.dart';
import '../../widgets/input_text.dart';

class BasicProfilePage extends StatefulWidget {
 const BasicProfilePage({Key? key}) : super(key: key);
 @override
 State<BasicProfilePage> createState() => _BasicProfilePageState();
}

class _BasicProfilePageState extends State<BasicProfilePage> {
 final TextEditingController _nameController = TextEditingController();
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
     endDrawer: CustomDrawer(),
     body: SafeArea(
       child: Padding(
         padding: const EdgeInsets.all(16.0),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             const Text(
               'Verify Identity',
               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
             ),
             const SizedBox(height: 24),
             CustomTextInput(
              labelText: 'First Name',
              controller: _nameController,
              suffixIcon: Icon(Icons.mail)
             ),
             const SizedBox(height: 16),
             InkWell(
               onTap: () => _selectDate(context),
               child: Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   border: Border.all(color: Colors.grey),
                   borderRadius: BorderRadius.circular(4),
                 ),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Text(
                       _selectedDate == null
                           ? 'Birthday'
                           : '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}',
                     ),
                     const Icon(Icons.calendar_today),
                   ],
                 ),
               ),
             ),
           ],
         ),
       ),
     ),
     bottomNavigationBar: CustomAppBar(
       route: AppRoutes.photos, // Your next route
       inputValues: inputData,
     ),
   );
 }
}