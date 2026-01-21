// HTTP helper for all platforms (web, mobile, desktop)
import 'dart:convert';
import 'package:http/http.dart' as http;

class HttpResponse {
  final int statusCode;
  final String body;
  HttpResponse(this.statusCode, this.body);
}

Future<HttpResponse> httpGet(String url, Map<String, String> params) async {
  final uri = Uri.parse(url).replace(queryParameters: params);
  try {
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    return HttpResponse(response.statusCode, response.body);
  } catch (e) {
    // Return a 0 status to indicate network-level failure; caller should handle it
    return HttpResponse(0, e.toString());
  }
}

Future<HttpResponse> httpPost(String url, Map<String, dynamic> data) async {
  final uri = Uri.parse(url);
  try {
    final response = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(data)).timeout(const Duration(seconds: 15));
    return HttpResponse(response.statusCode, response.body);
  } catch (e) {
    return HttpResponse(0, e.toString());
  }
}
