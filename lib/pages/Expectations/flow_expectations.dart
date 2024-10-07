import 'package:flutter/material.dart';
import '../../widgets/appBar.dart';
import '../../widgets/custom_drawer.dart';
import '../../inputs/input_config.dart';
import '../../widgets/input_grid_checkbox.dart';
import '../../widgets/input_slider.dart';

class PageConfig {
  final String title;
  final dynamic inputs;
  final String nextPage;

  PageConfig({required this.title, required this.inputs, required this.nextPage});
}
Input mateAttributesInput = inputs.firstWhere(
  (input) => input.title == "MateAttribute", // Make sure the title matches exactly
);
// Pages definition
List<PageConfig> pages = [
  PageConfig(
    title: "Mate Attributes",
    inputs: mateAttributesInput,
    nextPage: "Logistics",
  ),
  /*PageConfig(
    title: "Logistics",
    inputs: ["Plan Dates", "Pay for Dates", "Plan Trips", "Pay for Trips"],
    nextPage: "Page_02",
  ),*/
  // Define more pages as needed
];

class MyPage extends StatelessWidget {
  final List<Input> pages;

  MyPage({Key? key, required this.pages}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Dynamic Pages for Expectations",
        isLoggedIn: true,
        hasSubmittedForm: true,
      ),
      endDrawer: CustomDrawer(), 
      body: Column(

        /*children: <Widget>[
          for (var input in pages)
            Container(
              padding: EdgeInsets.all(8.0),
              child: _buildInputWidget(input),
            ),
          ElevatedButton(
            onPressed: () {print("Submit");},
            child: Text("Submit"),
          ),
        ],*/
      ),
    );
  }

  /*Widget _buildInputWidget(Input input) {
    switch (input.type) {
      case "Checkbox":
        return CheckboxGrid(title: input.title);
      case "Slider":
        return CustomSlider();
      case "Slider_Categorical":
        return CustomSlider();
      default:
        return Text("Unknown input type");
    }
  }*/
}