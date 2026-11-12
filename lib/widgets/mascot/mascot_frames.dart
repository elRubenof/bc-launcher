import 'dart:ui';

/// What the mascot is doing: asleep while there is nothing to do, floating
/// while the launcher works without a progress value, and flying right while
/// it downloads or installs with one.
enum MascotScene { waiting, loading, flying }

/// The mascot's face, the one of assets/img/icon.svg: pixel art on a 14 × 14
/// grid of cells, origin at its top left. Its colors are the logo's own.
abstract final class MascotFace {
  static const size = 14.0;

  /// Corner radius of the body, in cells (14.3 %): the curve ends where the
  /// outer tentacles start.
  static const radius = 2.0;

  static const body = Color(0xFFF4F1EC);
  static const frameColor = Color(0xFF8A5A3C);
  static const lensColor = Color(0xFFFFFFFF);
  static const bridgeColor = Color(0xFFA3A3A3);
  static const mouthColor = Color(0xFF5E5E5E);

  static const frame = [
    Rect.fromLTWH(2, 3, 3, 1),
    Rect.fromLTWH(9, 3, 3, 1),
    Rect.fromLTWH(0, 4, 2, 2),
    Rect.fromLTWH(12, 4, 2, 2),
    Rect.fromLTWH(1, 6, 1, 1),
    Rect.fromLTWH(12, 6, 1, 1),
    Rect.fromLTWH(5, 4, 1, 3),
    Rect.fromLTWH(8, 4, 1, 3),
    Rect.fromLTWH(2, 7, 3, 1),
    Rect.fromLTWH(9, 7, 3, 1),
  ];
  static const lenses = [Rect.fromLTWH(2, 4, 3, 3), Rect.fromLTWH(9, 4, 3, 3)];
  static const bridge = Rect.fromLTWH(6, 5, 2, 1);
  static const smile = [
    Rect.fromLTWH(4, 10, 1, 1),
    Rect.fromLTWH(9, 10, 1, 1),
    Rect.fromLTWH(5, 11, 4, 1),
  ];

  /// The columns the four tentacles hang from; they start at row 13, hidden
  /// under the body.
  static const tentacles = [2.0, 5.0, 8.0, 11.0];

  /// Rows each tentacle has from row 13: the middle two are one longer.
  static int tentacleRows(int i) => i == 1 || i == 2 ? 5 : 4;

  /// A pixel "z" of 4 × 4 cells, from its top left.
  static const z = [
    Rect.fromLTWH(0, 0, 4, 1),
    Rect.fromLTWH(2, 1, 1, 1),
    Rect.fromLTWH(1, 2, 1, 1),
    Rect.fromLTWH(0, 3, 4, 1),
  ];
}

/// One "z" over the sleeping mascot: where its top left is (cells, relative
/// to the body), its scale and opacity.
class MascotZ {
  final Offset position;
  final double scale;
  final double opacity;

  const MascotZ(this.position, this.scale, this.opacity);
}

/// What to paint on one frame, in cells relative to the body's top left.
class MascotFrame {
  /// How far down the body (and everything hanging from it) is moved.
  final double bob;

  /// The tentacles' cells, 1 × 1, painted under the body.
  final List<Rect> tentacles;

  final List<Rect> mouth;
  final List<MascotZ> zs;

  const MascotFrame({
    required this.bob,
    required this.tentacles,
    required this.mouth,
    this.zs = const [],
  });
}

/// The mascot's animation, one frame every [frameDuration]. Every value is a
/// pure function of the frame number, so it can be tested.
abstract final class MascotAnimation {
  static const frameDuration = Duration(milliseconds: 200);

  static const _sway = [0, 1, 0, -1];
  static const _breath = [0.0, 0.15, 0.3, 0.45, 0.6, 0.6, 0.45, 0.3, 0.15, 0.0];

  /// Flying tentacles lean back against the wind in 1-cell diagonals: the
  /// column offset of each row from row 13. Row 14, the first one under the
  /// body, never moves, so they join it without a seam.
  static const leaning = [0, 0, -1, -1, -2];
  static const swept = [0, 0, -1, -2, -3];

  static MascotFrame frame(MascotScene scene, int f) => switch (scene) {
    MascotScene.loading => MascotFrame(
      bob: const [0.0, 0.0, 0.45, 0.45][(f ~/ 4) % 4],
      tentacles: _hanging(f),
      mouth: MascotFace.smile,
    ),
    MascotScene.waiting => _waiting(f),
    MascotScene.flying => _flying(f),
  };

  /// Tentacles hanging down: three rows straight, the tip a column to a side.
  static List<Rect> _hanging(int phase) => [
    for (final (i, x) in MascotFace.tentacles.indexed) ...[
      Rect.fromLTWH(x, 13, 1, 3),
      Rect.fromLTWH(
        x + _sway[(phase + i) % 4],
        16,
        1,
        MascotFace.tentacleRows(i) - 3.0,
      ),
    ],
  ];

  static MascotFrame _waiting(int f) {
    final breath = _breath[(f ~/ 4) % _breath.length];
    return MascotFrame(
      bob: breath,
      // The tentacles barely move: five times slower.
      tentacles: _hanging(f ~/ 5),
      mouth: [Rect.fromLTWH(6, 10, 2, breath >= 0.45 ? 2 : 1)],
      zs: [for (var k = 0; k < 3; k++) _z(((f + k * 12) % 36) / 36)],
    );
  }

  /// A "z" [p] of the way through its rise: it grows, goes up and right, and
  /// fades out after fading in.
  static MascotZ _z(double p) => MascotZ(
    Offset(13 + p * 5, -0.5 - p * 7),
    0.3 + 0.4 * p,
    p < 0.15 ? p / 0.15 : 1 - (p - 0.15) / 0.85,
  );

  /// Flying runs at 1.5 times the speed of the other scenes.
  static double _flyingTime(int f) => f * 1.5;

  static MascotFrame _flying(int f) {
    final t = _flyingTime(f);
    // The same shape for all four at once, so they never touch.
    final shape = const [leaning, leaning, swept, swept][t.floor() % 4];
    return MascotFrame(
      bob: const [0.0, 0.25, 0.5, 0.25][(t / 2).floor() % 4],
      tentacles: [
        for (final (i, x) in MascotFace.tentacles.indexed)
          for (var row = 0; row < MascotFace.tentacleRows(i); row++)
            Rect.fromLTWH(x + shape[row], 13.0 + row, 1, 1),
      ],
      mouth: MascotFace.smile,
    );
  }

  /// The wind is a pattern of lines in a tile of [_tile] cells, repeated
  /// across and down the area from its middle, so a bigger window gets more
  /// lines instead of the same ones spread apart. Lines are `(x, y, length)`
  /// in the tile, half a cell tall.
  static const _tile = Size(71.11, 35.5);

  /// The far lines, moving left 2 cells a frame.
  static const _far = [
    (10.0, 2.2, 6.0),
    (48.0, 6.2, 4.0),
    (24.0, 11.7, 9.0),
    (64.0, 15.2, 5.0),
    (6.0, 20.7, 7.0),
    (38.0, 25.2, 3.0),
    (56.0, 29.7, 6.0),
    (18.0, 33.2, 4.0),
  ];

  /// The near ones, brighter and faster (3 cells a frame). Both go behind
  /// the mascot.
  static const _near = [
    (54.0, 5.2, 3.0),
    (20.0, 17.2, 4.0),
    (66.0, 26.2, 5.0),
    (36.0, 31.7, 3.0),
  ];

  /// The far lines over an area of [width] × [height] cells.
  static List<Rect> windFar(int f, double width, double height) =>
      _wind(_far, 2, f, width, height);

  static List<Rect> windNear(int f, double width, double height) =>
      _wind(_near, 3, f, width, height);

  static List<Rect> _wind(
    List<(double, double, double)> lines,
    double speed,
    int f,
    double width,
    double height,
  ) {
    final t = _flyingTime(f);
    // The tiles are laid from the middle of the area.
    final left = width / 2 - _tile.width / 2;
    final top = height / 2 - _tile.height / 2;
    return [
      for (final (x0, y0, length) in lines)
        for (
          var x = _wrap(left + x0 - t * speed, _tile.width) - _tile.width;
          x < width;
          x += _tile.width
        )
          if (x + length > 0)
            for (
              var y = _wrap(top + y0, _tile.height);
              y < height;
              y += _tile.height
            )
              Rect.fromLTWH(x, y, length, 0.5),
    ];
  }

  static double _wrap(double x, double span) => ((x % span) + span) % span;

  /// Frames after which every scene is back where it started (the longest
  /// cycles: 36 for the "z"s, 40 for the breathing, 16 for the bobbing).
  static final loop = [36, 40, 16, 20, 8].reduce(_lcm);

  static int _lcm(int a, int b) => a * b ~/ _gcd(a, b);
  static int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

  /// Opacity of the far and near wind lines.
  static const windFarOpacity = 0.18;
  static const windNearOpacity = 0.3;
}
