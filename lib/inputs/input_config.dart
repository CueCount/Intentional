import 'package:flutter/material.dart';

class Input {
  final String title;
  final List<dynamic> possibleValues; 

  Input({required this.title, required this.possibleValues});

  Map<String, dynamic> toJson() {
    return {
      'Title': title,
      'PossibleValues': possibleValues,
    };
  }
  
  factory Input.fromJson(Map<String, dynamic> json) {
    return Input(
      title: json['Title'],
      possibleValues: List<int>.from(json['PossibleValues']),
    );
  }
}

// Example configurations
List<Input> inputs = [
  // Mate Attributes Page
  Input(
    title: "MateAttribute",
    possibleValues: ["Physically Strong and Bruiting", "Mature and Thoughtful", "Assertive and Leading"],//type: "Checkbox",
  ),

  // Logistics Page
  Input(
    title: "Plan Dates",
    possibleValues: ["Mostly Me", "Mostly Equal", "Mostly Them"],//type: "slider_categorical",
  ),
  Input(
    title: "Pay for Dates",
    possibleValues: ["Mostly Me", "Mostly Equal", "Mostly Them"],//type: "slider_categorical",
  ),
  Input(
    title: "Plan Trips",
    possibleValues: ["Mostly Me", "Mostly Equal", "Mostly Them"],//type: "slider_categorical",
  ),
  Input(
    title: "Pay for Trips",
    possibleValues: ["Mostly Me", "Mostly Equal", "Mostly Them"],//type: "slider_categorical",
  ),

  // Labor Dynamics Page
  Input(
    title: "Do More Home Chores",
    possibleValues: [0, 100],//type: "slider",
  ),
  Input(
    title: "Earn More Money",
    possibleValues: [0, 100],//type: "slider",
  ),

  // Emotional Dynamics Page 
  Input(
    title: "More Empathic",
    possibleValues: [0, 100],//type: "slider",
  ),
  Input(
    title: "More Strong-Willed and Decisive",
    possibleValues: [0, 100],//type: "slider",
  ),
  Input(
    title: "More Charismatic and Entertaining",
    possibleValues: [0, 100],//type: "slider",
  ),
  
  // Status Dynamics Page 
  Input(
    title: "Who should be more generous with their time?",
    possibleValues: [0, 100],//type: "slider",
  ),
  Input(
    title: "Who should have a higher social/career status & accomplishments?",
    possibleValues: [0, 100],//type: "slider",
  ),

  // Time Spent Together Page 
  Input(
    title: "Pay for Trips",
    possibleValues: ["Less Than Once Per Week", "Once Per Week", "More Than Once Per Week"],//type: "slider_categorical",
  ),
  Input(
    title: "Pay for Trips",
    possibleValues: ["Once Per Week", "2-3 Times Per Week", "Everyday Or Almost"],//type: "slider_categorical",
  ),

  // Tone Page 
  Input(
    title: "More Transactionally Based, or Authentically Based?",
    possibleValues: [0, 100],//type: "slider",
  ),
  Input(
    title: "How flexible are you with your specific expectations?",
    possibleValues: [0, 100],//type: "slider",
  ),
];