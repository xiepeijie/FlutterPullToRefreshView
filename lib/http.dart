import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'data.dart';


class Http {
  final client = HttpClient();

  Future<List<Data>> get() async {
    final url = Uri.https("www.wanandroid.com", "/wxarticle/chapters/json");
    final request = await client.getUrl(url);
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    print("http success");
    Map<String, dynamic> data = json.decode(body);
    List<dynamic> datas = data['data'];
    return datas.map((item) => Data.fromJson(item)).toList();
  }
}
