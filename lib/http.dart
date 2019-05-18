import 'dart:async';
import 'dart:convert';
import 'dart:io';


class Http {
  final client = HttpClient();

  Future<dynamic> get() async {
    final url = Uri.https("www.wanandroid.com", "/wxarticle/chapters/json");
    final request = await client.getUrl(url);
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    print("http success");
    Map<String, dynamic> data = json.decode(body);
    return data['data'];
  }
}
