import 'dart:convert';
import 'package:http/http.dart' as http;

import 'data.dart';

class Server {
  static bool isActive = false;
  static List players = [];
  static List news = [];

  static dynamic _response;

  static Future<void> init() async {
    news = await _getNews();

    final x = await http
        .get(Uri.parse("https://api.mcstatus.io/v2/status/java/$serverIp"));
    _response = json.decode(x.body);

    isActive = await _getStatus();
    if (!isActive) return;

    players = await _getPlayers();
  }

  static Future<bool> _getStatus() async {
    try {
      return _response['online'];
    } catch (e) {
      return false;
    }
  }

  static Future<List> _getPlayers() async {
    return _response['players']['list'];
  }

  static Future<List> _getNews() async {
    final x = await http
        .get(Uri.parse("https://spartaland.es/news"));

    return json.decode(utf8.decode(x.bodyBytes));
  }
}
