import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'data_object.dart';
import 'airtable.dart';

class DataService {
  
  static const String cacheKey = 'dynamicData';
  final AirtableService airtableService = AirtableService();
  
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
  Data Handling Logic
   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  void storeRecordId(String recordId) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('recordId', recordId);
  }

  Future<String?> getRecordId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('recordId');
  }

  Future<void> handleSubmit(DynamicData data) async {
    Map<String, dynamic> inputData = data.toJson();
    String? recordId = await getRecordId();

    if (recordId == null) {
      recordId = await airtableService.createData(inputData);  // Use instance of airtableService
      if (recordId != null) {
        storeRecordId(recordId); 
      }
    } else {
      await airtableService.postData(recordId, inputData);  // Use instance for postData as well
    }
  }

}