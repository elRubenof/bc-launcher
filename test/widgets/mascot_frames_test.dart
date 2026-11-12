import 'dart:ui';

import 'package:bc_launcher/widgets/mascot/mascot_frames.dart';
import 'package:flutter_test/flutter_test.dart';

/// Whether two cells share an edge or a corner.
bool touches(Rect a, Rect b) =>
    a.left <= b.right &&
    b.left <= a.right &&
    a.top <= b.bottom &&
    b.top <= a.bottom;

void main() {
  final loop = MascotAnimation.loop;

  test('every scene loops after the same number of frames', () {
    for (final scene in MascotScene.values) {
      final first = MascotAnimation.frame(scene, 0);
      final again = MascotAnimation.frame(scene, loop);
      expect(again.bob, first.bob);
      expect(again.tentacles, first.tentacles);
      expect(again.mouth, first.mouth);
    }
  });

  test('flying tentacles never touch each other, not even at the corners', () {
    for (var f = 0; f < loop; f++) {
      final cells = MascotAnimation.frame(MascotScene.flying, f).tentacles;
      final tentacles = [
        for (var i = 0; i < 4; i++)
          cells.skip(_start(i)).take(MascotFace.tentacleRows(i)).toList(),
      ];
      for (var i = 0; i < 3; i++) {
        for (final a in tentacles[i]) {
          for (final b in tentacles[i + 1]) {
            expect(
              touches(a, b),
              isFalse,
              reason: 'frame $f, tentacles $i-${i + 1}',
            );
          }
        }
      }
    }
  });

  test('flying tentacles join the body straight and lean back', () {
    for (var f = 0; f < loop; f++) {
      final cells = MascotAnimation.frame(MascotScene.flying, f).tentacles;
      for (var i = 0; i < 4; i++) {
        final rows = cells
            .skip(_start(i))
            .take(MascotFace.tentacleRows(i))
            .toList();
        final x = MascotFace.tentacles[i];
        expect(rows[0].left, x);
        expect(rows[1].left, x, reason: 'row 14 joins the body');
        expect(rows.last.left, lessThan(x));
        for (var r = 1; r < rows.length; r++) {
          expect((rows[r].left - rows[r - 1].left).abs(), lessThanOrEqualTo(1));
        }
      }
    }
  });

  test('loading tentacles sway their tips one cell', () {
    final tips = {
      for (var f = 0; f < 4; f++)
        MascotAnimation.frame(MascotScene.loading, f).tentacles[1].left,
    };
    expect(tips, {1.0, 2.0, 3.0});
  });

  test('waiting breathes with its mouth and keeps the goggles', () {
    final mouths = {
      for (var f = 0; f < 40; f++)
        MascotAnimation.frame(MascotScene.waiting, f).mouth.single.height,
    };
    expect(mouths, {1.0, 2.0});
  });

  test('the "z"s fade in and out, growing as they rise', () {
    for (var f = 0; f < 36; f++) {
      for (final z in MascotAnimation.frame(MascotScene.waiting, f).zs) {
        expect(z.opacity, inInclusiveRange(0, 1));
        expect(z.scale, inInclusiveRange(0.3, 0.7));
      }
    }
  });

  test('a bigger area gets more wind lines, not the same ones spread', () {
    final small = MascotAnimation.windFar(0, 71.11, 35.5).length;
    final big = MascotAnimation.windFar(0, 4 * 71.11, 4 * 35.5).length;
    expect(big, closeTo(small * 16, small * 4));
  });

  test('wind lines stay within the area and move left', () {
    final a = MascotAnimation.windFar(0, 80, 40);
    final b = MascotAnimation.windFar(1, 80, 40);
    for (final line in a) {
      expect(line.left, greaterThanOrEqualTo(-line.width));
      expect(line.top, inInclusiveRange(0, 40));
    }
    expect(b.first.left, lessThan(a.first.left));
  });
}

/// Where tentacle [i]'s cells start in a flying frame (one cell per row).
int _start(int i) {
  var start = 0;
  for (var j = 0; j < i; j++) {
    start += MascotFace.tentacleRows(j);
  }
  return start;
}
