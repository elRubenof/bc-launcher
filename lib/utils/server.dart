import 'dart:math';

class Server {
  static bool isActive = false;
  static List players = [];

  static Future<void> init() async {
    isActive = await _getStatus();
    if (!isActive) return;

    players = await _getPlayers();
  }

  static Future<bool> _getStatus() async {
    return true;
  }

  static Future<List> _getPlayers() async {
    final p = [
      {
        "uuid": "elRubenof",
        "displayName": "phybros",
        "address": "localhost",
        "port": 58529,
        "exhaustion": 3.5640976,
        "exp": 0.45454547,
        "whitelisted": false,
        "banned": false,
        "op": true
      },
      {
        "uuid": "DrMixaDj",
        "displayName": "phybros",
        "address": "localhost",
        "port": 58529,
        "exhaustion": 3.5640976,
        "exp": 0.45454547,
        "whitelisted": false,
        "banned": false,
        "op": true
      },
      {
        "uuid": "ancao2",
        "displayName": "phybros",
        "address": "localhost",
        "port": 58529,
        "exhaustion": 3.5640976,
        "exp": 0.45454547,
        "whitelisted": false,
        "banned": false,
        "op": true
      },
      {
        "uuid": "Ciempi_17",
        "displayName": "phybros",
        "address": "localhost",
        "port": 58529,
        "exhaustion": 3.5640976,
        "exp": 0.45454547,
        "whitelisted": false,
        "banned": false,
        "op": true
      },
      {
        "uuid": "ForceX_TV",
        "displayName": "phybros",
        "address": "localhost",
        "port": 58529,
        "exhaustion": 3.5640976,
        "exp": 0.45454547,
        "whitelisted": false,
        "banned": false,
        "op": true
      },
      {
        "uuid": "Bruno_4D",
        "displayName": "phybros",
        "address": "localhost",
        "port": 58529,
        "exhaustion": 3.5640976,
        "exp": 0.45454547,
        "whitelisted": false,
        "banned": false,
        "op": true
      },
      {
        "uuid": "NataliaFerHeras",
        "displayName": "phybros",
        "address": "localhost",
        "port": 58529,
        "exhaustion": 3.5640976,
        "exp": 0.45454547,
        "whitelisted": false,
        "banned": false,
        "op": true
      },
      {
        "uuid": "Naru2712",
        "displayName": "phybros",
        "address": "localhost",
        "port": 58529,
        "exhaustion": 3.5640976,
        "exp": 0.45454547,
        "whitelisted": false,
        "banned": false,
        "op": true
      },
      {
        "uuid": "podojo30405",
        "displayName": "phybros",
        "address": "localhost",
        "port": 58529,
        "exhaustion": 3.5640976,
        "exp": 0.45454547,
        "whitelisted": false,
        "banned": false,
        "op": true
      },
    ];

    return p.sublist(0, Random().nextInt(p.length) + 1);
  }
}
