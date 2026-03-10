import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Coach Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              auth.logout();
            },
          )
        ],
      ),

      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(20),
        children: const [

          Card(
            child: Center(
              child: Text("Players"),
            ),
          ),

          Card(
            child: Center(
              child: Text("Training"),
            ),
          ),

          Card(
            child: Center(
              child: Text("Statistics"),
            ),
          ),
        ],
      ),
    );
  }
}