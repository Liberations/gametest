// HTTP helper for Web platform
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

class HttpResponse {
  final int statusCode;
  final String body;
  HttpResponse(this.statusCode, this.body);
}

Future<HttpResponse> httpGet(String url, Map<String, String> params) async {
  final uri = Uri.parse(url).replace(queryParameters: params);

  try {
    final body = await html.HttpRequest.getString(uri.toString());
    return HttpResponse(200, body);
  } catch (e) {
    // Try to get status from error if it's a ProgressEvent
    if (e is html.ProgressEvent) {
      final target = e.target;
      if (target is html.HttpRequest) {
        return HttpResponse(target.status ?? 0, target.responseText ?? '');
      }
    }
    return HttpResponse(0, '');
  }
}

Future<HttpResponse> httpPost(String url, Map<String, dynamic> data) async {
  final request = html.HttpRequest();
  request.open('POST', url);
  request.setRequestHeader('Content-Type', 'application/json');

  final completer = Completer<HttpResponse>();

  request.onLoad.listen((event) {
    completer.complete(HttpResponse(request.status ?? 0, request.responseText ?? ''));
  });

  request.onError.listen((event) {
    completer.complete(HttpResponse(0, ''));
  });

  request.send(jsonEncode(data));

  return completer.future;
}
