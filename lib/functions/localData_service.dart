import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/inputState.dart';

class LocalDataService {
  static const String _userDataKey = 'user_data';
  static const String _tempUserIdKey = 'temp_user_id';
  static const String _matchesKey = 'matches_data';
  static const String _routeStatusKey = 'route_status';

  /* = = = = = = = = = 
  createUserId 
  = = = = = = = = = */
  static Future<String> createUserId() async {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = List.generate(28, (index) => chars[(DateTime.now().millisecondsSinceEpoch + index) % chars.length]).join();
    return rand;
  }
  
  /* = = = = = = = = = 
  saveToInputState 
  = = = = = = = = = */
  static void saveToInputState({
    required BuildContext context,
    required Map<String, dynamic> data,
  }) {
    final inputState = Provider.of<InputState>(context, listen: false);
    inputState.cacheInputs(data);
    final fullData = inputState.getCachedInputs();
    print('✅ Data saved to InputState:\n$fullData');
  }

  /* = = = = = = = = = 
  fetchFromInputState 
  = = = = = = = = = */
  static Map<String, dynamic> fetchFromInputState(
    BuildContext context
  ) {
    final inputState = Provider.of<InputState>(context, listen: false);
    final data = inputState.getCachedInputs();
    print('📥 Data fetched from InputState:\n$data');
    return data;
  }

  /* = = = = = = = = = 
  saveToSharedPref 
  = = = = = = = = = */
  static Future<void> saveToSharedPref({
    required Map<String, dynamic> data,
    required String userId,
    String? customKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = customKey ?? 'user_data_$userId';
    String? existingDataJson = prefs.getString(key);
    Map<String, dynamic> existingData = {};
    if (existingDataJson != null && existingDataJson.isNotEmpty) {
      Map rawData = json.decode(existingDataJson);
      rawData.forEach((k, v) => existingData[k.toString()] = v);
    }
    final mergedData = {
      ...existingData,
      ...data,
      'temp_user_id': userId,
      'last_updated': DateTime.now().toIso8601String(),
    };
    await prefs.setString(key, json.encode(mergedData));
    print('✅ Data saved to SharedPreferences under key "$key":\n$mergedData');
  }
  
}