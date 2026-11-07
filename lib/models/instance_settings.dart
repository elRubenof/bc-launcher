import 'package:bc_launcher/models/instance.dart';
import 'package:bc_launcher/utils/constants.dart';

/// The game settings the player changed for one instance
/// (`.bc-launcher/settings.json`). What isn't changed is null and takes its
/// default, so a new recommended RAM applies until the player picks one.
class InstanceSettings {
  final int? ramGb;
  final int? gameWidth;
  final int? gameHeight;
  final bool? fullscreen;
  final bool? autoConnect;

  const InstanceSettings({
    this.ramGb,
    this.gameWidth,
    this.gameHeight,
    this.fullscreen,
    this.autoConnect,
  });

  static const empty = InstanceSettings();

  factory InstanceSettings.fromJson(Map<String, dynamic> json) {
    return InstanceSettings(
      ramGb: json['ramGb'],
      gameWidth: json['gameWidth'],
      gameHeight: json['gameHeight'],
      fullscreen: json['fullscreen'],
      autoConnect: json['autoConnect'],
    );
  }

  Map<String, dynamic> toJson() => {
    'ramGb': ?ramGb,
    'gameWidth': ?gameWidth,
    'gameHeight': ?gameHeight,
    'fullscreen': ?fullscreen,
    'autoConnect': ?autoConnect,
  };

  InstanceSettings copyWith({
    int? ramGb,
    int? gameWidth,
    int? gameHeight,
    bool? fullscreen,
    bool? autoConnect,
  }) {
    return InstanceSettings(
      ramGb: ramGb ?? this.ramGb,
      gameWidth: gameWidth ?? this.gameWidth,
      gameHeight: gameHeight ?? this.gameHeight,
      fullscreen: fullscreen ?? this.fullscreen,
      autoConnect: autoConnect ?? this.autoConnect,
    );
  }

  /// The GB the game gets: the player's, or else [instance]'s recommended
  /// (rounded up), or else the default; never more than [maxGb].
  int ram(Instance instance, int maxGb) {
    final recommended = instance.recommendedRamMb;
    final gb =
        ramGb ??
        (recommended != null ? (recommended / 1024).ceil() : null) ??
        Constants.defaultAllocatedRAM;
    return gb.clamp(1, maxGb < 1 ? 1 : maxGb);
  }

  int get width => gameWidth ?? Constants.defaultGameWidth;
  int get height => gameHeight ?? Constants.defaultGameHeight;
  bool get isFullscreen => fullscreen ?? Constants.defaultFullscreen;
  bool get connects => autoConnect ?? Constants.defaultAutoConnect;
}
