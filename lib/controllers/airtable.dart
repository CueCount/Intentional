import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AirtableService {
  final String apiKey = 'pathv5g07vtToPW3g.d3cc20dffd1ebaeab0c8c19053a5a8ce0668f838b47dba7909c1fc8b3f571292';
  final String baseUrl = 'https://api.airtable.com/v0/appe11umTCa3q8cg7/tblGb4zcZ3PT6fIjT';

  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
  CREATE NEW ROW AIRTABLE
   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  Future<String?> createData(Map<String, dynamic> fields) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json',},
        body: jsonEncode({'fields': fields,}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['id']; 
      } else {
        throw Exception('Failed to create record: ${response.body}');
      }
    } catch (e) {
      print('Error creating record: $e');
      return null;
    }
  }

  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
  UPDATE EXISTING ROW 
  } - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  Future<void> postData(String recordId, Map<String, dynamic> fields) async {
    final String updateUrl = '$baseUrl/$recordId';

    try {
      final response = await http.patch(
        Uri.parse(updateUrl),
        headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json',},
        body: jsonEncode({'fields': fields,}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update record: ${response.body}');
      }
    } catch (e) {
      print('Error updating record: $e');
    }
  }

  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
  Fetch data from Airtable
   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  Future<List<Map<String, dynamic>>> fetchData() async {
    final url = Uri.parse(baseUrl);
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json'
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch data: ${response.body}');
    } else {
      final Map<String, dynamic> responseData = json.decode(response.body);
      return List<Map<String, dynamic>>.from(responseData['records']);
    }
  }

}