import 'dart:convert';
import 'package:http/http.dart' as http;
import 'data.dart';

class AirtableService {
  final String apiKey = 'pathv5g07vtToPW3g.d3cc20dffd1ebaeab0c8c19053a5a8ce0668f838b47dba7909c1fc8b3f571292';
  final String baseUrl = 'https://api.airtable.com/v0/appe11umTCa3q8cg7/tblGb4zcZ3PT6fIjT';

  // Function to fetch data from Airtable
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

  // Function to post data to Airtable
  Future<void> postData(Map<String, dynamic> fields) async {
    final url = Uri.parse(baseUrl);
    final response = await http.post(url, headers: {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json'
    }, body: json.encode({
      "fields": fields
    }));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to post data: ${response.body}');
    } else {
      print('Data submitted successfully');
    }
  }

}