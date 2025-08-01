import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../widgets/bottomNavigationBar.dart';
import '../../widgets/navigation.dart';
import '../../widgets/input_checkbox.dart';  
import '../../functions/onboardingService.dart';
import '../../styles.dart';
import '../../data/inputState.dart';
import '/router/router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../functions/userActionsService.dart';

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
  bool _isInitialized = false; // Add initialization flag
  
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
        _isInitialized = true; // Set initialization flag
      });
    });
  }

  Map<String, dynamic> getSelectedAttributes() {
    final inputState = Provider.of<InputState>(context, listen: false);
    Map<String, dynamic> selections = {}; 
    
    for (var input in inputState.qual) {
      if (input.type == "checkbox") {
        // Add null safety check
        final groupValues = groupSelectedValues[input.title];
        if (groupValues != null) {
          selections[input.title] = groupValues.entries
              .where((entry) => entry.value)
              .map((entry) => entry.key)
              .toList();
        } else {
          selections[input.title] = <String>[]; // Return empty list if not initialized
        }
      } else if (input.type == "geopoint") {
        // Add the location data
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

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];
  Map<String, dynamic>? _selectedCity;
  bool _isLoading = false;

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

  @override
  Widget build(BuildContext context) {
    final inputState = Provider.of<InputState>(context);
    
    // Show loading indicator until initialization is complete
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    Map<String, dynamic> inputData = getSelectedAttributes();
    return Scaffold( 
      body: Column(
        children: [
          const CustomStatusBar(messagesCount: 2,likesCount: 5,), 
          Expanded(
            child: Padding (
              padding: const EdgeInsets.all(10),
          child: ListView(
            children: <Widget>[
              const SizedBox(height: 20),
              Text(
                'Let\'s Begin',
                style: AppTextStyles.headingLarge.copyWith(
                  color: ColorPalette.peach,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              for (var input in inputState.qual) ...[
                if (input.type == "checkbox" && input.possibleValues.isNotEmpty) ...[
                  SizedBox(
                    height: (input.possibleValues.length / 2).ceil() * 100.0, // Adjust height based on number of items
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // 2 columns like chemistry page
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.75, // Adjust for your design
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
                              // Clear all other selections for this input (single selection behavior)
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
                  ),
                ] else if (input.type == "geopoint") ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        Container(
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
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Around... (Your Location)',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                              suffixIcon: Icon(Icons.location_on_outlined),
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
                                  title: Text('${city['name']}, ${city['adminCode1']}'),
                                  onTap: () {
                                    setState(() {
                                      _selectedCity = city;
                                      _searchController.text = '${city['name']}, ${city['adminCode1']}';
                                      _suggestions = [];
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                ],
              ],
            ),
            ),
          ),
        ],
      ),
      
      bottomNavigationBar: () {
        final user = FirebaseAuth.instance.currentUser;
        bool isLoggedIn = user != null;
        return CustomAppBar(
          buttonText: isLoggedIn ? 'Save' : 'Continue',
          buttonIcon: isLoggedIn ? Icons.save : Icons.arrow_forward,
          onPressed: () async {
            if (isLoggedIn) {
              await UserActions().saveNeedLocally(context, inputData);
              if (context.mounted) {
                Navigator.pushNamed(context, AppRoutes.editNeeds, arguments: inputData);
              }
            } else {
              await AirTrafficController().saveNeedInOnboardingFlow(context, inputData);
              if (context.mounted) {
                Navigator.pushNamed(context, AppRoutes.age, arguments: inputData);
              }
            }
          },
        );
      }(),
    );
  }
}