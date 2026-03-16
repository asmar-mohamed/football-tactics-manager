import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/player.dart';
import '../providers/auth_provider.dart';
import '../services/player_service.dart';
import '../widgets/player_list_item.dart';
import '../widgets/tactical_pitch.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Future<List<Player>>? _playersFuture;
  late final ScrollController _playerScrollController;

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

  @override
  Widget build(BuildContext context) {
    final isAuth = context.watch<AuthProvider>().isAuth;
    _playersFuture ??= isAuth ? PlayerService().fetchPlayers() : null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 20,
            child: _Panel(
              title: 'Player Bank',
              expandChild: true,
              child: isAuth
                  ? FutureBuilder<List<Player>>(
                      future: _playersFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Text(
                            'Failed to load players',
                            style: TextStyle(color: Colors.red.shade700),
                          );
                        }
                        final players = snapshot.data ?? [];
                        if (players.isEmpty) {
                          return const Text('No players found');
                        }
                        return Scrollbar(
                          controller: _playerScrollController,
                          thumbVisibility: true,
                          child: ListView.separated(
                            controller: _playerScrollController,
                            physics: const BouncingScrollPhysics(),
                            itemCount: players.length,
                            separatorBuilder: (context, _) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final p = players[index];
                              return PlayerListItem(
                                name: p.name,
                                number: p.number,
                                statusColor: Colors.green, // placeholder until backend provides status
                              );
                            },
                          ),
                        );
                      },
                    )
                  : const Text('Please log in to view players'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 65,
            child: _Panel(
              title: 'Tactical Board',
              expandChild: true,
              child: const TacticalPitch(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 20,
            child: _Panel(
              title: 'Intelligent Assistance',
              child: const SizedBox.shrink(),
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
  });

  final String title;
  final Widget child;
  final bool expandChild;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF5F5F5),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wrapped the Text inside a FittedBox
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.w700, 
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (expandChild) Expanded(child: child) else child,
          ],
        ),
      ),
    );
  }
}
