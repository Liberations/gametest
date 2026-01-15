// HTTP helper for native platforms (iOS, Android, Desktop)
import 'dart:convert';
import 'dart:io';

class HttpResponse {
  final int statusCode;
  final String body;
  HttpResponse(this.statusCode, this.body);
}

Future<HttpResponse> httpGet(String url, Map<String, String> params) async {
  final uri = Uri.parse(url).replace(queryParameters: params);
  final client = HttpClient();
  try {
    final request = await client.getUrl(uri);
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    return HttpResponse(response.statusCode, body);
  } finally {
    client.close();
  }
}

Future<HttpResponse> httpPost(String url, Map<String, dynamic> data) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(Uri.parse(url));
    request.headers.set('Content-Type', 'application/json');
    request.write(jsonEncode(data));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    return HttpResponse(response.statusCode, body);
  } finally {
    client.close();
  }
}
