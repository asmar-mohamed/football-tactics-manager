import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../models/tactic.dart';

class TacticLayoutPitch extends StatefulWidget {
  const TacticLayoutPitch({super.key});

  @override
  State<TacticLayoutPitch> createState() => TacticLayoutPitchState();
}

class _SlotData {
  _SlotData(this.slotIndex, this.pos);

  final int slotIndex;
  Offset pos;
}

class TacticLayoutPitchState extends State<TacticLayoutPitch> {
  static const double _tokenSize = 56;
  final ApiClient _api = ApiClient.instance;

  bool _loading = false;
  String? _error;
  int? _tacticId;
  List<_SlotData> _slots = [];

  @override
  void initState() {
    super.initState();
    _slots = _defaultSlotsByFormation('4-3-3');
  }

  List<_SlotData> _defaultSlotsByFormation(String formation) {
    final starterSlots = _formationSlots(formation);
    return List.generate(11, (i) => _SlotData(i + 1, starterSlots[i]));
  }

  List<Offset> _formationSlots(String formation) {
    final slots = <Offset>[const Offset(0.08, 0.50)];
    final normalized = formation.replaceAll(RegExp(r'\s+'), '');
    final lines = RegExp(r'\d+')
        .allMatches(normalized)
        .map((m) => int.tryParse(m.group(0) ?? '') ?? 0)
        .toList();

    if (lines.isEmpty ||
        lines.any((line) => line <= 0) ||
        lines.fold(0, (a, b) => a + b) != 10) {
      return const [
        Offset(0.08, 0.50),
        Offset(0.25, 0.15),
        Offset(0.22, 0.38),
        Offset(0.22, 0.62),
        Offset(0.25, 0.85),
        Offset(0.45, 0.25),
        Offset(0.45, 0.50),
        Offset(0.45, 0.75),
        Offset(0.75, 0.20),
        Offset(0.80, 0.50),
        Offset(0.75, 0.80),
      ];
    }

    List<double> xBands;
    if (lines.length == 3) {
      xBands = [0.25, 0.50, 0.75];
    } else if (lines.length == 4) {
      xBands = [0.25, 0.45, 0.65, 0.80];
    } else {
      xBands = List.generate(
        lines.length,
        (i) => 0.25 + (i * 0.55 / (lines.length - 1)),
      );
    }

    for (var i = 0; i < lines.length; i++) {
      final count = lines[i];
      final x = xBands[i];

      if (count == 1) {
        slots.add(Offset(x, 0.50));
      } else {
        final verticalSpan = count <= 2 ? 0.35 : 0.70;
        final yStart = 0.50 - (verticalSpan / 2);
        final yStep = verticalSpan / (count - 1);

        for (var j = 0; j < count; j++) {
          var dx = x;
          final y = yStart + (j * yStep);
          if (i == 0 && (j == 0 || j == count - 1) && count >= 4) {
            dx += 0.03;
          }
          if (i == 0 && count >= 4 && j > 0 && j < count - 1) {
            dx -= 0.03;
          }
          slots.add(Offset(dx, y));
        }
      }
    }

    while (slots.length < 11) {
      slots.add(const Offset(0.5, 0.5));
    }

    return slots.take(11).toList();
  }

  List<dynamic> _extractDataList(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) return data;
      return const [];
    }
    if (response is List) return response;
    return const [];
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  String _errorMessage(Object error) {
    if (error is ApiException) {
      final data = error.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) return message;
      }
      return 'API error ${error.status}';
    }
    return error.toString();
  }

  Future<Map<int, Offset>> _fetchSavedSlotPositions(int tacticId) async {
    final res = await _api.get('/tactics/$tacticId/slot-positions');
    final positions = _extractDataList(res);
    final map = <int, Offset>{};

    for (final entry in positions) {
      if (entry is! Map<String, dynamic>) continue;
      final slotIndex = _toInt(entry['slot_index']);
      if (slotIndex < 1 || slotIndex > 11) continue;

      final x = _toDouble(entry['x_position']).clamp(0.0, 1.0).toDouble();
      final y = _toDouble(entry['y_position']).clamp(0.0, 1.0).toDouble();
      map[slotIndex] = Offset(x, y);
    }

    return map;
  }

  Future<void> changeTactic(Tactic tactic) async {
    setState(() {
      _tacticId = tactic.id;
      _loading = true;
      _error = null;
    });

    final defaultSlots = _defaultSlotsByFormation(tactic.formation);
    try {
      final savedPositions = await _fetchSavedSlotPositions(tactic.id);

      for (final slot in defaultSlots) {
        slot.pos = savedPositions[slot.slotIndex] ?? slot.pos;
      }

      if (!mounted) return;
      setState(() {
        _slots = defaultSlots;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _slots = defaultSlots;
        _error = null;
        _loading = false;
      });
    }
  }

  Future<({bool success, String message})> saveLayout() async {
    if (_loading) {
      return (success: false, message: 'Tactical pitch is still loading');
    }
    if (_tacticId == null) {
      return (success: false, message: 'No tactic selected');
    }

    try {
      for (final slot in _slots) {
        await _api.post('/tactic-slot-positions', {
          'tactic_id': _tacticId,
          'slot_index': slot.slotIndex,
          'x_position': double.parse(slot.pos.dx.toStringAsFixed(4)),
          'y_position': double.parse(slot.pos.dy.toStringAsFixed(4)),
        });
      }
      return (success: true, message: 'Tactic positions saved successfully');
    } catch (e) {
      return (
        success: false,
        message: 'Failed to save tactic positions: ${_errorMessage(e)}',
      );
    }
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
                if (_loading) const Center(child: CircularProgressIndicator()),
                if (!_loading && _error != null)
                  Center(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (!_loading)
                  for (var i = 0; i < _slots.length; i++)
                    Positioned(
                      left:
                          _slots[i].pos.dx * constraints.maxWidth -
                          (_tokenSize / 2),
                      top:
                          _slots[i].pos.dy * constraints.maxHeight -
                          (_tokenSize / 2),
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            final w = constraints.maxWidth;
                            final h = constraints.maxHeight;
                            final dxClamp = (_tokenSize / 2) / w;
                            final dyClamp = (_tokenSize / 2) / h;
                            final newX =
                                _slots[i].pos.dx + (details.delta.dx / w);
                            final newY =
                                _slots[i].pos.dy + (details.delta.dy / h);
                            _slots[i].pos = Offset(
                              newX.clamp(dxClamp, 1 - dxClamp),
                              newY.clamp(dyClamp, 1 - dyClamp),
                            );
                          });
                        },
                        child: _SlotToken(index: _slots[i].slotIndex),
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

class _SlotToken extends StatelessWidget {
  const _SlotToken({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1ED6B0).withValues(alpha: 0.85),
              border: Border.all(color: Colors.white, width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.sports_soccer,
              color: Colors.white,
              size: 20,
            ),
          ),
          Positioned(
            bottom: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$index',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double padding = 32.0;

    final paint = Paint()
      ..color = const Color(0xFF1E8A41)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, paint);

    final stripePaint = Paint()
      ..color = const Color(0xFF28AB54).withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    const stripeCount = 12;
    final stripeWidth = size.width / stripeCount;
    for (var i = 0; i < stripeCount; i++) {
      if (i.isEven) {
        canvas.drawRect(
          Rect.fromLTWH(i * stripeWidth, 0, stripeWidth, size.height),
          stripePaint,
        );
      }
    }

    final line = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
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
    final circleRadius = innerRect.shortestSide * 0.08;
    canvas.drawCircle(center, circleRadius, line);
    canvas.drawCircle(center, 2, line..style = PaintingStyle.fill);
    line.style = PaintingStyle.stroke;

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
