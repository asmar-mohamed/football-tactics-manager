import 'package:flutter/material.dart';

class TacticalPitch extends StatefulWidget {
  const TacticalPitch({super.key});

  @override
  State<TacticalPitch> createState() => _TacticalPitchState();
}

class _PlayerData {
  final String name;
  final String number;
  Offset pos; // normalized 0-1
  
  _PlayerData(this.name, this.number, this.pos);
}

class _TacticalPitchState extends State<TacticalPitch> {
  static const double _tokenSize = 56; // approx size of token widget
  late List<_PlayerData> _players;

  @override
  void initState() {
    super.initState();
    // FIXED: Coordinates mapped for a HORIZONTAL pitch (Attacking Left to Right)
    // X goes from 0.0 (left goal) to 1.0 (right goal)
    // Y goes from 0.0 (top sideline) to 1.0 (bottom sideline)
    _players = [
      _PlayerData('G. Keeper', 'GK', const Offset(0.08, 0.50)), // Left goal
      _PlayerData('L. Back', 'LB', const Offset(0.25, 0.15)),   // Defense line
      _PlayerData('L. Center', 'CB', const Offset(0.22, 0.38)),
      _PlayerData('R. Center', 'CB', const Offset(0.22, 0.62)),
      _PlayerData('R. Back', 'RB', const Offset(0.25, 0.85)),
      _PlayerData('L. Mid', 'CM', const Offset(0.45, 0.25)),    // Midfield line
      _PlayerData('C. Mid', 'CM', const Offset(0.45, 0.50)),
      _PlayerData('R. Mid', 'CM', const Offset(0.45, 0.75)),
      _PlayerData('L. Wing', 'LW', const Offset(0.75, 0.20)),   // Attack line
      _PlayerData('Striker', 'ST', const Offset(0.80, 0.50)),
      _PlayerData('R. Wing', 'RW', const Offset(0.75, 0.80)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: _PitchPainter()),
                for (var i = 0; i < _players.length; i++)
                  Positioned(
                    left: _players[i].pos.dx * constraints.maxWidth - (_tokenSize / 2),
                    top: _players[i].pos.dy * constraints.maxHeight - (_tokenSize / 2),
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          final w = constraints.maxWidth;
                          final h = constraints.maxHeight;
                          final dxClamp = (_tokenSize / 2) / w;
                          final dyClamp = (_tokenSize / 2) / h;
                          final newX = _players[i].pos.dx + (details.delta.dx / w);
                          final newY = _players[i].pos.dy + (details.delta.dy / h);
                          _players[i].pos = Offset(
                            newX.clamp(dxClamp, 1 - dxClamp),
                            newY.clamp(dyClamp, 1 - dyClamp),
                          );
                        });
                      },
                      child: _PlayerToken(
                        name: _players[i].name,
                        number: _players[i].number,
                        elevated: true,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PlayerToken extends StatelessWidget {
  const _PlayerToken({
    required this.name, 
    required this.number, 
    this.elevated = false,
  });

  final String name;
  final String number;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFF1ED6B0),
          foregroundColor: Colors.white,
          child: Text(
            number,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(8),
            boxShadow: elevated
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double padding = 32.0; // stadium padding

    final paint = Paint()
      ..color = const Color(0xFF1E8A41)
      ..style = PaintingStyle.fill;

    // Base pitch (full bleed grass)
    canvas.drawRect(Offset.zero & size, paint);

    // Slight gradient stripes
    final stripePaint = Paint()
      ..color = const Color(0xFF1B7A3A).withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    const stripeCount = 12;
    final stripeWidth = size.width / stripeCount;
    for (var i = 0; i < stripeCount; i++) {
      if (i.isEven) {
        canvas.drawRect(Rect.fromLTWH(i * stripeWidth, 0, stripeWidth, size.height), stripePaint);
      }
    }

    final line = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Define inner playable area with padding
    final innerRect = Rect.fromLTWH(
      padding,
      padding,
      size.width - padding * 2,
      size.height - padding * 2,
    );

    // Outline
    canvas.drawRect(innerRect, line);

    // Halfway line
    canvas.drawLine(
      Offset(size.width / 2, innerRect.top),
      Offset(size.width / 2, innerRect.bottom),
      line,
    );

    // Center circle
    final center = innerRect.center;
    final circleRadius = innerRect.shortestSide * 0.08;
    canvas.drawCircle(center, circleRadius, line);

    // Center spot
    canvas.drawCircle(center, 2, line..style = PaintingStyle.fill);
    line.style = PaintingStyle.stroke;

    // Penalty boxes (percentage of inner field)
    final boxDepth = innerRect.width * 0.16;
    final boxWidth = innerRect.height * 0.4;

    final leftBox = Rect.fromLTWH(
      innerRect.left,
      innerRect.center.dy - boxWidth / 2,
      boxDepth,
      boxWidth,
    );
    final rightBox = Rect.fromLTWH(
      innerRect.right - boxDepth,
      innerRect.center.dy - boxWidth / 2,
      boxDepth,
      boxWidth,
    );
    canvas.drawRect(leftBox, line);
    canvas.drawRect(rightBox, line);

    // Goal boxes (percentage of inner field)
    final goalDepth = innerRect.width * 0.06;
    final goalWidth = innerRect.height * 0.18;
    final leftGoal = Rect.fromLTWH(
      innerRect.left,
      innerRect.center.dy - goalWidth / 2,
      goalDepth,
      goalWidth,
    );
    final rightGoal = Rect.fromLTWH(
      innerRect.right - goalDepth,
      innerRect.center.dy - goalWidth / 2,
      goalDepth,
      goalWidth,
    );
    canvas.drawRect(leftGoal, line);
    canvas.drawRect(rightGoal, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
