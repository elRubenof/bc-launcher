import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:flutter/material.dart';

class Button3D extends StatefulWidget {
  final String title;
  final double width;
  final Color color, secondaryColor;
  final GestureTapCallback onPressed;

  const Button3D({
    super.key,
    required this.title,
    required this.width,
    required this.color,
    required this.secondaryColor,
    required this.onPressed,
  });

  @override
  State<Button3D> createState() => _Button3DState();
}

class _Button3DState extends State<Button3D> {
  double _top = 7;
  double _lateral = 0;

  final _duration = const Duration(milliseconds: 70);
  final _buttonHeight = Constants.topBarHeight + 5;
  final _curve = Curves.ease;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: _buttonHeight + 7,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Constants.mainColor.withOpacity(0.3),
            blurRadius: 50.0,
            spreadRadius: 40.0,
          ),
        ],
      ),
      child: GestureDetector(
        onTapDown: _pressed,
        onTapUp: _unPressedOnTapUp,
        onTapCancel: _unPressed,
        child: Stack(
          children: <Widget>[
            // Arriba
            AnimatedPositioned(
              duration: _duration,
              top: _top,
              left: _lateral,
              right: _lateral,
              curve: _curve,
              child: Container(
                alignment: Alignment.center,
                height: _buttonHeight,
                decoration: BoxDecoration(
                  color: widget.color,
                  border: Border.all(color: widget.color, width: 1),
                ),
                child: Text(
                  widget.title.toUpperCase(),
                  style: const TextStyle(
                    color: Constants.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            // Top 1
            Positioned(
              left: 3.5,
              top: 0,
              child: Transform(
                transform: Matrix4.skewX(-0.5),
                child: Transform(
                  origin: const Offset(100, 10),
                  transform: Matrix4.rotationX(0),
                  child: AnimatedContainer(
                    duration: _duration,
                    curve: _curve,
                    width: widget.width * 0.7,
                    height: _top,
                    color: widget.secondaryColor,
                  ),
                ),
              ),
            ),
            // Top 2
            Positioned(
              right: 3.5,
              top: 0,
              child: Transform(
                transform: Matrix4.skewX(0.5),
                child: Transform(
                  origin: const Offset(100, 10),
                  transform: Matrix4.rotationX(0),
                  child: AnimatedContainer(
                    duration: _duration,
                    curve: _curve,
                    width: widget.width * 0.7,
                    height: _top,
                    color: widget.secondaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pressed(_) {
    if (Utility.isLaunching.value) return;

    setState(() {
      _top = 0;
      _lateral = 3.5;
    });
  }

  void _unPressedOnTapUp(_) => _unPressed();

  void _unPressed() {
    setState(() {
      _top = 7;
      _lateral = 0;
    });

    Future.delayed(_duration).then((value) => widget.onPressed());
  }
}
