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
  bool _isLoadingData = true;
  final GlobalKey _textFieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingValues();
    });
  }

  Future<void> _loadExistingValues() async {
    final inputState = Provider.of<InputState>(context, listen: false);
    
    // Initialize all possible values as false first
    for (var input in inputState.qual) {
      groupSelectedValues[input.title] = {};
      for (var value in input.possibleValues) {
        groupSelectedValues[input.title]![value] = false;
      }
    }
    
    try {
      // Get existing Gender selection
      final existingGender = await inputState.fetchInputFromLocal('Gender');
      if (existingGender != null && existingGender is List && existingGender.isNotEmpty) {
        for (String selectedValue in existingGender) {
          if (groupSelectedValues['Gender']?.containsKey(selectedValue) ?? false) {
            groupSelectedValues['Gender']![selectedValue] = true;
          }
        }
      }
      
      // Get existing Seeking selection
      final existingSeeking = await inputState.fetchInputFromLocal('Seeking');
      if (existingSeeking != null && existingSeeking is List && existingSeeking.isNotEmpty) {
        for (String selectedValue in existingSeeking) {
          if (groupSelectedValues['Seeking']?.containsKey(selectedValue) ?? false) {
            groupSelectedValues['Seeking']![selectedValue] = true;
          }
        }
      }
      
      // Get existing Location
      final existingLocation = await inputState.fetchInputFromLocal('Location');
      if (existingLocation != null && existingLocation is Map) {
        _selectedCity = Map<String, dynamic>.from(existingLocation);
        _searchController.text = '${_selectedCity!['name']}, ${_selectedCity!['adminCode1']}';
      }
      
    } catch (e) {
      print('qual: Error loading existing values - $e');
    }
    
    setState(() {
      _isInitialized = true;
      _isLoadingData = false;
    });
  }

  @override
  void dispose() {
    _removeOverlay();
    _searchController.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    _removeOverlay();
    
    final RenderBox? renderBox = _textFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      print('DEBUG: RenderBox is null');
      return;
    }
    
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    
    print('DEBUG: TextField position - left: ${offset.dx}, top: ${offset.dy}, width: ${size.width}, height: ${size.height}');
    print('DEBUG: Suggestions count: ${_suggestions.length}');

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: 32, // Match the padding from parent
        right: 32, // Match the padding from parent
        top: offset.dy + size.height + 5,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 250),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red, // Temporarily red to see if it's rendering
                width: 2,
              ),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              shrinkWrap: true,
              itemCount: _suggestions.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Colors.grey.shade200,
              ),
              itemBuilder: (context, index) {
                final city = _suggestions[index];
                return InkWell(
                  onTap: () {
                    print('DEBUG: City tapped: ${city['name']}');
                    setState(() {
                      _selectedCity = city;
                      _searchController.text = '${city['name'] ?? ''}, ${city['adminCode1'] ?? ''}';
                      _suggestions = [];
                    });
                    _removeOverlay();
                  },
                  child: Container(
                    color: Colors.blue.withOpacity(0.1), // Temporary background
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      '${city['name'] ?? ''}, ${city['adminCode1'] ?? ''}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    print('DEBUG: Overlay inserted');
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
    print('DEBUG: searchCities called with query: $query');
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
      });
      _removeOverlay();
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Use HTTPS instead of HTTP
      final response = await http.get(Uri.parse(
        'https://secure.geonames.org/searchJSON?q=$query&maxRows=5&username=jmocko&country=US&featureClass=P'
      ));

      print('DEBUG: API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = List<Map<String, dynamic>>.from(data['geonames']);
        print('DEBUG: Got ${results.length} results');
        setState(() {
          _suggestions = results;
          _isLoading = false;
        });
        
        if (_suggestions.isNotEmpty) {
          print('DEBUG: Calling _showOverlay');
          _showOverlay();
        } else {
          _removeOverlay();
        }
      }
    } catch (e) {
      print('DEBUG: Error in searchCities: $e');
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
      _removeOverlay();
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
                  
                  Container(
                    key: _textFieldKey,
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
                        suffixIcon: _isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : Icon(
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
              await inputState.saveInputToRemoteThenLocal(inputData);
              if (context.mounted) {
                Navigator.pushNamed(context, AppRoutes.editNeeds, arguments: inputData);
              }
            } else {
              await inputState.saveInputToRemoteThenLocalInOnboarding(inputData);
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