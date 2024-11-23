import 'data_inputs.dart';
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
This file holds functions that take input data and convert it to and from JSON
 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
 
class DynamicData {
  final Map<String, dynamic> inputValues;
  DynamicData({required this.inputValues,});

  Map<String, dynamic> toJson() {
    print(inputValues);
    return inputValues; 
  }

  factory DynamicData.fromJson(Map<String, dynamic> json) {
    final inputs = (json['fields'] as Map<String, dynamic>).entries.map((entry) {
      return Input(
        title: entry.key,
        possibleValues: List<int>.from(entry.value['PossibleValues']),
        type: entry.value['type'],
      );
    }).toList();

    return DynamicData(
      inputValues: {}, 
    );
  }
}