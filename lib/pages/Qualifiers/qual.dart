import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/appBar.dart';
import '/router/router.dart';
import '../../widgets/input_slider.dart';
import '../../styles.dart';
import '../../data/data_inputs.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../widgets/navigation.dart';

class QualifierRelDate extends StatefulWidget {
  const QualifierRelDate({super.key, required this.title});
  final String title;
  @override
  State<QualifierRelDate> createState() => _QualifierRelDate();
}

class _QualifierRelDate extends State<QualifierRelDate> {
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  VALUES
   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  Map<String, dynamic> inputValues = {};
  Map<String, Map<String, bool>> groupSelectedValues = {};
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
      setState(() {});
    });
  }

  Map<String, dynamic> getSelectedAttributes() {
    final inputState = Provider.of<InputState>(context);
    Map<String, List<String>> selections = {};
    for (var input in inputState.qual) {
      selections[input.title] = groupSelectedValues[input.title]!.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();
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
    Map<String, dynamic> inputData = getSelectedAttributes();
    return Scaffold( 
      body: Container (
        padding: const EdgeInsets.all(20), // 20px padding on all sides
        decoration: const BoxDecoration(
          gradient: ColorPalette.brandGradient,
        ),
      child: Column(
      children: [
        
        const CustomStatusBar(
              messagesCount: 2,
              likesCount: 5,
            ),
      
      Expanded(
      child: ListView(
        children: <Widget>[
          for (var input in inputState.qual)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    input.title,
                    style: AppTextStyles.headingMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (input.type == "checkbox") ...[
                  Wrap(
                    alignment: WrapAlignment.spaceEvenly,
                    children: input.possibleValues.map((value) =>  
                      SizedBox(  
                        width: 160,
                        height: 160,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CheckboxListTile(
                              title: Text(
                                value,  
                                textAlign: TextAlign.center,
                              ),
                              value: groupSelectedValues[input.title]![value],
                              onChanged: (bool? checked) {
                                setState(() {
                                  for (var v in input.possibleValues) {
                                    groupSelectedValues[input.title]![v] = false;
                                  }
                                  groupSelectedValues[input.title]![value] = checked ?? false;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ).toList(),
                  ),
                ],
              ],
            ), 
            
            Center(
              child: Text(
                'In',
                style: AppTextStyles.headingMedium,
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 20),

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
                  hintText: 'Enter your city',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  suffixIcon: const Icon(Icons.location_on_outlined),
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
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final city = _suggestions[index];
                    return ListTile(
                      title: Text('${city['name']}, ${city['adminCode1']}'),
                      onTap: () {
                        setState(() {
                          _selectedCity = city;
                          _searchController.text = 
                              '${city['name']}, ${city['adminCode1']}';
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
      ),
    ),
      bottomNavigationBar: CustomAppBar(
        route: AppRoutes.emotionalNeeds, 
        inputValues: inputData,
      ),
    );
  }
}