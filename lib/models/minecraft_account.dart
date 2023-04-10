import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:launcher/utils/data.dart';

class MinecraftAccount {
  String uuid = "", username = "";
  String xblToken = "", bearer = "";

  MinecraftAccount(this.xblToken, this.bearer);
  MinecraftAccount.load(this.uuid, this.username);
  MinecraftAccount.loadFull(
      this.uuid, this.username, this.xblToken, this.bearer);

  Future<bool> owned() async {
    final response = await http.post(
      Uri.parse("$minecraftApi/entitlements/mcstore"),
      headers: {"Authorization": bearer},
    );

    return response.body.contains('"game_minecraft"') ||
        response.body.contains('"product_minecraft"');
  }

  Future<void> loadProfile() async {
    final response = await http.get(
      Uri.parse("$minecraftApi/minecraft/profile"),
      headers: {"Authorization": "Bearer $bearer"},
    );

    try {
      Map body = json.decode(response.body);
      uuid = body['id'];
      username = body['name'];
    } catch (e) {
      return;
    }
  }

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'username': username,
        'xblToken': xblToken,
        'bearer': bearer,
      };
}
