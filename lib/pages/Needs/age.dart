import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/bottomNavigationBar.dart';
import '../../widgets/customRangeSlider.dart';
import '/router/router.dart';
import '../../styles.dart';
import '../../widgets/navigation.dart';
import '../../providers/inputState.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Age extends StatefulWidget {
  const Age({Key? key}) : super(key: key);
  @override
  State<Age> createState() => _Age();
}

class _Age extends State<Age> {
  DateTime? _selectedDate;
  List<double> _ageRange = [22, 48]; // Default age range

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingValues();
    });
  }

  Future<void> _loadExistingValues() async {
    final inputState = Provider.of<InputState>(context, listen: false);
    
    try {
      // Load existing birthDate
      final existingBirthDate = await inputState.getInput('birthDate');
      if (existingBirthDate != null) {
        setState(() {
          _selectedDate = DateTime.fromMillisecondsSinceEpoch(existingBirthDate);
        });
      }
      
      // Load existing age range
      final existingAgeRange = await inputState.getInput('ageRange');
      if (existingAgeRange != null && existingAgeRange is List) {
        setState(() {
          _ageRange = [
            (existingAgeRange[0] as num).toDouble(),
            (existingAgeRange[1] as num).toDouble()
          ];
        });
      }
    } catch (e) {
      print('Age: Error loading existing values - $e');
    }
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
      'birthDate': _selectedDate != null ? _selectedDate!.millisecondsSinceEpoch : null,
      'ageRange': _ageRange,
    };
  }

  bool isFormComplete() {
    bool ageSelected = _selectedDate!=null;
    return ageSelected;
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> inputData = getInputData();
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const CustomStatusBar(),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [                    
                    // Verify Your Age header
                    Text(
                      'Verify Your Age',
                      style: AppTextStyles.headingMedium.copyWith(
                        color: ColorPalette.peach,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // Birthday input
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: Container(
                        height: 60,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ColorPalette.peach,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedDate == null
                                  ? 'Birthday'
                                  : '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}',
                              style: TextStyle(
                                fontSize: 16,
                                color: _selectedDate == null 
                                    ? ColorPalette.peach.withOpacity(0.6)
                                    : ColorPalette.peach,
                              ),
                            ),
                            Icon(
                              Icons.calendar_today,
                              color: ColorPalette.peach,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Age range section
                    Text(
                      "You're willing to date",
                      style: AppTextStyles.headingMedium.copyWith(
                        color: ColorPalette.peach,
                      ),
                      textAlign: TextAlign.left,
                    ),
                                        
                    Text(
                      'Ages ${_ageRange[0].round()} - ${_ageRange[1].round()}:',
                      style: AppTextStyles.headingMedium.copyWith(
                        color: ColorPalette.peach,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // Age range slider
                    CustomRangeSlider(
                      label: '',  // Empty label since we show it above
                      min: 18.0,
                      max: 100.0,
                      divisions: 82,
                      initialValues: RangeValues(_ageRange[0], _ageRange[1]),
                      onChanged: (RangeValues values) {
                        setState(() {
                          _ageRange = [values.start, values.end];
                        });
                      },
                    ),
                    
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      
      bottomNavigationBar: () {
        final inputState = Provider.of<InputState>(context, listen: false);
        final user = FirebaseAuth.instance.currentUser;
        bool isLoggedIn = user != null;
        bool isComplete = isFormComplete();
        
        return CustomAppBar(
          buttonText: isLoggedIn ? 'Save' : 'Continue',
          buttonIcon: isLoggedIn ? Icons.save : Icons.arrow_forward,
          isEnabled: isComplete,

          onPressed: () async {
            if (isLoggedIn) {
              await inputState.saveNeedLocally(inputData);
              if (context.mounted) {
                Navigator.pushNamed(context, AppRoutes.editNeeds, arguments: inputData);
              }
            } else {
              await inputState.saveNeedLocally(inputData);
              if (context.mounted) {
                Navigator.pushNamed(context, AppRoutes.basics);
              }
            }
          },
        );
      }(),
    );
  }
}