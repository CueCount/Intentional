import '../inputs/input_config.dart';


class DynamicData {
  final List<Input> inputs;

  DynamicData({required this.inputs});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> fields = {};
    for (var input in inputs) {
      fields[input.title] = input.toJson();
    }
    return {
      'fields': fields,
    };
  }

  factory DynamicData.fromJson(Map<String, dynamic> json) {
    final inputs = (json['fields'] as Map<String, dynamic>).entries.map((entry) {
      return Input(
        title: entry.key,
        possibleValues: List<int>.from(entry.value['PossibleValues']),
      );
    }).toList();
    return DynamicData(inputs: inputs);
  }
}