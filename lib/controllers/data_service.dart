import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'data.dart';
import 'airtable.dart';

class DataService {
  static const String cacheKey = 'dynamicData';
  final AirtableService airtableService = AirtableService();

  // Cache data locally
  Future<void> cacheData(DynamicData data) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(cacheKey, jsonEncode(data.toJson()));
  }

  // Submit data to Airtable
  Future<void> submitData(DynamicData data) async {
    try {
      await airtableService.postData(data.toJson());
    } catch (e) {
      print('Failed to submit data: $e');
    }
  }

  // Load cached data
  Future<DynamicData> loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(cacheKey);
    if (data != null) {
      final jsonData = jsonDecode(data) as Map<String, dynamic>;
      return DynamicData.fromJson(jsonData);
    }
    return DynamicData(inputs: []);
  }

  // Fetch data from Airtable and cache it locally
  Future<void> fetchDataAndCache() async {
    try {
      final records = await airtableService.fetchData();
      // Assuming records are in the format needed for DynamicData.fromJson
      final dynamicData = DynamicData.fromJson({
        'fields': { for (var record in records) record['fields']['Title']: record['fields'] }
      });
      await cacheData(dynamicData);
    } catch (e) {
      print('Failed to fetch and cache data: $e');
    }
  }
  
}