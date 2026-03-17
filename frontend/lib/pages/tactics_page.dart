import 'package:flutter/material.dart';

import '../models/tactic.dart';
import '../services/player_service.dart';
import '../services/tactic_service.dart';
import '../widgets/tactic_preview_board.dart';

class TacticsPage extends StatefulWidget {
  const TacticsPage({super.key});

  @override
  State<TacticsPage> createState() => _TacticsPageState();
}

class _TacticsPageState extends State<TacticsPage> {
  final PlayerService _playerService = PlayerService();
  final TacticService _tacticService = TacticService();
  
  bool _isLoading = true;
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
        _tactics = await _tacticService.fetchTactics(); // fetch defaults if no team
      }

      if (_tactics.isNotEmpty) {
        _selectTactic(_tactics.first);
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
        const SnackBar(content: Text('No active team assigned. Cannot save tactic.')),
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
        if (_selectedTactic!.isDefault) {
          throw Exception('Cannot edit global default tactics');
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
    if (tactic.isDefault) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot delete default global tactics.')),
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _tactics.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF37C8DF)));
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    final readOnly = _selectedTactic?.isDefault == true;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left panel: List
          Expanded(
            flex: 1,
            child: Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'SAVED TACTICS',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Color(0xFF37C8DF)),
                          onPressed: _startCreating,
                          tooltip: 'Create New Tactic',
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: _tactics.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 4),
                      itemBuilder: (ctx, i) {
                        final t = _tactics[i];
                        final isSelected = t.id == _selectedTactic?.id;
                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: const Color(0xFF37C8DF).withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          title: Text(
                            t.name,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF475569),
                            ),
                          ),
                          subtitle: Text(
                            t.formation,
                            style: const TextStyle(color: Color(0xFF94A3B8)),
                          ),
                          trailing: t.isDefault
                              ? const Tooltip(
                                  message: 'Global Default',
                                  child: Icon(Icons.lock_outline, size: 16, color: Color(0xFF94A3B8)),
                                )
                              : null,
                          onTap: () => _selectTactic(t),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Right panel: Form & Preview
          Expanded(
            flex: 2,
            child: Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isCreating ? 'Create New Tactic' : 'Edit Tactic',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            if (readOnly) ...[
                              const SizedBox(height: 8),
                              Text(
                                'This is a global strategy and cannot be modified.',
                                style: TextStyle(color: Colors.amber.shade700, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _nameController,
                              enabled: !readOnly,
                              decoration: const InputDecoration(
                                labelText: 'Tactic Name',
                                filled: true,
                                fillColor: Color(0xFFF8FAFC),
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Requires a name' : null,
                              onChanged: (v) {
                                // Live preview update?
                                setState(() {});
                              },
                            ),
                            const SizedBox(height: 16),
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
                                int sum = 0;
                                for (var p in parts) {
                                  final num = int.tryParse(p);
                                  if (num == null || num <= 0) return 'Numbers must be > 0';
                                  sum += num;
                                }
                                if (sum != 10) return 'Outfield players must equal 10';
                                return null;
                              },
                              onChanged: (v) {
                                setState(() {}); // Live preview
                              },
                            ),
                            const Spacer(),
                            if (!readOnly)
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _saveTactic,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF37C8DF),
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: _isLoading && _isCreating
                                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                          : Text(_isCreating ? 'CREATE' : 'SAVE CHANGES', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  if (!_isCreating && _selectedTactic != null) ...[
                                    const SizedBox(width: 12),
                                    OutlinedButton(
                                      onPressed: _isLoading ? null : () => _deleteTactic(_selectedTactic!),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red.shade600,
                                        side: BorderSide(color: Colors.red.shade200),
                                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Icon(Icons.delete_outline),
                                    ),
                                  ]
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'FORMATION PREVIEW',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: TacticPreviewBoard(
                              tactic: Tactic(
                                id: 0,
                                name: _nameController.text,
                                formation: _formationController.text,
                                isDefault: false,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
