import 'package:flutter/material.dart';

import '../models/tactic.dart';
import '../services/player_service.dart';
import '../services/tactic_service.dart';
import '../widgets/tactic_layout_pitch.dart';

class TacticsPage extends StatefulWidget {
  const TacticsPage({super.key});

  @override
  State<TacticsPage> createState() => _TacticsPageState();
}

class _TacticsPageState extends State<TacticsPage> {
  final PlayerService _playerService = PlayerService();
  final TacticService _tacticService = TacticService();
  final GlobalKey<TacticLayoutPitchState> _tacticalPitchKey =
      GlobalKey<TacticLayoutPitchState>();

  bool _isLoading = true;
  bool _isSavingPitch = false;
  String? _error;
  int? _teamId;

  List<Tactic> _tactics = [];
  Tactic? _selectedTactic;

  bool _isCreating = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _formationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _formationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final players = await _playerService.fetchPlayers();
      _teamId = players.isNotEmpty ? players.first.teamId : null;

      if (_teamId != null) {
        _tactics = await _tacticService.fetchTactics(teamId: _teamId);
      } else {
        _tactics = await _tacticService
            .fetchTactics(); // fetch defaults if no team
      }

      if (_tactics.isNotEmpty) {
        final preferred = _tactics.firstWhere(
          (t) => t.isDefault && t.teamId != null,
          orElse: () => _tactics.firstWhere(
            (t) => t.teamId != null,
            orElse: () => _tactics.first,
          ),
        );
        _selectTactic(preferred);
      } else {
        _selectedTactic = null;
      }
    } catch (e) {
      _error = 'Failed to load tactics data';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectTactic(Tactic tactic) {
    setState(() {
      _selectedTactic = tactic;
      _isCreating = false;
      _nameController.text = tactic.name;
      _formationController.text = tactic.formation;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _tacticalPitchKey.currentState?.changeTactic(tactic);
    });
  }

  void _startCreating() {
    setState(() {
      _selectedTactic = null;
      _isCreating = true;
      _nameController.clear();
      _formationController.text = '4-3-3'; // Default value wrapper
    });
  }

  Future<void> _saveTactic() async {
    if (!_formKey.currentState!.validate()) return;

    if (_teamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active team assigned. Cannot save tactic.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isCreating) {
        final newTactic = await _tacticService.createTactic(
          _nameController.text.trim(),
          _formationController.text.trim(),
          _teamId!,
        );
        _tactics.add(newTactic);
        _selectTactic(newTactic);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tactic created successfully!')),
          );
        }
      } else if (_selectedTactic != null) {
        if (_selectedTactic!.teamId == null) {
          throw Exception('Cannot edit global template tactics');
        }

        final updated = await _tacticService.updateTactic(
          _selectedTactic!.id,
          _nameController.text.trim(),
          _formationController.text.trim(),
        );

        final idx = _tactics.indexWhere((t) => t.id == updated.id);
        if (idx >= 0) _tactics[idx] = updated;
        _selectTactic(updated);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tactic updated successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTactic(Tactic tactic) async {
    if (tactic.teamId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot delete default global tactics.'),
          ),
        );
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Tactic?'),
        content: Text('Are you sure you want to delete "${tactic.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('DELETE', style: TextStyle(color: Colors.red.shade600)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      await _tacticService.deleteTactic(tactic.id);
      _tactics.removeWhere((t) => t.id == tactic.id);
      if (_tactics.isNotEmpty) {
        _selectTactic(_tactics.first);
      } else {
        _startCreating();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tactic deleted successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete tactic.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePitchPositions() async {
    final pitch = _tacticalPitchKey.currentState;
    if (pitch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tactical pitch is not ready yet')),
      );
      return;
    }

    setState(() => _isSavingPitch = true);
    try {
      Tactic? tacticToSave = _selectedTactic;
      if (tacticToSave == null || tacticToSave.teamId == null) {
        tacticToSave = await _ensureCoachTeamTactic();
        if (tacticToSave == null) {
          if (!mounted) return;
          setState(() => _isSavingPitch = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No team tactic could be assigned for the authenticated coach.',
              ),
            ),
          );
          return;
        }
        _selectTactic(tacticToSave);
        await pitch.changeTactic(tacticToSave);
      }

      final result = await pitch.saveLayout();
      if (!mounted) return;
      setState(() => _isSavingPitch = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success
              ? Colors.green.shade600
              : Colors.red.shade600,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingPitch = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to assign a team tactic: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Future<Tactic?> _ensureCoachTeamTactic() async {
    if (_teamId == null) {
      for (final tactic in _tactics) {
        if (tactic.teamId != null) {
          _teamId = tactic.teamId;
          break;
        }
      }
    }

    if (_teamId == null) {
      final players = await _playerService.fetchPlayers();
      _teamId = players.isNotEmpty ? players.first.teamId : null;
    }
    if (_teamId == null) return null;

    for (final tactic in _tactics) {
      if (tactic.isDefault && tactic.teamId == _teamId) {
        return tactic;
      }
    }
    for (final tactic in _tactics) {
      if (tactic.teamId == _teamId) {
        return tactic;
      }
    }

    final created = await _tacticService.createTactic(
      'Main Lineup',
      '4-3-3',
      _teamId!,
    );
    _tactics = [..._tactics, created];
    return created;
  }

  Widget _buildSavedTacticsPanel() {
    return _Panel(
      title: 'SAVED TACTICS',
      backgroundColor: Colors.white,
      titleColor: const Color(0xFF0F172A),
      borderColor: const Color(0xFFE5E7EB),
      contentPadding: const EdgeInsets.fromLTRB(12, 14, 10, 10),
      expandChild: true,
      titleAction: IconButton(
        icon: const Icon(Icons.add_circle, color: Color(0xFF37C8DF)),
        onPressed: _startCreating,
        tooltip: 'Create New Tactic',
      ),
      child: _tactics.isEmpty
          ? const Center(
              child: Text(
                'No tactics found',
                style: TextStyle(color: Color(0xFF475569)),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.only(
                right: 6,
                left: 4,
                top: 2,
                bottom: 8,
              ),
              physics: const BouncingScrollPhysics(),
              itemCount: _tactics.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final tactic = _tactics[i];
                final isSelected = tactic.id == _selectedTactic?.id;
                return InkWell(
                  onTap: () => _selectTactic(tactic),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF37C8DF).withValues(alpha: 0.10)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF37C8DF)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tactic.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tactic.formation,
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (tactic.teamId == null)
                          const Tooltip(
                            message: 'Global Default',
                            child: Icon(
                              Icons.lock_outline,
                              size: 16,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        if (tactic.teamId != null && tactic.isDefault)
                          const Tooltip(
                            message: 'Active Tactic',
                            child: Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Color(0xFF37C8DF),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildPitchPanel() {
    return _Panel(
      title: '',
      showTitle: false,
      backgroundColor: Colors.transparent,
      contentPadding: EdgeInsets.zero,
      expandChild: true,
      child: Stack(
        children: [
          Positioned.fill(child: TacticLayoutPitch(key: _tacticalPitchKey)),
          Positioned(
            top: 12,
            right: 12,
            child: OutlinedButton.icon(
              onPressed: _isSavingPitch ? null : _savePitchPositions,
              icon: _isSavingPitch
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_alt_outlined, size: 16),
              label: Text(_isSavingPitch ? 'Saving...' : 'Save Positions'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF37C8DF),
                side: const BorderSide(color: Color(0xFF37C8DF)),
                backgroundColor: Colors.white.withValues(alpha: 0.95),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditTacticPanel(bool readOnly) {
    return _Panel(
      title: _isCreating ? 'Create Tactic' : 'Edit Tactic',
      backgroundColor: Colors.white,
      borderColor: const Color(0xFFE5E7EB),
      expandChild: true,
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (readOnly)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'This is a global strategy and cannot be modified.',
                    style: TextStyle(
                      color: Colors.amber.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              TextFormField(
                controller: _nameController,
                enabled: !readOnly,
                decoration: const InputDecoration(
                  labelText: 'Tactic Name',
                  filled: true,
                  fillColor: Color(0xFFF8FAFC),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Requires a name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _formationController,
                enabled: !readOnly,
                decoration: const InputDecoration(
                  labelText: 'Formation (e.g., 4-3-3)',
                  filled: true,
                  fillColor: Color(0xFFF8FAFC),
                  border: OutlineInputBorder(),
                  hintText: 'Format: x-y-z',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requires a formation';
                  final parts = v.split('-');
                  if (parts.length < 2) return 'Invalid format';
                  var sum = 0;
                  for (final p in parts) {
                    final num = int.tryParse(p);
                    if (num == null || num <= 0) return 'Numbers must be > 0';
                    sum += num;
                  }
                  if (sum != 10) return 'Outfield players must equal 10';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: readOnly || _isLoading ? null : _saveTactic,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF37C8DF),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _isCreating ? 'CREATE' : 'SAVE CHANGES',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!_isCreating && _selectedTactic != null) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () => _deleteTactic(_selectedTactic!),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete Tactic'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                    side: BorderSide(color: Colors.red.shade200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _tactics.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF37C8DF)),
      );
    }

    if (_error != null && _tactics.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: TextStyle(color: Colors.red.shade600)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    final readOnly = _selectedTactic != null && _selectedTactic!.teamId == null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 12, child: _buildSavedTacticsPanel()),
          const SizedBox(width: 12),
          Expanded(flex: 65, child: _buildPitchPanel()),
          const SizedBox(width: 12),
          Expanded(flex: 20, child: _buildEditTacticPanel(readOnly)),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
    this.expandChild = false,
    this.showTitle = true,
    this.backgroundColor = const Color(0xFFF5F5F5),
    this.titleColor = Colors.black87,
    this.borderColor,
    this.contentPadding = const EdgeInsets.all(16),
    this.titleAction,
  });

  final String title;
  final Widget child;
  final bool expandChild;
  final bool showTitle;
  final Color backgroundColor;
  final Color titleColor;
  final Color? borderColor;
  final EdgeInsets contentPadding;
  final Widget? titleAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: backgroundColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: borderColor != null
            ? BorderSide(color: borderColor!, width: 1)
            : BorderSide.none,
      ),
      child: Padding(
        padding: contentPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle) ...[
              Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ).copyWith(color: titleColor),
                      ),
                    ),
                  ),
                  ...(titleAction != null ? [titleAction!] : const <Widget>[]),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (expandChild) Expanded(child: child) else child,
          ],
        ),
      ),
    );
  }
}
