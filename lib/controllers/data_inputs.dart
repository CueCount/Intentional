import 'package:flutter/material.dart';

class Input {
  final String title;
  final List<dynamic> possibleValues; 
  final String type;
  Input({required this.title, required this.possibleValues, required this.type, });
  Map<String, dynamic> toJson() {
    return {'Title': title, 'PossibleValues': possibleValues, 'Type': type, };
  }
  factory Input.fromJson(Map<String, dynamic> json) {
    return Input(title: json['Title'], possibleValues: List<int>.from(json['PossibleValues']), type: json['Type'],);
  }
}

List<Input> mateAttInputs = [
  Input(
    title: "MateAttribute",
    possibleValues: [
      "Physically Strong and Bruiting",
      "Mature and Thoughtful",
      "Assertive and Leading",
      "Intelligent and Nerdy",
      "Spontaneous and Romantic",
      "High Earning High Status",
      ],
    type: "checkbox"),
];

List<Input> logisticsInputs = [
  Input(
    title: "Plan Dates",
    possibleValues: [0, 100],
    type: "slider",
  ),
  Input(
    title: "Pay for Dates",
    possibleValues: [0, 100],
    type: "slider",
  ),
  Input(
    title: "Plan Trips",
    possibleValues: [0, 100],
    type: "slider",
  ),
  Input(
    title: "Pay for Trips",
    possibleValues: [0, 100],
    type: "slider",
  ),
];

List<Input> laborInputs = [
  Input(
    title: "Do More Home Chores",
    possibleValues: [0, 100],
    type: "slider",
  ),
  Input(
    title: "Earn More Money",
    possibleValues: [0, 100],
    type: "slider",
  ),
];

List<Input> emotionalInputs = [
  Input(
    title: "More Empathic",
    possibleValues: [0, 100],
    type: "slider",
  ),
  Input(
    title: "More Strong-Willed and Decisive",
    possibleValues: [0, 100],
    type: "slider",
  ),
  Input(
    title: "More Charismatic and Entertaining",
    possibleValues: [0, 100],
    type: "slider",
  ),
];

List<Input> statusInputs = [
  Input(
    title: "Generous Time",
    possibleValues: [0, 100],
    type: "slider",
  ),
  Input(
    title: "Higher Status",
    possibleValues: [0, 100],
    type: "slider",
  ),
];

List<Input> timeSpentInputs = [
  Input(
    title: "Time Spend During Dating",
    possibleValues: [0, 100],
    type: "slider",
  ),
  Input(
    title: "Time Spend During Relationship",
    possibleValues: [0, 100],
    type: "slider",
  ),
];

List<Input> toneInputs = [
  Input(
    title: "Tone",
    possibleValues: [0, 100],
    type: "slider",
  ),
  Input(
    title: "Expectations",
    possibleValues: [0, 100],
    type: "slider",
  ),
];