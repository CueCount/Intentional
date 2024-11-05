import 'package:flutter/material.dart';
import '/router/router.dart';
import '../../widgets/appBar.dart';
import '../../widgets/custom_drawer.dart';
import '../../widgets/input_checkbox.dart';  
import '../../controllers/data_functions.dart';
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

  Map<String, dynamic> getSelectedAttributes() {
    return {
      "MateAttribute": selectedValues.entries
          .where((entry) => entry.value)  
          .map((entry) => entry.key)       
          .toList(),                       
    };
  }

  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  SCAFFOLD
   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> inputData = getSelectedAttributes();
    return Scaffold(
      endDrawer: CustomDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.0,
          ),
          itemCount: mateAttInputs.isNotEmpty ? mateAttInputs[0].possibleValues.length : 0,
          itemBuilder: (context, index) {
            if (mateAttInputs.isEmpty || index >= mateAttInputs[0].possibleValues.length) {
              return const SizedBox.shrink();
            }
            String attribute = mateAttInputs[0].possibleValues[index];  
            return CustomCheckbox(
              attribute: MateAttribute(
                title: attribute,
                description: '',  
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
      ),
      bottomNavigationBar: CustomAppBar(
        route: AppRoutes.logistics, 
        inputValues: inputData,
      ),
    );
  }
}
