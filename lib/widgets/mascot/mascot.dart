import 'dart:async';

import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/widgets/mascot/mascot_frames.dart';
import 'package:flutter/material.dart';

/// The launcher's animated mascot (the face of its icon with tentacles), in
/// [scene], each cell of its pixel grid [cell] logical pixels.
///
/// On its own it takes a box with room for its animation: 28 × 28 cells
/// while waiting (for the "z"s), 14 × 19 otherwise. With [fill] it takes its
/// parent's whole area, the box centered in it, and flying draws its wind
/// across all of it but [windMargin] (the parts of the screen it must leave
/// clear). Loading and flying put the body in the same place, so switching
/// between them doesn't move it.
class Mascot extends StatefulWidget {
  final MascotScene scene;
  final double cell;
  final bool fill;
  final EdgeInsets windMargin;

  const Mascot({
    super.key,
    required this.scene,
    required this.cell,
    this.fill = false,
    this.windMargin = EdgeInsets.zero,
  });

  /// The box the mascot takes in cells, and where its body is in it.
  static (Size, Offset) box(MascotScene scene) => scene == MascotScene.waiting
      ? (const Size(28, 28), const Offset(7, 8))
      : (const Size(14, 19), const Offset(0, 1));

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> {
  Timer? _timer;
  int _frame = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Without animations the mascot stays on its first frame.
    if (MediaQuery.disableAnimationsOf(context)) {
      _timer?.cancel();
      _timer = null;
    } else {
      _timer ??= Timer.periodic(MascotAnimation.frameDuration, (_) {
        setState(() => _frame = (_frame + 1) % MascotAnimation.loop);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (box, _) = Mascot.box(widget.scene);
    // Every screen's size scaled by the one setting for the whole launcher.
    final cell = widget.cell * Constants.mascotScale;
    final painter = _MascotPainter(
      scene: widget.scene,
      frame: _frame,
      cell: cell,
      pixelRatio: MediaQuery.devicePixelRatioOf(context),
      windMargin: widget.windMargin,
    );
    return ExcludeSemantics(
      child: widget.fill
          ? CustomPaint(painter: painter, size: Size.infinite)
          : CustomPaint(painter: painter, size: box * cell),
    );
  }
}

class _MascotPainter extends CustomPainter {
  final MascotScene scene;
  final int frame;
  final double cell;
  final double pixelRatio;
  final EdgeInsets windMargin;

  _MascotPainter({
    required this.scene,
    required this.frame,
    required this.cell,
    required this.pixelRatio,
    required this.windMargin,
  });

  /// [v] on the closest device pixel, so the pixel art stays sharp.
  double _snap(double v) => (v * pixelRatio).round() / pixelRatio;

  /// A rect in cells, from [origin] (logical pixels), on whole device pixels.
  Rect _cells(Offset origin, Rect r) => Rect.fromLTRB(
    _snap(origin.dx + r.left * cell),
    _snap(origin.dy + r.top * cell),
    _snap(origin.dx + r.right * cell),
    _snap(origin.dy + r.bottom * cell),
  );

  void _fill(Canvas canvas, Offset origin, Iterable<Rect> rects, Color color) {
    final paint = Paint()
      ..color = color
      ..isAntiAlias = false;
    for (final r in rects) {
      canvas.drawRect(_cells(origin, r), paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final (box, body) = Mascot.box(scene);
    final boxOrigin = Offset(
      (size.width - box.width * cell) / 2,
      (size.height - box.height * cell) / 2,
    );
    final still = Offset(
      _snap(boxOrigin.dx + body.dx * cell),
      _snap(boxOrigin.dy + body.dy * cell),
    );
    final f = MascotAnimation.frame(scene, frame);
    final origin = still + Offset(0, _snap(f.bob * cell));

    final flying = scene == MascotScene.flying;
    final area = Size(size.width / cell, size.height / cell);
    const wind = Colors.white;
    // All the wind goes behind the mascot: over it, it looked see-through.
    // The nearer layer is brighter and faster. Only whole lines inside the
    // area left clear of [windMargin].
    if (flying) {
      final top = windMargin.top / cell;
      final bottom = (size.height - windMargin.bottom) / cell;
      bool inside(Rect r) => r.top >= top && r.bottom <= bottom;
      _fill(
        canvas,
        Offset.zero,
        MascotAnimation.windFar(frame, area.width, area.height).where(inside),
        wind.withValues(alpha: MascotAnimation.windFarOpacity),
      );
      _fill(
        canvas,
        Offset.zero,
        MascotAnimation.windNear(frame, area.width, area.height).where(inside),
        wind.withValues(alpha: MascotAnimation.windNearOpacity),
      );
    }

    // The tentacles go under the body, which covers their first row.
    _fill(canvas, origin, f.tentacles, MascotFace.body);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        _cells(
          origin,
          const Rect.fromLTWH(0, 0, MascotFace.size, MascotFace.size),
        ),
        Radius.circular(MascotFace.radius * cell),
      ),
      Paint()..color = MascotFace.body,
    );
    _fill(canvas, origin, MascotFace.frame, MascotFace.frameColor);
    _fill(canvas, origin, MascotFace.lenses, MascotFace.lensColor);
    _fill(canvas, origin, [MascotFace.bridge], MascotFace.bridgeColor);
    _fill(canvas, origin, f.mouth, MascotFace.mouthColor);

    // The "z"s rise from the body where it rests, without its breathing.
    for (final z in f.zs) {
      _fill(canvas, still, [
        for (final r in MascotFace.z)
          Rect.fromLTWH(
            z.position.dx + r.left * z.scale,
            z.position.dy + r.top * z.scale,
            r.width * z.scale,
            r.height * z.scale,
          ),
      ], MascotFace.body.withValues(alpha: z.opacity));
    }
  }

  @override
  bool shouldRepaint(_MascotPainter old) =>
      old.frame != frame ||
      old.scene != scene ||
      old.cell != cell ||
      old.pixelRatio != pixelRatio ||
      old.windMargin != windMargin;
}
