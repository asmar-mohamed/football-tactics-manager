import 'dart:math';
import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../models/player.dart';
import '../models/tactic.dart';
import '../services/player_service.dart';
import '../services/tactic_service.dart';

class TacticalPitch extends StatefulWidget {
  const TacticalPitch({super.key, this.onLineupChanged, this.onTacticsLoaded});

  final VoidCallback? onLineupChanged;
  final void Function(List<Tactic>, Tactic)? onTacticsLoaded;

  @override
  State<TacticalPitch> createState() => TacticalPitchState();
}

class _PlayerData {
  final int id;
  final String name;
  final String number;
  final String position;
  final String category;
  Offset pos; // normalized 0-1

  _PlayerData(
    this.id,
    this.name,
    this.number,
    this.position,
    this.category,
    this.pos,
  );
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

    final normalized = formation.replaceAll(RegExp(r'\s+'), '');
    List<int> lines = RegExp(r'\d+')
        .allMatches(normalized)
        .map((m) => int.tryParse(m.group(0)!) ?? 0)
        .toList();
    if (lines.isEmpty ||
        lines.any((l) => l <= 0) ||
        lines.fold(0, (a, b) => a + b) != 10) {
      return _starterSlots;
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
  Tactic? _pendingTacticChange;
  int _changeRequestId = 0;

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

        if (_tacticId != null) {
          for (final t in allTactics) {
            if (t.id == _tacticId) {
              activeTactic = t;
              break;
            }
          }
        }

        if (activeTactic == null) {
          for (var t in allTactics) {
            if (!t.isDefault && t.teamId == _teamId) {
              activeTactic = t;
              break;
            }
          }

          if (activeTactic == null) {
            activeTactic = await _tacticService.createTactic(
              'Main Lineup',
              '4-3-3',
              _teamId!,
            );
            allTactics.add(activeTactic);
          }
        }

        _tacticId = activeTactic.id;
      }

      if (mounted && allTactics.isNotEmpty && activeTactic != null) {
        widget.onTacticsLoaded?.call(allTactics, activeTactic);
      }

      Map<int, Offset> savedPositions = <int, Offset>{};
      Map<int, Offset> savedSlotPositions = <int, Offset>{};
      if (_tacticId != null) {
        try {
          savedPositions = await _fetchSavedPositions(_tacticId!);
        } catch (_) {
          savedPositions = <int, Offset>{};
        }
        try {
          savedSlotPositions = await _fetchSavedSlotPositions(_tacticId!);
        } catch (_) {
          savedSlotPositions = <int, Offset>{};
        }
      }

      final count = min(starters.length, _starterSlots.length);
      final defaultSlots = activeTactic != null
          ? _getFormationSlots(activeTactic.formation)
          : _starterSlots;
      final referenceSlots = List<Offset>.generate(
        11,
        (i) => savedSlotPositions[i + 1] ?? defaultSlots[i],
      );
      _players = List.generate(
        count,
        (i) => _PlayerData(
          starters[i].id,
          starters[i].name,
          starters[i].number.toString(),
          starters[i].position,
          _categoryBadgeText(starters[i].categoryName),
          savedSlotPositions[i + 1] ??
              savedPositions[starters[i].id] ??
              defaultSlots[i],
        ),
      );
      _resolveOverlaps(referenceSlots);

      if (_players.isEmpty) {
        _error = 'No starter players found';
      }

      final pendingTactic = _pendingTacticChange;
      if (pendingTactic != null) {
        _pendingTacticChange = null;
        Future.microtask(() => changeTactic(pendingTactic));
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
    _pendingTacticChange = newTactic;
    final requestId = ++_changeRequestId;

    setState(() {
      _tacticId = newTactic.id;
      _loading = true;
      _error = null;
    });

    if (_players.isEmpty) {
      return;
    }

    final slots = _getFormationSlots(newTactic.formation);
    Map<int, Offset> savedPositions = <int, Offset>{};
    Map<int, Offset> savedSlotPositions = <int, Offset>{};
    try {
      savedPositions = await _fetchSavedPositions(_tacticId!);
    } catch (_) {
      savedPositions = <int, Offset>{};
    }
    try {
      savedSlotPositions = await _fetchSavedSlotPositions(_tacticId!);
    } catch (_) {
      savedSlotPositions = <int, Offset>{};
    }

    if (!mounted || requestId != _changeRequestId) {
      return;
    }

    final referenceSlots = List<Offset>.generate(
      11,
      (i) => savedSlotPositions[i + 1] ?? slots[i],
    );
    setState(() {
      _pendingTacticChange = null;
      for (var i = 0; i < _players.length; i++) {
        final p = _players[i];
        if (savedSlotPositions.containsKey(i + 1)) {
          p.pos = savedSlotPositions[i + 1]!;
        } else if (savedPositions.containsKey(p.id)) {
          p.pos = savedPositions[p.id]!;
        } else {
          if (i < slots.length) p.pos = slots[i];
        }
      }
      _resolveOverlaps(referenceSlots);
      _loading = false;
    });
  }

  bool _hasOverlap(List<_PlayerData> players, {double threshold = 0.015}) {
    final sq = threshold * threshold;
    for (var i = 0; i < players.length; i++) {
      for (var j = i + 1; j < players.length; j++) {
        if ((players[i].pos - players[j].pos).distanceSquared <= sq) {
          return true;
        }
      }
    }
    return false;
  }

  double _preferredXForCategory(String category) {
    switch (category) {
      case 'GK':
        return 0.08;
      case 'DF':
        return 0.25;
      case 'MF':
        return 0.45;
      case 'FW':
        return 0.75;
      default:
        return 0.50;
    }
  }

  double _preferredYForPosition(String position) {
    final p = position.toUpperCase();
    if (p.startsWith('L') || p.contains('LW') || p.contains('LM')) return 0.20;
    if (p.startsWith('R') || p.contains('RW') || p.contains('RM')) return 0.80;
    return 0.50;
  }

  int _playerPriority(_PlayerData player) {
    switch (player.category) {
      case 'GK':
        return 0;
      case 'DF':
        return 1;
      case 'MF':
        return 2;
      case 'FW':
        return 3;
      default:
        return 4;
    }
  }

  double _slotScoreForPlayer(_PlayerData player, Offset slot) {
    final d = (player.pos - slot).distanceSquared;
    final linePenalty =
        (_preferredXForCategory(player.category) - slot.dx).abs() * 0.70;
    final sidePenalty =
        (_preferredYForPosition(player.position) - slot.dy).abs() * 0.45;
    return d + linePenalty + sidePenalty;
  }

  void _resolveOverlaps(List<Offset> referenceSlots) {
    if (_players.length < 2 || !_hasOverlap(_players)) return;

    final playerIndices = List<int>.generate(_players.length, (i) => i);
    playerIndices.sort(
      (a, b) =>
          _playerPriority(_players[a]).compareTo(_playerPriority(_players[b])),
    );

    final availableSlots = List<Offset>.from(referenceSlots);
    final usedSlotIndices = <int>{};

    for (final playerIndex in playerIndices) {
      var bestSlotIndex = -1;
      var bestScore = double.infinity;
      for (var slotIndex = 0; slotIndex < availableSlots.length; slotIndex++) {
        if (usedSlotIndices.contains(slotIndex)) continue;
        final score = _slotScoreForPlayer(
          _players[playerIndex],
          availableSlots[slotIndex],
        );
        if (score < bestScore) {
          bestScore = score;
          bestSlotIndex = slotIndex;
        }
      }
      if (bestSlotIndex < 0) continue;
      usedSlotIndices.add(bestSlotIndex);
      _players[playerIndex].pos = availableSlots[bestSlotIndex];
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

  Future<int?> _ensureTacticId(int? teamId) async {
    if (teamId == null || teamId <= 0) return null;
    if (_tacticId != null) return _tacticId;

    final tactics = await _tacticService.fetchTactics(teamId: teamId);
    Tactic? activeTactic;
    for (final t in tactics) {
      if (!t.isDefault && t.teamId == teamId) {
        activeTactic = t;
        break;
      }
    }

    activeTactic ??= await _tacticService.createTactic(
      'Main Lineup',
      '4-3-3',
      teamId,
    );

    _tacticId = activeTactic.id;
    if (mounted) {
      final list = [...tactics];
      if (!list.any((t) => t.id == activeTactic!.id)) {
        list.add(activeTactic);
      }
      widget.onTacticsLoaded?.call(list, activeTactic);
    }
    return _tacticId;
  }

  Future<({bool success, String message})> saveLineup() async {
    if (_loading) {
      return (success: false, message: 'Lineup is still loading');
    }
    if (_players.isEmpty) {
      return (success: false, message: 'No starter players to save');
    }

    try {
      _tacticId ??= await _ensureTacticId(_teamId);
      final tacticId = _tacticId;
      if (tacticId == null) {
        return (
          success: false,
          message: 'No team tactic available to save positions',
        );
      }

      for (var i = 0; i < _players.length; i++) {
        final player = _players[i];
        await _api.post('/player-positions', {
          'player_id': player.id,
          'tactic_id': tacticId,
          'x_position': double.parse(player.pos.dx.toStringAsFixed(4)),
          'y_position': double.parse(player.pos.dy.toStringAsFixed(4)),
        });

        await _api.post('/tactic-slot-positions', {
          'tactic_id': tacticId,
          'slot_index': i + 1,
          'x_position': double.parse(player.pos.dx.toStringAsFixed(4)),
          'y_position': double.parse(player.pos.dy.toStringAsFixed(4)),
        });
      }

      return (success: true, message: 'Lineup saved successfully');
    } catch (e) {
      return (
        success: false,
        message: 'Failed to save lineup: ${_errorMessage(e)}',
      );
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

  Offset _normalizedDropPosition(
    Offset localPoint,
    BoxConstraints constraints,
  ) {
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;
    if (w <= 0 || h <= 0) return const Offset(0.5, 0.5);

    final dxClamp = (_tokenSize / 2) / w;
    final dyClamp = (_tokenSize / 2) / h;
    final nx = (localPoint.dx / w).clamp(dxClamp, 1 - dxClamp).toDouble();
    final ny = (localPoint.dy / h).clamp(dyClamp, 1 - dyClamp).toDouble();
    return Offset(nx, ny);
  }

  Future<void> _handleDroppedBankPlayer(
    Player droppedPlayer,
    Offset localPoint,
    BoxConstraints constraints,
  ) async {
    if (_loading) return;
    if (_teamId != null && droppedPlayer.teamId != _teamId) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only drop players from your current team'),
        ),
      );
      return;
    }

    if (_players.isEmpty) {
      final previousTeamId = _teamId;
      final position = _normalizedDropPosition(localPoint, constraints);
      final added = _PlayerData(
        droppedPlayer.id,
        droppedPlayer.name,
        droppedPlayer.number.toString(),
        droppedPlayer.position,
        _categoryBadgeText(droppedPlayer.categoryName),
        position,
      );

      setState(() {
        _teamId ??= droppedPlayer.teamId;
        _error = null;
        _players = [added];
      });

      try {
        _tacticId ??= await _ensureTacticId(_teamId);
        await _playerService.updatePlayerRole(droppedPlayer.id, 'starter');
        widget.onLineupChanged?.call();
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _players.clear();
          _teamId = previousTeamId;
          _error = 'No starter players found';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign player: ${_errorMessage(e)}'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
      return;
    }

    final targetIndex = _nearestStarterIndex(localPoint, constraints);
    if (targetIndex < 0 || targetIndex >= _players.length) return;

    final replaced = _players[targetIndex];
    if (replaced.id == droppedPlayer.id) return;

    final replacement = _PlayerData(
      droppedPlayer.id,
      droppedPlayer.name,
      droppedPlayer.number.toString(),
      droppedPlayer.position,
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
                await _handleDroppedBankPlayer(
                  details.data,
                  localPoint,
                  constraints,
                );
              },
              builder: (context, candidateData, rejectedData) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(painter: _PitchPainter()),
                    if (candidateData.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xAA37C8DF),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    if (_loading)
                      const Center(child: CircularProgressIndicator()),
                    if (!_loading && _error != null && _players.isEmpty)
                      Center(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    for (var i = 0; i < _players.length; i++)
                      Positioned(
                        left:
                            _players[i].pos.dx * constraints.maxWidth -
                            (_tokenSize / 2),
                        top:
                            _players[i].pos.dy * constraints.maxHeight -
                            (_tokenSize / 2),
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              final w = constraints.maxWidth;
                              final h = constraints.maxHeight;
                              final dxClamp = (_tokenSize / 2) / w;
                              final dyClamp = (_tokenSize / 2) / h;
                              final newX =
                                  _players[i].pos.dx + (details.delta.dx / w);
                              final newY =
                                  _players[i].pos.dy + (details.delta.dy / h);
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
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.45),
                  width: 2,
                ),
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
                    ),
                  ]
                : null,
          ),
          child: Text(
            '$name ($number)',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
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
