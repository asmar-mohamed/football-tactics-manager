import 'package:flutter/material.dart';

import 'package:frontend/pages/dashboard_page.dart';
import 'package:frontend/pages/players_page.dart';
import 'package:frontend/pages/settings_page.dart';
import 'package:frontend/pages/tactics_page.dart';
import 'package:frontend/pages/training_page.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _selectedIndex = 0;
  bool _savingLineup = false;
  final GlobalKey<DashboardPageState> _dashboardPageKey = GlobalKey<DashboardPageState>();

  final _items = const [
    _NavItem('Dashboard', Icons.dashboard_outlined),
    _NavItem('Players', Icons.group_outlined),
    _NavItem('Tactics', Icons.sports_soccer_outlined),
    _NavItem('Training Sessions', Icons.fitness_center_outlined),
    _NavItem('Settings', Icons.settings_outlined),
  ];

  late final List<Widget> _pages = [
    DashboardPage(key: _dashboardPageKey),
    PlayersPage(),
    const TacticsPage(),
    const TrainingPage(),
    const SettingsPage(),
  ];

  Future<void> _onSaveLineupPressed() async {
    if (_selectedIndex != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Open Dashboard page to save lineup')),
      );
      return;
    }

    final dashboardState = _dashboardPageKey.currentState;
    if (dashboardState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dashboard is not ready yet')),
      );
      return;
    }

    setState(() => _savingLineup = true);
    final result = await dashboardState.saveLineup();
    if (!mounted) return;
    setState(() => _savingLineup = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? Colors.green.shade600 : Colors.red.shade600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
        titleSpacing: 16,
        title: const Text(
          'CoachCompanion FC',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Coach',
                  style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 10),
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFF1ED6B0),
                  child: Text(
                    'C',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: _savingLineup ? null : _onSaveLineupPressed,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF1ED6B0),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: BorderSide.none,
                    ),
                    child: _savingLineup
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Save Lineup',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 80,
              child: _Sidebar(
                items: _items,
                selectedIndex: _selectedIndex,
                onSelect: (i) => setState(() => _selectedIndex = i),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Container(
                color: Colors.white,
                child: _pages[_selectedIndex],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F8FA),
      child: Column(
        children: [
          const SizedBox(height: 8),
          for (var i = 0; i < items.length; i++) ...[
            _SidebarIconButton(
              icon: items[i].icon,
              label: items[i].label,
              selected: i == selectedIndex,
              onTap: () => onSelect(i),
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _SidebarIconButton extends StatelessWidget {
  const _SidebarIconButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFE8F7F3) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: selected ? const Color(0xFF1ED6B0) : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem(this.label, this.icon);
}
