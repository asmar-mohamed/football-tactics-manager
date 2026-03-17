import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/player.dart';
import '../models/tactic.dart';
import '../providers/auth_provider.dart';
import '../services/player_service.dart';
import '../widgets/player_list_item.dart';
import '../widgets/tactical_pitch.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  Future<List<Player>>? _playersFuture;
  late final ScrollController _playerScrollController;
  final GlobalKey<TacticalPitchState> _tacticalPitchKey = GlobalKey<TacticalPitchState>();
  List<Tactic>? _tactics;
  Tactic? _selectedTactic;

  @override
  void initState() {
    super.initState();
    _playerScrollController = ScrollController();
  }

  @override
  void dispose() {
    _playerScrollController.dispose();
    super.dispose();
  }

  Future<({bool success, String message})> saveLineup() async {
    final tacticalState = _tacticalPitchKey.currentState;
    if (tacticalState == null) {
      return (success: false, message: 'Tactical board is not ready');
    }
    return tacticalState.saveLineup();
  }

  void refreshPlayerBank() {
    setState(() {
      _playersFuture = PlayerService().fetchPlayers(role: 'substitute');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAuth = context.watch<AuthProvider>().isAuth;
    _playersFuture ??= isAuth ? PlayerService().fetchPlayers(role: 'substitute') : null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 12,
            child: _Panel(
              title: 'PLAYER BANK',
              backgroundColor: Colors.white,
              titleColor: const Color(0xFF0F172A),
              borderColor: const Color(0xFFE5E7EB),
              contentPadding: const EdgeInsets.fromLTRB(12, 14, 10, 10),
              expandChild: true,
              child: isAuth
                  ? FutureBuilder<List<Player>>(
                      future: _playersFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: Color(0xFF5ED3E8)),
                          );
                        }
                        if (snapshot.hasError) {
                          return Text(
                            'Failed to load players',
                            style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600),
                          );
                        }
                        final players = snapshot.data ?? [];
                        if (players.isEmpty) {
                          return const Text(
                            'No players found',
                            style: TextStyle(color: Color(0xFF475569)),
                          );
                        }
                        return ScrollbarTheme(
                          data: ScrollbarThemeData(
                            thumbColor: WidgetStateProperty.all(const Color(0xFF37C8DF)),
                            trackColor: WidgetStateProperty.all(Colors.transparent),
                            thickness: WidgetStateProperty.all(2),
                            radius: const Radius.circular(99),
                            mainAxisMargin: 6,
                            crossAxisMargin: 1,
                          ),
                          child: Scrollbar(
                            controller: _playerScrollController,
                            thumbVisibility: true,
                            trackVisibility: false,
                            child: ListView.separated(
                              controller: _playerScrollController,
                              padding: const EdgeInsets.only(right: 6, left: 4, top: 2, bottom: 8),
                              physics: const BouncingScrollPhysics(),
                              itemCount: players.length,
                              separatorBuilder: (context, _) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final p = players[index];
                                return Draggable<Player>(
                                  data: p,
                                  feedback: Material(
                                    color: Colors.transparent,
                                    child: SizedBox(
                                      width: 130,
                                      child: PlayerListItem(player: p),
                                    ),
                                  ),
                                  childWhenDragging: Opacity(
                                    opacity: 0.35,
                                    child: PlayerListItem(player: p),
                                  ),
                                  child: PlayerListItem(
                                    player: p,
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    )
                  : const Text(
                      'Please log in to view players',
                      style: TextStyle(color: Color(0xFF475569)),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 65,
            child: _Panel(
              title: '',
              showTitle: false,
              backgroundColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              expandChild: true,
              child: TacticalPitch(
                key: _tacticalPitchKey,
                onLineupChanged: refreshPlayerBank,
                onTacticsLoaded: (tactics, activeTactic) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _tactics = tactics;
                        _selectedTactic = activeTactic;
                      });
                    }
                  });
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Panel(
                  title: 'Strategy & Formation',
                  backgroundColor: Colors.white,
                  borderColor: const Color(0xFFE5E7EB),
                  child: _tactics == null
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF37C8DF)))
                      : DropdownButtonFormField<Tactic>(
                          value: _selectedTactic,
                          isExpanded: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF37C8DF)),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          dropdownColor: Colors.white,
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                          items: _tactics!.map((tactic) {
                            return DropdownMenuItem<Tactic>(
                              value: tactic,
                              child: Text(
                                '${tactic.name} (${tactic.formation})',
                                style: const TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (Tactic? newTactic) {
                            if (newTactic != null && _selectedTactic?.id != newTactic.id) {
                              setState(() {
                                _selectedTactic = newTactic;
                              });
                              _tacticalPitchKey.currentState?.changeTactic(newTactic);
                            }
                          },
                        ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _Panel(
                    title: 'Intelligent Assistance',
                    backgroundColor: Colors.white,
                    borderColor: const Color(0xFFE5E7EB),
                    child: const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
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
  });

  final String title;
  final Widget child;
  final bool expandChild;
  final bool showTitle;
  final Color backgroundColor;
  final Color titleColor;
  final Color? borderColor;
  final EdgeInsets contentPadding;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: backgroundColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: borderColor != null ? BorderSide(color: borderColor!, width: 1) : BorderSide.none,
      ),
      child: Padding(
        padding: contentPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle) ...[
              // Wrapped the Text inside a FittedBox
              FittedBox(
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
              const SizedBox(height: 12),
            ],
            if (expandChild) Expanded(child: child) else child,
          ],
        ),
      ),
    );
  }
}
