import 'package:flutter/material.dart';
import '/router/router.dart';
import '../../widgets/appBar.dart';
import '../../widgets/custom_drawer.dart';
import '../../widgets/input_checkbox.dart';  
import '../../controllers/data_functions.dart';
import '../../controllers/data_object.dart';
import '../../controllers/data_inputs.dart';

class MateAttributes extends StatefulWidget {
  const MateAttributes({super.key, required this.title});
  final String title;
  @override
  State<MateAttributes> createState() => _MateAttributes();
}

class _MateAttributes extends State<MateAttributes> {
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  VALUES
   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  Map<String, dynamic> inputValues = {};
  DataService dataService = DataService();
  Map<String, bool> selectedValues = {};
  @override
  void initState() {
    super.initState();
    for (var input in mateAttInputs) {
      for (var value in input.possibleValues) {
        selectedValues[value] = false;
      }
    }
  }

  // Function to gather selected values and prepare them as an array
  Map<String, dynamic> getSelectedAttributes() {
    return {
      "MateAttribute": selectedValues.entries
          .where((entry) => entry.value)  // Only selected entries
          .map((entry) => entry.key)       // Get the selected keys
          .toList(),                       // Convert to a list
    };
  }

  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  SCAFFOLD
   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  @override
  Widget build(BuildContext context) { 
    return Scaffold( 
      appBar: CustomAppBar(
        title: widget.title,
        isLoggedIn: true,
        hasSubmittedForm: true,
      ),
      endDrawer: CustomDrawer(), 

      body: GridView.builder(
        padding: EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.0,
        ),
        itemCount: mateAttInputs[0].possibleValues.length,
        itemBuilder: (context, index) {
          String attribute = mateAttInputs[0].possibleValues[index];  // Get the individual attribute

          return CustomCheckbox(
            attribute: MateAttribute(
              title: attribute,
              description: '',  // Description can be left empty or adjusted
              isSelected: selectedValues[attribute] ?? false,
            ),
            onChanged: (isSelected) {
              setState(() {
                selectedValues[attribute] = isSelected;
              });
            },
            isSelected: selectedValues[attribute] ?? false,
          );
        },
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: MaterialButton(
          onPressed: () {
            Map<String, dynamic> inputData = getSelectedAttributes();
            dataService.handleSubmit(DynamicData(inputValues: inputData));
            Navigator.pushNamed(context, AppRoutes.logistics);
          },
          child: Text('Begin'),
          color: Color.fromARGB(255, 226, 33, 243),
          height: 50,
          minWidth: double.infinity,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      /*body: ListView(
        children: <Widget>[
          CustomCheckbox(
            title: 'Physically Strong and Bruiting',
            initialValue: true,
            onChanged: (value) {
              // Handle change
              print("Physically Strong and Bruiting: $value");
            },
          ),
          CustomCheckbox(
            title: 'Mature and Thoughtful',
            initialValue: false,
            onChanged: (value) {
              // Handle change
              print("Mature and Thoughtful: $value");
            },
          ),
          CustomCheckbox(
            title: 'Assertive and Leading',
            initialValue: false,
            onChanged: (value) {
              // Handle change
              print("Assertive and Leading: $value");
            },
          ),
          CustomCheckbox(
            title: 'Intelligent and Nerdy',
            initialValue: false,
            onChanged: (value) {
              // Handle change
              print("Intelligent and Nerdy: $value");
            },
          ),
          CustomCheckbox(
            title: 'Spontaneous and Romantic',
            initialValue: false,
            onChanged: (value) {
              // Handle change
              print("Spontaneous and Romantic: $value");
            },
          ),
          CustomCheckbox(
            title: 'High Earning High Status',
            initialValue: false,
            onChanged: (value) {
              // Handle change
              print("High Earning High Status: $value");
            },
          ),
          MaterialButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.logistics);
            },
            child: const Text('Begin'),
            color: const Color.fromARGB(255, 226, 33, 243),
          ),
        ],
      ),*/

    );

  }
}
