import 'package:flutter/material.dart';

class PlayersPage extends StatelessWidget {
  const PlayersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Players',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black87),
      ),
    );
  }
}
