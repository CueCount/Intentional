import 'package:flutter/material.dart';
import '../../widgets/appBar.dart';
import '/router/router.dart';
import '../../styles.dart';
import '../../widgets/navigation.dart';
import '../../functions/airTrafficControler_service.dart';

class Age extends StatefulWidget {
 const Age({Key? key}) : super(key: key);
 @override
 State<Age> createState() => _Age();
}

class _Age extends State<Age> {
 DateTime? _selectedDate;

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
      'birthDate': _selectedDate != null ? _selectedDate!.millisecondsSinceEpoch : null,
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

              const CustomStatusBar(messagesCount: 2,likesCount: 5,),

              Text(
                'Verify Your Age',
                style: AppTextStyles.headingLarge.copyWith(
                  color: ColorPalette.peach,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),
              
              Text( 
                'Birthday',
                style: AppTextStyles.headingMedium.copyWith(
                  color: ColorPalette.white,
                ),
              ),

              const SizedBox(height: 20),

              InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  height: 50, 
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(10), 
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

           ],
         ),
     ),
    
    bottomNavigationBar: CustomAppBar(
      onPressed: () async {
        await AirTrafficController().addedNeed(context, inputData);
        if (context.mounted) {
          Navigator.pushNamed(context, AppRoutes.emotionalNeeds, arguments: inputData);
        }
      },
    ),
  );
 }
}