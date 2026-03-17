import 'dart:math';
import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../models/player.dart';
import '../models/tactic.dart';
import '../services/player_service.dart';
import '../services/tactic_service.dart';

class TacticalPitch extends StatefulWidget {
  const TacticalPitch({
    super.key,
    this.onLineupChanged,
    this.onTacticsLoaded,
  });

  final VoidCallback? onLineupChanged;
  final void Function(List<Tactic>, Tactic)? onTacticsLoaded;

  @override
  State<TacticalPitch> createState() => TacticalPitchState();
}

class _PlayerData {
  final int id;
  final String name;
  final String number;
  final String category;
  Offset pos; // normalized 0-1
  
  _PlayerData(this.id, this.name, this.number, this.category, this.pos);
}

class TacticalPitchState extends State<TacticalPitch> {
  static const double _tokenSize = 56; // approx size of token widget
  static const List<Offset> _starterSlots = [
    Offset(0.08, 0.50), // GK
    Offset(0.25, 0.15), // LB
    Offset(0.22, 0.38), // CB
    Offset(0.22, 0.62), // CB
    Offset(0.25, 0.85), // RB
    Offset(0.45, 0.25), // CM
    Offset(0.45, 0.50), // CM
    Offset(0.45, 0.75), // CM
    Offset(0.75, 0.20), // LW
    Offset(0.80, 0.50), // ST
    Offset(0.75, 0.80), // RW
  ];

  List<Offset> _getFormationSlots(String formation) {
    List<Offset> slots = [const Offset(0.08, 0.50)]; // GK

    List<int> lines = formation.split('-').map((e) => int.tryParse(e) ?? 0).toList();
    if (lines.isEmpty || lines.any((l) => l <= 0) || lines.fold(0, (a, b) => a + b) != 10) {
      return _starterSlots;
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
      if (count == 1) {
        slots.add(Offset(x, 0.50));
      } else {
        // IMPROVED: Use dynamic spacing based on count. 
        // Small counts (e.g. 2 players) should be more centered.
        double verticalSpan = count <= 2 ? 0.35 : 0.70;
        double yStart = 0.50 - (verticalSpan / 2);
        double yStep = verticalSpan / (count - 1);

        for (int j = 0; j < count; j++) {
          double y = yStart + (j * yStep);
          double dx = x;
          if (i == 0 && (j == 0 || j == count - 1) && count >= 4) {
            dx += 0.03; // push fullbacks slightly forward
          }
          if (i == 0 && count >= 4 && j > 0 && j < count - 1) {
            dx -= 0.03; // central defenders slightly back
          }
          slots.add(Offset(dx, y));
        }
      }
    }

    while (slots.length < 11) {
      slots.add(const Offset(0.5, 0.5));
    }
    return slots;
  }

  final ApiClient _api = ApiClient.instance;
  final PlayerService _playerService = PlayerService();
  final _tacticService = TacticService();
  List<_PlayerData> _players = [];
  bool _loading = true;
  String? _error;
  int? _teamId;
  int? _tacticId;

  @override
  void initState() {
    super.initState();
    _loadStarters();
  }

  Future<void> _loadStarters() async {
    try {
      final starters = await _playerService.fetchPlayers(role: 'starter');
      starters.sort((a, b) => a.number.compareTo(b.number));
      _teamId = starters.isNotEmpty ? starters.first.teamId : null;
      
      Tactic? activeTactic;
      List<Tactic> allTactics = [];

      if (_teamId != null) {
        allTactics = await _tacticService.fetchTactics(teamId: _teamId);
        
        for (var t in allTactics) {
          if (!t.isDefault && t.teamId == _teamId) {
             activeTactic = t;
             break;
          }
        }
        
        if (activeTactic == null) {
          activeTactic = await _tacticService.createTactic('Main Lineup', '4-3-3', _teamId!);
          allTactics.add(activeTactic);
        }
        _tacticId = activeTactic.id;
      }

      if (mounted && allTactics.isNotEmpty && activeTactic != null) {
        widget.onTacticsLoaded?.call(allTactics, activeTactic);
      }

      final savedPositions = _tacticId != null ? await _fetchSavedPositions(_tacticId!) : <int, Offset>{};
  
      final count = min(starters.length, _starterSlots.length);
      final defaultSlots = activeTactic != null ? _getFormationSlots(activeTactic.formation) : _starterSlots;
      _players = List.generate(
        count,
        (i) => _PlayerData(
          starters[i].id,
          starters[i].name,
          starters[i].number.toString(),
          _categoryBadgeText(starters[i].categoryName),
          savedPositions[starters[i].id] ?? defaultSlots[i],
        ),
      );

      if (_players.isEmpty) {
        _error = 'No starter players found';
      }
    } catch (_) {
      _error = 'Failed to load starter players';
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> changeTactic(Tactic newTactic) async {
    setState(() {
      _tacticId = newTactic.id;
      _loading = true;
      _error = null;
    });

    try {
      final savedPositions = await _fetchSavedPositions(_tacticId!);
      final slots = _getFormationSlots(newTactic.formation);

      setState(() {
        for (var i = 0; i < _players.length; i++) {
          final p = _players[i];
          if (savedPositions.containsKey(p.id)) {
            p.pos = savedPositions[p.id]!;
          } else {
            if (i < slots.length) p.pos = slots[i];
          }
        }
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Failed to load tactic positions';
        _loading = false;
      });
    }
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

  List<dynamic> _extractDataList(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) return data;
      return const [];
    }
    if (response is List) return response;
    return const [];
  }

  Future<Map<int, Offset>> _fetchSavedPositions(int tacticId) async {
    final res = await _api.get('/tactics/$tacticId/positions');
    final positions = _extractDataList(res);
    final map = <int, Offset>{};

    for (final entry in positions) {
      if (entry is! Map<String, dynamic>) continue;
      final playerId = _toInt(entry['player_id']);
      if (playerId <= 0) continue;

      final x = _toDouble(entry['x_position']).clamp(0.0, 1.0).toDouble();
      final y = _toDouble(entry['y_position']).clamp(0.0, 1.0).toDouble();
      map[playerId] = Offset(x, y);
    }

    return map;
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

  String _categoryBadgeText(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'goalkeeper':
        return 'GK';
      case 'defender':
        return 'DF';
      case 'midfielder':
        return 'MF';
      case 'forward':
        return 'FW';
      default:
        return '--';
    }
  }

  Future<({bool success, String message})> saveLineup() async {
    if (_loading) {
      return (success: false, message: 'Lineup is still loading');
    }
    if (_players.isEmpty) {
      return (success: false, message: 'No starter players to save');
    }

    try {
      final tacticId = _tacticId;
      if (tacticId == null) {
        return (success: false, message: 'No team tactic available to save positions');
      }

      for (final player in _players) {
        await _api.post('/player-positions', {
          'player_id': player.id,
          'tactic_id': tacticId,
          'x_position': double.parse(player.pos.dx.toStringAsFixed(4)),
          'y_position': double.parse(player.pos.dy.toStringAsFixed(4)),
        });
      }

      return (success: true, message: 'Lineup saved successfully');
    } catch (e) {
      return (success: false, message: 'Failed to save lineup: ${_errorMessage(e)}');
    }
  }

  int _nearestStarterIndex(Offset localPoint, BoxConstraints constraints) {
    if (_players.isEmpty) return -1;

    var minDistance = double.infinity;
    var minIndex = 0;
    for (var i = 0; i < _players.length; i++) {
      final center = Offset(
        _players[i].pos.dx * constraints.maxWidth,
        _players[i].pos.dy * constraints.maxHeight,
      );
      final d = (center - localPoint).distanceSquared;
      if (d < minDistance) {
        minDistance = d;
        minIndex = i;
      }
    }
    return minIndex;
  }

  Future<void> _handleDroppedBankPlayer(
    Player droppedPlayer,
    Offset localPoint,
    BoxConstraints constraints,
  ) async {
    final targetIndex = _nearestStarterIndex(localPoint, constraints);
    if (targetIndex < 0 || targetIndex >= _players.length) return;

    final replaced = _players[targetIndex];
    if (replaced.id == droppedPlayer.id) return;

    final replacement = _PlayerData(
      droppedPlayer.id,
      droppedPlayer.name,
      droppedPlayer.number.toString(),
      _categoryBadgeText(droppedPlayer.categoryName),
      replaced.pos,
    );

    setState(() {
      _players[targetIndex] = replacement;
    });

    try {
      await _playerService.updatePlayerRole(droppedPlayer.id, 'starter');
      await _playerService.updatePlayerRole(replaced.id, 'substitute');
      widget.onLineupChanged?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _players[targetIndex] = replaced;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to assign player: ${_errorMessage(e)}'),
          backgroundColor: Colors.red.shade600,
        ),
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
            return DragTarget<Player>(
              onWillAcceptWithDetails: (details) => true,
              onAcceptWithDetails: (details) async {
                final box = context.findRenderObject();
                if (box is! RenderBox) return;
                final localPoint = box.globalToLocal(details.offset);
                await _handleDroppedBankPlayer(details.data, localPoint, constraints);
              },
              builder: (context, candidateData, rejectedData) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(painter: _PitchPainter()),
                    if (candidateData.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xAA37C8DF), width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    if (_loading)
                      const Center(child: CircularProgressIndicator()),
                    if (!_loading && _error != null && _players.isEmpty)
                      Center(
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600),
                        ),
                      ),
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
                            category: _players[i].category,
                            elevated: true,
                          ),
                        ),
                      ),
                  ],
                );
              },
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
    required this.category,
    this.elevated = false,
  });

  final String name;
  final String number;
  final String category;
  final bool elevated;

  String _initialsFromName(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final word = parts.first;
      return (word.length >= 2 ? word.substring(0, 2) : word).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _initialsFromName(name);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1ED6B0).withValues(alpha: 0.55),
                border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 2),
                boxShadow: elevated
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF111827),
                  border: Border.all(color: Colors.white, width: 1.2),
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
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
            '$name ($number)',
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
