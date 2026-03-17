import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../models/player.dart';
import '../services/player_service.dart';

enum _SortField {
  id,
  name,
  number,
  position,
  role,
  category,
  team,
  created,
}

class PlayersPage extends StatefulWidget {
  const PlayersPage({super.key});

  @override
  State<PlayersPage> createState() => _PlayersPageState();
}

class _PlayersPageState extends State<PlayersPage> {
  final PlayerService _playerService = PlayerService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  final List<String> _positions = const ['GK', 'CB', 'LB', 'RB', 'DM', 'CM', 'AM', 'LW', 'RW', 'ST'];
  final List<String> _roles = const ['starter', 'substitute'];

  List<Player> _players = [];
  List<({int id, String name})> _teams = [];
  List<({int id, String name})> _categories = [];

  String? _selectedPosition;
  String _selectedRole = 'substitute';
  int? _selectedCategoryId;
  int? _selectedTeamId;

  String _search = '';
  String? _filterPosition;
  String? _filterRole;
  int? _filterCategoryId;
  int? _filterTeamId;

  int? _editingPlayerId;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  _SortField _sortField = _SortField.id;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  int _rowsPerPage = 5;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await Future.wait([
        _playerService.fetchPlayers(),
        _playerService.fetchTeams(),
      ]);

      final players = result[0] as List<Player>;
      var teams = result[1] as List<({int id, String name})>;

      if (teams.isEmpty) {
        final ids = players.map((p) => p.teamId).toSet().toList()..sort();
        teams = ids.map((id) => (id: id, name: 'Team #$id')).toList();
      }

      final categories = _buildCategoryOptions(players);

      setState(() {
        _players = players;
        _teams = teams;
        _categories = categories;
        _selectedPosition ??= _positions.first;
        _selectedCategoryId ??= null;
        _selectedTeamId ??= _teams.isNotEmpty ? _teams.first.id : null;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = _errorMessage(e);
        _loading = false;
      });
    }
  }

  List<({int id, String name})> _buildCategoryOptions(List<Player> players) {
    final map = <int, String>{};
    for (final p in players) {
      final id = p.categoryId;
      if (id == null) continue;
      map[id] = p.categoryName ?? 'Category #$id';
    }

    if (map.isEmpty) {
      map[1] = 'Goalkeeper';
      map[2] = 'Defender';
      map[3] = 'Midfielder';
      map[4] = 'Forward';
    }

    final list = map.entries.map((e) => (id: e.key, name: e.value)).toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  String _errorMessage(Object e) {
    if (e is ApiException) {
      if (e.data is Map<String, dynamic>) {
        final data = e.data as Map<String, dynamic>;
        final msg = data['message'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
      return 'API error ${e.status}';
    }
    return e.toString();
  }

  void _setFilterState(VoidCallback updater) {
    setState(() {
      updater();
      _page = 0;
    });
  }

  String _teamName(int teamId) {
    final t = _teams.where((e) => e.id == teamId).firstOrNull;
    return t?.name ?? 'Team #$teamId';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPosition == null || _selectedTeamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete required fields')),
      );
      return;
    }

    final number = int.tryParse(_numberController.text.trim());
    if (number == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jersey number is invalid')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (_editingPlayerId == null) {
        await _playerService.createPlayer(
          name: _nameController.text.trim(),
          number: number,
          position: _selectedPosition!,
          role: _selectedRole,
          categoryId: _selectedCategoryId,
          teamId: _selectedTeamId!,
        );
      } else {
        await _playerService.updatePlayer(
          playerId: _editingPlayerId!,
          name: _nameController.text.trim(),
          number: number,
          position: _selectedPosition!,
          role: _selectedRole,
          categoryId: _selectedCategoryId,
          teamId: _selectedTeamId!,
        );
      }

      _resetForm();
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_editingPlayerId == null ? 'Player added' : 'Player updated'),
          backgroundColor: Colors.green.shade600,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: ${_errorMessage(e)}'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _editPlayer(Player p) {
    setState(() {
      _editingPlayerId = p.id;
      _nameController.text = p.name;
      _numberController.text = p.number.toString();
      _selectedPosition = p.position;
      _selectedRole = p.role;
      _selectedCategoryId = p.categoryId;
      _selectedTeamId = p.teamId;
    });
  }

  Future<void> _deletePlayer(Player p) async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete player'),
            content: Text('Delete ${p.name}?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirm) return;

    try {
      await _playerService.deletePlayer(p.id);
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Player deleted'),
          backgroundColor: Colors.green.shade600,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: ${_errorMessage(e)}'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  void _resetForm() {
    setState(() {
      _editingPlayerId = null;
      _nameController.clear();
      _numberController.clear();
      _selectedPosition = _positions.first;
      _selectedRole = 'substitute';
      _selectedCategoryId = null;
      _selectedTeamId = _teams.isNotEmpty ? _teams.first.id : null;
    });
  }

  List<Player> get _visiblePlayers {
    final query = _search.trim().toLowerCase();
    final filtered = _players.where((p) {
      if (query.isNotEmpty && !p.name.toLowerCase().contains(query)) return false;
      if (_filterPosition != null && p.position != _filterPosition) return false;
      if (_filterRole != null && p.role != _filterRole) return false;
      if (_filterCategoryId != null && p.categoryId != _filterCategoryId) return false;
      if (_filterTeamId != null && p.teamId != _filterTeamId) return false;
      return true;
    }).toList();

    int compare(Player a, Player b) {
      switch (_sortField) {
        case _SortField.id:
          return a.id.compareTo(b.id);
        case _SortField.name:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case _SortField.number:
          return a.number.compareTo(b.number);
        case _SortField.position:
          return a.position.compareTo(b.position);
        case _SortField.role:
          return a.role.compareTo(b.role);
        case _SortField.category:
          return (a.categoryName ?? '').compareTo(b.categoryName ?? '');
        case _SortField.team:
          return _teamName(a.teamId).compareTo(_teamName(b.teamId));
        case _SortField.created:
          final ad = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bd = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return ad.compareTo(bd);
      }
    }

    filtered.sort(compare);
    if (!_sortAscending) {
      return filtered.reversed.toList();
    }
    return filtered;
  }

  void _sortBy(_SortField field, int columnIndex, bool ascending) {
    setState(() {
      _sortField = field;
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _page = 0;
    });
  }

  Widget _roleBadge(String role) {
    final isStarter = role == 'starter';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: isStarter ? const Color(0xFFE8FAF3) : const Color(0xFFFFF5E7),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: isStarter ? const Color(0xFF0F9D65) : const Color(0xFFB76E00),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _positionBadge(String position) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFFEFF6FF),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Text(
        position,
        style: const TextStyle(
          color: Color(0xFF1D4ED8),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF1ED6B0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _editingPlayerId == null ? 'Add Player' : 'Edit Player',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Player Name',
                  hintText: 'e.g. Jude Bellingham',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Player name is required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _numberController,
                decoration: const InputDecoration(
                  labelText: 'Jersey Number',
                  hintText: 'e.g. 10',
                ),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || int.tryParse(v) == null) ? 'Valid number required' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _selectedPosition,
                decoration: const InputDecoration(labelText: 'Position'),
                items: _positions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => setState(() => _selectedPosition = v),
                validator: (v) => v == null ? 'Position is required' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setState(() => _selectedRole = v ?? 'substitute'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int?>(
                initialValue: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Category (Optional)',
                  hintText: 'Select category',
                ),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Optional')),
                  ..._categories.map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name))),
                ],
                onChanged: (v) => setState(() => _selectedCategoryId = v),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: _selectedTeamId,
                decoration: const InputDecoration(labelText: 'Team'),
                items: _teams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                onChanged: (v) => setState(() => _selectedTeamId = v),
                validator: (v) => v == null ? 'Team is required' : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _submitForm,
                      icon: const Icon(Icons.add_circle_outline),
                      label: Text(_saving
                          ? 'Saving...'
                          : (_editingPlayerId == null ? 'Add Player' : 'Update Player')),
                    ),
                  ),
                ],
              ),
              if (_editingPlayerId != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _saving ? null : _resetForm,
                    child: const Text('Cancel Edit'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersCard() {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF1ED6B0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 260,
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search by player name',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (v) => _setFilterState(() => _search = v),
              ),
            ),
            SizedBox(
              width: 130,
              child: DropdownButtonFormField<String?>(
                initialValue: _filterPosition,
                decoration: const InputDecoration(
                  labelText: 'Position',
                  prefixIcon: Icon(Icons.filter_alt_outlined),
                ),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('All')),
                  ..._positions.map((p) => DropdownMenuItem<String?>(value: p, child: Text(p))),
                ],
                onChanged: (v) => _setFilterState(() => _filterPosition = v),
              ),
            ),
            SizedBox(
              width: 130,
              child: DropdownButtonFormField<String?>(
                initialValue: _filterRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('All')),
                  ..._roles.map((r) => DropdownMenuItem<String?>(value: r, child: Text(r))),
                ],
                onChanged: (v) => _setFilterState(() => _filterRole = v),
              ),
            ),
            SizedBox(
              width: 170,
              child: DropdownButtonFormField<int?>(
                initialValue: _filterCategoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('All')),
                  ..._categories.map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name))),
                ],
                onChanged: (v) => _setFilterState(() => _filterCategoryId = v),
              ),
            ),
            SizedBox(
              width: 170,
              child: DropdownButtonFormField<int?>(
                initialValue: _filterTeamId,
                decoration: const InputDecoration(labelText: 'Team'),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('All')),
                  ..._teams.map((t) => DropdownMenuItem<int?>(value: t.id, child: Text(t.name))),
                ],
                onChanged: (v) => _setFilterState(() => _filterTeamId = v),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                _setFilterState(() {
                  _search = '';
                  _filterPosition = null;
                  _filterRole = null;
                  _filterCategoryId = null;
                  _filterTeamId = null;
                });
              },
              icon: const Icon(Icons.clear_all_rounded),
              label: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableCard() {
    final all = _visiblePlayers;
    final total = all.length;
    final totalPages = total == 0 ? 1 : ((total - 1) ~/ _rowsPerPage) + 1;
    final page = _page.clamp(0, totalPages - 1);
    if (page != _page) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _page = page);
      });
    }
    final start = total == 0 ? 0 : page * _rowsPerPage;
    final end = total == 0 ? 0 : (start + _rowsPerPage).clamp(0, total);
    final rows = all.sublist(start, end);

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF1ED6B0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.table_chart_rounded, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Squad Players',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: rows.isEmpty
                  ? const Center(
                      child: Text(
                        'No players found for current filters',
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, tableConstraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: tableConstraints.maxWidth),
                            child: DataTable(
                              sortColumnIndex: _sortColumnIndex,
                              sortAscending: _sortAscending,
                              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                              columnSpacing: 20,
                              columns: [
                                DataColumn(
                                  label: const Text('Player ID'),
                                  onSort: (i, asc) => _sortBy(_SortField.id, i, asc),
                                ),
                                DataColumn(
                                  label: const Text('Name'),
                                  onSort: (i, asc) => _sortBy(_SortField.name, i, asc),
                                ),
                                DataColumn(
                                  label: const Text('Jersey #'),
                                  numeric: true,
                                  onSort: (i, asc) => _sortBy(_SortField.number, i, asc),
                                ),
                                DataColumn(
                                  label: const Text('Position'),
                                  onSort: (i, asc) => _sortBy(_SortField.position, i, asc),
                                ),
                                DataColumn(
                                  label: const Text('Role'),
                                  onSort: (i, asc) => _sortBy(_SortField.role, i, asc),
                                ),
                                DataColumn(
                                  label: const Text('Category'),
                                  onSort: (i, asc) => _sortBy(_SortField.category, i, asc),
                                ),
                                DataColumn(
                                  label: const Text('Team'),
                                  onSort: (i, asc) => _sortBy(_SortField.team, i, asc),
                                ),
                                DataColumn(
                                  label: const Text('Created Date'),
                                  onSort: (i, asc) => _sortBy(_SortField.created, i, asc),
                                ),
                                const DataColumn(label: Text('Actions')),
                              ],
                              rows: rows.map((p) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(p.id.toString())),
                                    DataCell(Text(p.name)),
                                    DataCell(Text(p.number.toString())),
                                    DataCell(_positionBadge(p.position)),
                                    DataCell(_roleBadge(p.role)),
                                    DataCell(Text(p.categoryName ?? '-')),
                                    DataCell(Text(_teamName(p.teamId))),
                                    DataCell(Text(_formatDate(p.createdAt))),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: 'Edit',
                                            icon: const Icon(Icons.edit_outlined),
                                            onPressed: () => _editPlayer(p),
                                          ),
                                          IconButton(
                                            tooltip: 'Delete',
                                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                                            onPressed: () => _deletePlayer(p),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Showing ${total == 0 ? 0 : (start + 1)}-$end of $total',
                  style: const TextStyle(color: Colors.black54),
                ),
                const Spacer(),
                const Text('Rows:'),
                const SizedBox(width: 6),
                DropdownButton<int>(
                  value: _rowsPerPage,
                  items: const [5, 8, 10, 20, 50]
                      .map((n) => DropdownMenuItem<int>(value: n, child: Text('$n')))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _rowsPerPage = v;
                      _page = 0;
                    });
                  },
                ),
                IconButton(
                  onPressed: page > 0 ? () => setState(() => _page = page - 1) : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Text('${page + 1}/$totalPages'),
                IconButton(
                  onPressed: page + 1 < totalPages ? () => setState(() => _page = page + 1) : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: TextStyle(color: Colors.red.shade700)),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1200;
        final compactTableHeight = (constraints.maxHeight * 0.9).clamp(360.0, 640.0).toDouble();

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Players Management',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Manage squad players, roles, and structure in one place.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 360, child: _buildFormCard()),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              children: [
                                _buildFiltersCard(),
                                const SizedBox(height: 12),
                                Expanded(child: _buildTableCard()),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView(
                        children: [
                          _buildFormCard(),
                          const SizedBox(height: 12),
                          _buildFiltersCard(),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: compactTableHeight,
                            child: _buildTableCard(),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
