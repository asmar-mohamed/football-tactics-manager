import 'package:flutter/material.dart';

import '../models/tactic.dart';

class TacticPreviewBoard extends StatelessWidget {
  const TacticPreviewBoard({super.key, required this.tactic});

  final Tactic tactic;

  List<({Offset pos, Color color})> _getFormationSlots(String formation) {
    List<({Offset pos, Color color})> slots = [
      (pos: const Offset(0.08, 0.50), color: Colors.grey.shade400) // GK
    ];

    List<int> lines = formation.split('-').map((e) => int.tryParse(e) ?? 0).toList();
    if (lines.isEmpty || lines.any((l) => l <= 0) || lines.fold(0, (a, b) => a + b) != 10) {
      return slots;
    }

    List<double> xBands;
    if (lines.length == 3) {
      xBands = [0.25, 0.50, 0.75];
    } else if (lines.length == 4) {
      xBands = [0.25, 0.45, 0.65, 0.80];
    } else {
      xBands = List.generate(lines.length, (i) => 0.25 + (i * 0.55 / (lines.length - 1)));
    }

    for (int i = 0; i < lines.length; i++) {
      int count = lines[i];
      double x = xBands[i];
      
      // Determine color based on line index
      Color lineColor;
      if (lines.length == 3) {
        // Standard 3-line formation (Def-Mid-Fwd)
        if (i == 0) lineColor = Colors.blue.shade600;
        else if (i == 1) lineColor = Colors.yellow.shade600;
        else lineColor = Colors.red.shade600;
      } else {
        // More complex lines: map roughly by depth
        double progress = i / (lines.length - 1);
        if (progress < 0.3) lineColor = Colors.blue.shade600;
        else if (progress < 0.7) lineColor = Colors.yellow.shade600;
        else lineColor = Colors.red.shade600;
      }

      if (count == 1) {
        slots.add((pos: Offset(x, 0.50), color: lineColor));
      } else {
        double verticalSpan = count <= 2 ? 0.35 : 0.70;
        double yStart = 0.50 - (verticalSpan / 2);
        double yStep = verticalSpan / (count - 1);

        for (int j = 0; j < count; j++) {
          double y = yStart + (j * yStep);
          double dx = x;
          if (i == 0 && (j == 0 || j == count - 1) && count >= 4) {
            dx += 0.03;
          }
          if (i == 0 && count >= 4 && j > 0 && j < count - 1) {
            dx -= 0.03;
          }
          slots.add((pos: Offset(dx, y), color: lineColor));
        }
      }
    }

    return slots;
  }

  @override
  Widget build(BuildContext context) {
    final slots = _getFormationSlots(tactic.formation);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double tokenSize = 32;
          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _PreviewPitchPainter()),
              for (var slot in slots)
                Positioned(
                  left: slot.pos.dx * constraints.maxWidth - (tokenSize / 2),
                  top: slot.pos.dy * constraints.maxHeight - (tokenSize / 2),
                  child: Container(
                    width: tokenSize,
                    height: tokenSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: slot.color,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PreviewPitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double padding = 16.0;

    final paint = Paint()
      ..color = const Color(0xFF1E8A41)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Offset.zero & size, paint);

    final stripePaint = Paint()
      ..color = const Color.fromARGB(255, 40, 171, 84).withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    const stripeCount = 12;
    final stripeWidth = size.width / stripeCount;
    for (var i = 0; i < stripeCount; i++) {
      if (i.isEven) {
        canvas.drawRect(Rect.fromLTWH(i * stripeWidth, 0, stripeWidth, size.height), stripePaint);
      }
    }

    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final innerRect = Rect.fromLTWH(
      padding,
      padding,
      size.width - padding * 2,
      size.height - padding * 2,
    );

    canvas.drawRect(innerRect, line);

    canvas.drawLine(
      Offset(size.width / 2, innerRect.top),
      Offset(size.width / 2, innerRect.bottom),
      line,
    );

    final center = innerRect.center;
    final circleRadius = innerRect.shortestSide * 0.1;
    canvas.drawCircle(center, circleRadius, line);

    canvas.drawCircle(center, 1.5, line..style = PaintingStyle.fill);
    line.style = PaintingStyle.stroke;

    final boxDepth = innerRect.width * 0.16;
    final boxWidth = innerRect.height * 0.4;

    canvas.drawRect(
      Rect.fromLTWH(innerRect.left, innerRect.center.dy - boxWidth / 2, boxDepth, boxWidth),
      line,
    );
    canvas.drawRect(
      Rect.fromLTWH(innerRect.right - boxDepth, innerRect.center.dy - boxWidth / 2, boxDepth, boxWidth),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
