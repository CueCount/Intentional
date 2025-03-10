import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/appBar.dart';
import '../../widgets/custom_drawer.dart';
import '/router/router.dart';
import '../../widgets/input_slider.dart';
import '../../styles.dart';
import '../../data/data_inputs.dart';

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

  @override
  Widget build(BuildContext context) {
    final inputState = Provider.of<InputState>(context);
    Map<String, dynamic> inputData = getSelectedAttributes();
    return Scaffold( 
      endDrawer: const CustomDrawer(), 
      body: ListView(
        children: <Widget>[
          for (var input in inputState.qual)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(input.title), 
                if (input.type == "slider") ...[
                  CustomSlider(
                    label: input.title,
                    initialValue: inputValues[input.title]!,
                    min: input.possibleValues[0].toDouble(),
                    max: input.possibleValues[1].toDouble(),
                    divisions: 20,
                    onChanged: (value) {
                      setState(() {
                        inputValues[input.title] = value; 
                      });
                    },
                  ),
                ] else if (input.type == "checkbox") ...[
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
              ], // Children
            ),
        ],
      ),
      bottomNavigationBar: CustomAppBar(
        route: AppRoutes.location, 
        inputValues: inputData,
      ),
    );
  }
}