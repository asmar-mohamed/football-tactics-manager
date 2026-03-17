import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../models/player.dart';
import '../services/player_service.dart';

enum _SortField { name, number, position, role, created }

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

  final List<String> _positions = const [
    'GK',
    'CB',
    'LB',
    'RB',
    'DM',
    'CM',
    'AM',
    'LW',
    'RW',
    'ST',
  ];
  final List<String> _roles = const ['starter', 'substitute'];
  static const Map<String, String> _positionCategoryMap = {
    'GK': 'Goalkeeper',
    'CB': 'Defender',
    'LB': 'Defender',
    'RB': 'Defender',
    'DM': 'Midfielder',
    'CM': 'Midfielder',
    'AM': 'Midfielder',
    'LW': 'Forward',
    'RW': 'Forward',
    'ST': 'Forward',
  };
  static const List<String> _categoryDisplayOrder = [
    'Goalkeeper',
    'Defender',
    'Midfielder',
    'Forward',
  ];

  List<Player> _players = [];
  List<({int id, String name})> _teams = [];
  List<({int id, String name})> _categories = [];

  String? _selectedCategory;
  String? _selectedPosition;
  int? _selectedTeamId;

  String _search = '';
  String? _filterPosition;
  String? _filterRole;
  int? _filterCategoryId;

  int? _editingPlayerId;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  _SortField _sortField = _SortField.name;
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
        _selectedCategory ??= _categoryDisplayOrder.first;
        _selectedPosition ??= _positions.first;
        _syncSelectedPositionWithCategory();
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

  String _tableTeamTitle() {
    final teamId = _selectedTeamId;
    if (teamId != null) return _teamName(teamId);
    if (_teams.isNotEmpty) return _teams.first.name;
    return 'Team';
  }

  String _categoryNameForPosition(String? position) {
    if (position == null) return '-';
    return _positionCategoryMap[position] ?? '-';
  }

  List<String> _positionsForCategory(String? category) {
    if (category == null) return _positions;
    final normalized = category.toLowerCase().trim();
    return _positions
        .where(
          (p) => (_positionCategoryMap[p] ?? '').toLowerCase() == normalized,
        )
        .toList();
  }

  void _syncSelectedPositionWithCategory() {
    final available = _positionsForCategory(_selectedCategory);
    if (available.isEmpty) {
      _selectedPosition = null;
      return;
    }
    if (_selectedPosition == null || !available.contains(_selectedPosition)) {
      _selectedPosition = available.first;
    }
  }

  int? _categoryIdByName(String categoryName) {
    for (final c in _categories) {
      if (c.name.toLowerCase() == categoryName.toLowerCase()) return c.id;
    }

    switch (categoryName) {
      case 'Goalkeeper':
        return 1;
      case 'Defender':
        return 2;
      case 'Midfielder':
        return 3;
      case 'Forward':
        return 4;
      default:
        return null;
    }
  }

  bool _isJerseyNumberTaken(int number, int teamId, {int? excludingPlayerId}) {
    return _players.any(
      (p) =>
          p.number == number && p.teamId == teamId && p.id != excludingPlayerId,
    );
  }

  String _roleForSubmit() {
    if (_editingPlayerId == null) return 'substitute';
    for (final p in _players) {
      if (p.id == _editingPlayerId) return p.role;
    }
    return 'substitute';
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null || _selectedPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete required fields')),
      );
      return;
    }

    final number = int.tryParse(_numberController.text.trim());
    if (number == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Jersey number is invalid')));
      return;
    }
    final selectedTeamId = _selectedTeamId;
    final isTaken = selectedTeamId != null
        ? _isJerseyNumberTaken(
            number,
            selectedTeamId,
            excludingPlayerId: _editingPlayerId,
          )
        : _players.any((p) => p.number == number && p.id != _editingPlayerId);
    if (isTaken) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jersey number must be unique in your team'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final categoryId = _categoryIdByName(_selectedCategory!);
      final role = _roleForSubmit();
      if (_editingPlayerId == null) {
        await _playerService.createPlayer(
          name: _nameController.text.trim(),
          number: number,
          position: _selectedPosition!,
          role: role,
          categoryId: categoryId,
        );
      } else {
        await _playerService.updatePlayer(
          playerId: _editingPlayerId!,
          name: _nameController.text.trim(),
          number: number,
          position: _selectedPosition!,
          role: role,
          categoryId: categoryId,
        );
      }

      _resetForm();
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editingPlayerId == null ? 'Player added' : 'Player updated',
          ),
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
      _selectedCategory =
          p.categoryName ?? _categoryNameForPosition(p.position);
      _selectedPosition = p.position;
      _syncSelectedPositionWithCategory();
      _selectedTeamId = p.teamId;
    });
  }

  Future<void> _deletePlayer(Player p) async {
    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete player'),
            content: Text('Delete ${p.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                ),
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
      _selectedCategory = _categoryDisplayOrder.first;
      _selectedPosition = _positionsForCategory(_selectedCategory).firstOrNull;
      _selectedTeamId = _teams.isNotEmpty ? _teams.first.id : null;
    });
  }

  List<Player> get _visiblePlayers {
    final query = _search.trim().toLowerCase();
    final filtered = _players.where((p) {
      if (query.isNotEmpty && !p.name.toLowerCase().contains(query)) {
        return false;
      }
      if (_filterPosition != null && p.position != _filterPosition) {
        return false;
      }
      if (_filterRole != null && p.role != _filterRole) return false;
      if (_filterCategoryId != null && p.categoryId != _filterCategoryId) {
        return false;
      }
      return true;
    }).toList();

    int compare(Player a, Player b) {
      switch (_sortField) {
        case _SortField.name:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case _SortField.number:
          return a.number.compareTo(b.number);
        case _SortField.position:
          return a.position.compareTo(b.position);
        case _SortField.role:
          return a.role.compareTo(b.role);
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
    final availablePositions = _positionsForCategory(_selectedCategory);

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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
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
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Player name is required'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _numberController,
                decoration: const InputDecoration(
                  labelText: 'Jersey Number',
                  hintText: 'e.g. 10',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final number = int.tryParse(v?.trim() ?? '');
                  if (number == null) return 'Valid number required';
                  final teamId = _selectedTeamId;
                  final isTaken = teamId != null
                      ? _isJerseyNumberTaken(
                          number,
                          teamId,
                          excludingPlayerId: _editingPlayerId,
                        )
                      : _players.any(
                          (p) => p.number == number && p.id != _editingPlayerId,
                        );
                  if (isTaken) {
                    return 'Jersey number already used in your team';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categoryDisplayOrder
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedCategory = v;
                    _syncSelectedPositionWithCategory();
                  });
                },
                validator: (v) => v == null ? 'Category is required' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _selectedPosition,
                decoration: const InputDecoration(labelText: 'Position'),
                items: availablePositions
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedPosition = v;
                  });
                },
                validator: (v) => v == null ? 'Position is required' : null,
              ),
              const SizedBox(height: 10),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Team'),
                child: Text(
                  _tableTeamTitle(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _submitForm,
                      icon: const Icon(Icons.add_circle_outline),
                      label: Text(
                        _saving
                            ? 'Saving...'
                            : (_editingPlayerId == null
                                  ? 'Add Player'
                                  : 'Update Player'),
                      ),
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
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All'),
                  ),
                  ..._positions.map(
                    (p) => DropdownMenuItem<String?>(value: p, child: Text(p)),
                  ),
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
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All'),
                  ),
                  ..._roles.map(
                    (r) => DropdownMenuItem<String?>(value: r, child: Text(r)),
                  ),
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
                  ..._categories.map(
                    (c) => DropdownMenuItem<int?>(
                      value: c.id,
                      child: Text(c.name),
                    ),
                  ),
                ],
                onChanged: (v) => _setFilterState(() => _filterCategoryId = v),
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
    final tableTitle = '${_tableTeamTitle()} Players';
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
                Text(
                  tableTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
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
                            constraints: BoxConstraints(
                              minWidth: tableConstraints.maxWidth,
                            ),
                            child: DataTable(
                              sortColumnIndex: _sortColumnIndex,
                              sortAscending: _sortAscending,
                              headingRowColor: WidgetStateProperty.all(
                                const Color(0xFFF8FAFC),
                              ),
                              columnSpacing: 20,
                              columns: [
                                DataColumn(
                                  headingRowAlignment: MainAxisAlignment.center,
                                  label: const Center(child: Text('Name')),
                                  onSort: (i, asc) =>
                                      _sortBy(_SortField.name, i, asc),
                                ),
                                DataColumn(
                                  headingRowAlignment: MainAxisAlignment.center,
                                  label: const Center(child: Text('Jersey #')),
                                  onSort: (i, asc) =>
                                      _sortBy(_SortField.number, i, asc),
                                ),
                                DataColumn(
                                  headingRowAlignment: MainAxisAlignment.center,
                                  label: const Center(child: Text('Position')),
                                  onSort: (i, asc) =>
                                      _sortBy(_SortField.position, i, asc),
                                ),
                                DataColumn(
                                  headingRowAlignment: MainAxisAlignment.center,
                                  label: const Center(child: Text('Role')),
                                  onSort: (i, asc) =>
                                      _sortBy(_SortField.role, i, asc),
                                ),
                                DataColumn(
                                  headingRowAlignment: MainAxisAlignment.center,
                                  label: const Center(
                                    child: Text('Created Date'),
                                  ),
                                  onSort: (i, asc) =>
                                      _sortBy(_SortField.created, i, asc),
                                ),
                                const DataColumn(
                                  headingRowAlignment: MainAxisAlignment.center,
                                  label: Center(child: Text('Actions')),
                                ),
                              ],
                              rows: rows.map((p) {
                                return DataRow(
                                  cells: [
                                    DataCell(Center(child: Text(p.name))),
                                    DataCell(
                                      Center(child: Text(p.number.toString())),
                                    ),
                                    DataCell(
                                      Center(child: _positionBadge(p.position)),
                                    ),
                                    DataCell(Center(child: _roleBadge(p.role))),
                                    DataCell(
                                      Center(
                                        child: Text(_formatDate(p.createdAt)),
                                      ),
                                    ),
                                    DataCell(
                                      Center(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              tooltip: 'Edit',
                                              icon: const Icon(
                                                Icons.edit_outlined,
                                              ),
                                              onPressed: () => _editPlayer(p),
                                            ),
                                            IconButton(
                                              tooltip: 'Delete',
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red,
                                              ),
                                              onPressed: () => _deletePlayer(p),
                                            ),
                                          ],
                                        ),
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
                      .map(
                        (n) =>
                            DropdownMenuItem<int>(value: n, child: Text('$n')),
                      )
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
                  onPressed: page > 0
                      ? () => setState(() => _page = page - 1)
                      : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Text('${page + 1}/$totalPages'),
                IconButton(
                  onPressed: page + 1 < totalPages
                      ? () => setState(() => _page = page + 1)
                      : null,
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
        final compactTableHeight = (constraints.maxHeight * 0.9)
            .clamp(360.0, 640.0)
            .toDouble();

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
                'Manage squad players with position-based categories.',
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
