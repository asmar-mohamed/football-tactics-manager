import 'package:flutter/material.dart';

class TrainingPage extends StatelessWidget {
  const TrainingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Training Sessions',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black87),
      ),
    );
  }
}
