import 'dart:convert';
import 'package:http/http.dart' as http;

class AirtableData {
  final String apiKey = 'pathv5g07vtToPW3g.d3cc20dffd1ebaeab0c8c19053a5a8ce0668f838b47dba7909c1fc8b3f571292';
  final String baseUrl = 'https://api.airtable.com/v0/appe11umTCa3q8cg7/tblGb4zcZ3PT6fIjT';

  // Function to fetch data from Airtable
  Future<List> fetchData() async {
    final url = Uri.parse(baseUrl);
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json'
    });

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      List records = data['records'];
      return records;
    } else {
      throw Exception('Failed to load data');
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

    if (response.statusCode != 200) {
      throw Exception('Failed to post data');
    }
  }
}

AirtableData airtableData = AirtableData();

void saveInput(String inputType, dynamic value) {
  airtableData.postData({
    'PreferenceType': inputType,
    'Value': value,
  });
}