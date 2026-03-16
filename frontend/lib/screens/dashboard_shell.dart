import 'package:flutter/material.dart';

import '../pages/dashboard_page.dart';
import '../pages/players_page.dart';
import '../pages/settings_page.dart';
import '../pages/tactics_page.dart';
import '../pages/training_page.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _selectedIndex = 0;

  final _items = const [
    _NavItem('Dashboard', Icons.dashboard_outlined),
    _NavItem('Players', Icons.group_outlined),
    _NavItem('Tactics', Icons.sports_soccer_outlined),
    _NavItem('Training Sessions', Icons.fitness_center_outlined),
    _NavItem('Settings', Icons.settings_outlined),
  ];

  late final List<Widget> _pages = const [
    DashboardPage(),
    PlayersPage(),
    TacticsPage(),
    TrainingPage(),
    SettingsPage(),
  ];

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
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF1ED6B0),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: BorderSide.none,
                    ),
                    child: const Text(
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
