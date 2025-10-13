import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../widgets/bottomNavigationBar.dart';
import '../../widgets/navigation.dart';
import '../../widgets/inputCheckbox.dart';  
import '../../styles.dart';
import '../../providers/inputState.dart';
import '/router/router.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QualifierRelDate extends StatefulWidget {
  const QualifierRelDate({super.key});
  @override
  State<QualifierRelDate> createState() => _QualifierRelDate();
}

class _QualifierRelDate extends State<QualifierRelDate> {
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  VALUES
   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  Map<String, dynamic> inputValues = {};
  Map<String, Map<String, bool>> groupSelectedValues = {};
  bool _isInitialized = false;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];
  Map<String, dynamic>? _selectedCity;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final inputState = Provider.of<InputState>(context, listen: false); 
      for (var input in inputState.qual) {
        groupSelectedValues[input.title] = {};
        for (var value in input.possibleValues) {
          groupSelectedValues[input.title]![value] = false;
        }
      }
      setState(() {
        _isInitialized = true;
      });
    });
  }

  Map<String, dynamic> getSelectedAttributes() {
    final inputState = Provider.of<InputState>(context, listen: false);
    Map<String, dynamic> selections = {}; 
    
    for (var input in inputState.qual) {
      if (input.type == "checkbox") {
        final groupValues = groupSelectedValues[input.title];
        if (groupValues != null) {
          selections[input.title] = groupValues.entries
              .where((entry) => entry.value)
              .map((entry) => entry.key)
              .toList();
        } else {
          selections[input.title] = <String>[];
        }
      } else if (input.type == "geopoint") {
        selections[input.title] = _selectedCity != null 
            ? {
                'name': _selectedCity!['name'],
                'adminCode1': _selectedCity!['adminCode1'],
                'lat': _selectedCity!['lat'],
                'lng': _selectedCity!['lng'],
              }
            : null;
      }
    }
    
    return selections;
  }

  Future<void> searchCities(String query) async {
    if (query.length < 2) {
      setState(() => _suggestions = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.get(Uri.parse(
        'http://api.geonames.org/searchJSON?q=$query&maxRows=5&username=jmocko&country=US&featureClass=P'
      ));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _suggestions = List<Map<String, dynamic>>.from(data['geonames']);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
    }
  }

  Widget _buildCheckboxGrid(Input input) {
    if (input.possibleValues.isEmpty) return const SizedBox.shrink();
    
    return SizedBox(
      height: (input.possibleValues.length / 2).ceil() * 100.0,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.75,
        ),
        itemCount: input.possibleValues.length,
        itemBuilder: (context, index) {
          String attribute = input.possibleValues[index];
          return CustomCheckbox(
            attribute: CheckboxAttribute(
              title: attribute,
              description: '',
              isSelected: groupSelectedValues[input.title]?[attribute] ?? false,
            ),
            onChanged: (isSelected) {
              setState(() {
                // Clear all other selections for this input (single selection)
                for (var value in input.possibleValues) {
                  groupSelectedValues[input.title]![value] = false;
                }
                // Set the selected value
                groupSelectedValues[input.title]![attribute] = isSelected;
              });
            },
            isSelected: groupSelectedValues[input.title]?[attribute] ?? false,
          );
        },
      ),
    );
  }

  bool isFormComplete() {
    bool genderSelected = groupSelectedValues["Gender"]?.values.any((v) => v) ?? false;
    bool seekingSelected = groupSelectedValues["Seeking"]?.values.any((v) => v) ?? false;
    bool locationSelected = _selectedCity != null;
    return genderSelected && seekingSelected && locationSelected;
  }

  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  SCAFFOLD
  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

  @override
  Widget build(BuildContext context) {
    final inputState = Provider.of<InputState>(context, listen: false);
    
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Get specific inputs by title
    final genderInput = inputState.qual.firstWhere((i) => i.title == "Gender");
    final seekingInput = inputState.qual.firstWhere((i) => i.title == "Seeking");
    final locationInput = inputState.qual.firstWhere((i) => i.title == "Location");
    
    return Scaffold( 
      body: Column(
        children: [
          const CustomStatusBar(), 
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: ListView(
                children: <Widget>[
                  
                  Text(
                    'I am a',
                    style: AppTextStyles.headingMedium.copyWith(
                      color: ColorPalette.peach,
                    ),
                    textAlign: TextAlign.left,
                  ),

                  const SizedBox(height: 10),
                  
                  _buildCheckboxGrid(genderInput),
                  
                  const SizedBox(height: 20),
                  
                  Text(
                    'Seeking a',
                    style: AppTextStyles.headingMedium.copyWith(
                      color: ColorPalette.peach,
                    ),
                    textAlign: TextAlign.left,
                  ),

                  const SizedBox(height: 10),
                  
                  _buildCheckboxGrid(seekingInput),
                  
                  const SizedBox(height: 20),
                  
                  Text(
                    'Around Abouts',
                    style: AppTextStyles.headingMedium.copyWith(
                      color: ColorPalette.peach,
                    ),
                    textAlign: TextAlign.left,
                  ),

                  const SizedBox(height: 10),
                  
                  Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ColorPalette.peach.withOpacity(0.5),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.black87,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Ex: New York',
                            hintStyle: AppTextStyles.bodyMedium.copyWith(
                              color: ColorPalette.peach,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                            suffixIcon: Icon(
                              Icons.keyboard_arrow_down,
                              color: ColorPalette.peach,
                            ),
                          ),
                          onChanged: (value) {
                            Future.delayed(const Duration(milliseconds: 500), () {
                              if (value == _searchController.text) {
                                searchCities(value);
                              }
                            });
                          },
                        ),
                      ),

                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),

                      if (_suggestions.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _suggestions.length,
                            itemBuilder: (context, index) {
                              final city = _suggestions[index];
                              return ListTile(
                                title: Text(
                                  '${city['name'] ?? ''}, ${city['adminCode1'] ?? ''}',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                      color: Colors.black87,  // Explicitly set text color
                                    ),
                                ),
                                onTap: () {
                                  setState(() {
                                    _selectedCity = city;
                                    _searchController.text = '${city['name'] ?? ''}, ${city['adminCode1'] ?? ''}';
                                    _suggestions = [];
                                  });
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                  
                ],
              ),
            ),
          ),
        ],
      ),
      
      bottomNavigationBar: () {
        final user = FirebaseAuth.instance.currentUser;
        bool isLoggedIn = user != null;
        final inputData = getSelectedAttributes();
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
                Navigator.pushNamed(context, AppRoutes.age);
              }
            }
          },
        );
      }(),
    );
  }
}