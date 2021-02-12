library multicoloredcircle;

import 'package:flutter/material.dart';
import 'dart:math' as math;

// ignore: must_be_immutable
class MultiColorCircle extends StatefulWidget {
  Key key;
  List<Color> colors;
  List<double> percentages;
  double diameter;
  Color unfilled;
  Widget centerText;
  double width;
  bool clockwise;
  bool reversed;
  double startingPosition;

  MultiColorCircle(
      {this.key,
      @required this.colors,
      @required this.percentages,
      this.diameter = 100,
      this.unfilled = Colors.transparent,
      this.centerText,
      this.width = 20,
      this.clockwise = true,
      this.reversed = false,
      this.startingPosition = 0}) {
    assert(colors.length > 0, '"colors" requires a valid List<Color>');
    assert(
        percentages.length > 0, '"percentages" requires a valid List<double>');
    assert(percentages.reduce((value, element) => value + element) <= 100.1,
        'Sum of all percentages cannot exceed 100.1%!');
  }

  @override
  _MultiColorCircleState createState() => _MultiColorCircleState(
      colors: colors,
      percentages: percentages,
      diameter: diameter,
      centerText: centerText,
      unfilled: unfilled,
      width: width,
      clockwise: clockwise,
      reversed: reversed,
      startingPosition: startingPosition);
}

class _MultiColorCircleState extends State<MultiColorCircle> {
  List<Color> colors;
  List<double> percentages;
  double diameter;
  Color unfilled;
  Widget centerText;
  double width;
  bool clockwise;
  bool reversed;
  double startingPosition;

  _MultiColorCircleState(
      {@required this.colors,
      @required this.percentages,
      this.diameter,
      this.unfilled,
      this.centerText,
      this.width,
      this.clockwise,
      this.reversed,
      this.startingPosition});

  List<Widget> _drawCircles() {
    // This variable stores how much % of the circle was drawn so far. Always start with 0.
    double _totalDrawn = 0.0;

    // This list stores the widgets drawn and the text, if provided.
    List<Widget> drawnObjects = [];

    for (var i = 0; i < colors.length; i++) {
      drawnObjects.add(
        CustomPaint(
          size: Size(diameter, diameter),
          painter: MyPainter(
              color: colors[i],
              percentage: percentages[i],
              width: width,
              beginDraw: reversed ? -_totalDrawn - percentages[i] : _totalDrawn,
              diameter: diameter,
              clockwise: clockwise,
              startingPosition: startingPosition),
        ),
      );
      _totalDrawn += percentages[i];
    }
    if (unfilled != Colors.transparent) {
      drawnObjects.add(
        CustomPaint(
          size: Size(diameter, diameter),
          painter: MyPainter(
              color: unfilled,
              percentage: 100 - _totalDrawn,
              width: width,
              beginDraw: _totalDrawn,
              diameter: diameter,
              clockwise: clockwise,
              startingPosition: startingPosition),
        ),
      );
    }
    if (centerText != null) {
      drawnObjects.add(Center(child: centerText));
    }
    return drawnObjects;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      child: Stack(children: _drawCircles()),
    );
  }
}

class MyPainter extends CustomPainter {
  Color color;
  double percentage;
  double diameter;
  double width;
  double beginDraw;
  bool clockwise;
  double startingPosition;

  MyPainter(
      {@required this.color,
      @required this.percentage,
      @required this.beginDraw,
      @required this.diameter,
      @required this.width,
      @required this.clockwise,
      @required this.startingPosition});

  @override
  void paint(Canvas canvas, Size size) {
    Rect rect = Rect.fromCenter(
        height: diameter,
        width: diameter,
        center: Offset(diameter / 2, diameter / 2));
    double startAngle = ((math.pi * 2) * (beginDraw / 100)) -
        (math.pi / 2) +
        (math.pi * 2 * startingPosition / 100);
    double sweepAngle = (math.pi * 2) * (percentage / 100);
    bool useCenter = false;
    Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    canvas.drawArc(rect, startAngle, sweepAngle, useCenter, paint);
  }

  @override
  bool shouldRepaint(CustomPainter old) => true;
}
