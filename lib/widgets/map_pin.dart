import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A teardrop map pin whose point sits exactly on the bottom-centre of its
/// box.
///
/// Material's `Icons.location_on` glyph carries a few pixels of internal
/// padding below its tip, so anchoring that icon leaves the pin visibly
/// floating above the radius circle it is supposed to mark. Painting the
/// shape directly makes the tip and the circle's centre line up exactly.
class MapPin extends StatelessWidget {
  const MapPin({
    super.key,
    required this.color,
    this.size = 44,
    this.borderColor = Colors.white,
  });

  final Color color;
  final Color borderColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PinPainter(color: color, borderColor: borderColor),
      ),
    );
  }
}

class _PinPainter extends CustomPainter {
  _PinPainter({required this.color, required this.borderColor});

  final Color color;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Circular head sized so the tangent lines from the tip meet it cleanly.
    final headRadius = width * 0.32;
    final headCentre = Offset(width / 2, headRadius + height * 0.04);
    final tip = Offset(width / 2, height);

    // Angle from the head's centre to the tip, used to find the two points
    // where the body's straight edges leave the circle tangentially.
    final dy = tip.dy - headCentre.dy;
    final tangentAngle = math.acos(headRadius / dy);

    final path = Path();
    final leftAngle = math.pi / 2 + tangentAngle;
    final rightAngle = math.pi / 2 - tangentAngle;

    path.moveTo(
      headCentre.dx + headRadius * math.cos(leftAngle),
      headCentre.dy + headRadius * math.sin(leftAngle),
    );
    path.lineTo(tip.dx, tip.dy);
    path.lineTo(
      headCentre.dx + headRadius * math.cos(rightAngle),
      headCentre.dy + headRadius * math.sin(rightAngle),
    );
    // Anticlockwise, hence the negative sweep: the head's outer edge is the
    // major arc that runs over the top, from the right tangent point back to
    // the left one. Sweeping the same angle the other way lands on the top of
    // the circle instead, and close() then cuts a straight chord across the
    // head while the arc itself crosses the body. That is what made the pin
    // render as a lopsided blob rather than a teardrop.
    path.arcTo(
      Rect.fromCircle(center: headCentre, radius: headRadius),
      rightAngle,
      -(2 * math.pi - 2 * tangentAngle),
      false,
    );
    path.close();

    // A blurred copy rather than Canvas.drawShadow. That call is Material's
    // elevation primitive and it rasterises differently per backend: under
    // Impeller it lands as a hard offset silhouette, so the pin reads as two
    // overlapping markers instead of one with a shadow. A mask filter blurs
    // the same on every backend.
    canvas.drawPath(
      path.shift(const Offset(0, 1.5)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );

    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 0.055,
    );

    // Hollow centre, the way a conventional map pin reads.
    canvas.drawCircle(
      headCentre,
      headRadius * 0.38,
      Paint()..color = borderColor,
    );
  }

  @override
  bool shouldRepaint(_PinPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.borderColor != borderColor;
}
