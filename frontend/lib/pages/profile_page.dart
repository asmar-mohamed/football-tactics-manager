import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ApiClient _api = ApiClient.instance;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _teamNameController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  int _totalPlayers = 0;
  int _totalTactics = 0;
  int _totalTrainingSessions = 0;
  int _totalStarters = 0;
  int _totalSubstitutes = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _teamNameController.dispose();
    super.dispose();
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

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  void _applyProfileResponse(
    dynamic response, {
    bool notifyAuthProvider = false,
  }) {
    final data = response is Map<String, dynamic> ? response['data'] : null;
    if (data is! Map<String, dynamic>) return;

    final userMap = data['user'];
    final teamMap = data['team'];
    final statsMap = data['stats'];

    if (userMap is Map<String, dynamic>) {
      _fullNameController.text = (userMap['name'] as String? ?? '').trim();
      _emailController.text = (userMap['email'] as String? ?? '').trim();

      if (notifyAuthProvider && mounted) {
        context.read<AuthProvider>().setUser(User.fromMap(userMap));
      }
    }

    if (teamMap is Map<String, dynamic>) {
      _teamNameController.text = (teamMap['name'] as String? ?? '').trim();
    } else {
      _teamNameController.text = '';
    }

    if (statsMap is Map<String, dynamic>) {
      _totalPlayers = _toInt(statsMap['total_players']);
      _totalTactics = _toInt(statsMap['total_tactics']);
      _totalTrainingSessions = _toInt(statsMap['total_training_sessions']);
      _totalStarters = _toInt(statsMap['total_starters']);
      _totalSubstitutes = _toInt(statsMap['total_substitutes']);
    }
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _api.get('/profile');
      _applyProfileResponse(res);
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _errorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    final name = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final teamName = _teamNameController.text.trim();

    if (name.isEmpty || email.isEmpty || teamName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Full name, email, and team name are required'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final res = await _api.put('/profile', {
        'name': name,
        'email': email,
        'team_name': teamName,
      });
      _applyProfileResponse(res, notifyAuthProvider: true);
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully'),
          backgroundColor: Colors.green.shade600,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update failed: ${_errorMessage(e)}'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
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
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Coach Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'View and update your account information and team overview.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 14),
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFF1ED6B0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Coach Information',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _teamNameController,
                    decoration: const InputDecoration(labelText: 'Team Name'),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _saveProfile,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(_saving ? 'Saving...' : 'Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFF1ED6B0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Team Statistics',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final maxWidth = constraints.maxWidth;
                      final columns = maxWidth >= 1080
                          ? 5
                          : maxWidth >= 760
                          ? 3
                          : 2;
                      const spacing = 10.0;
                      final cardWidth =
                          (maxWidth - (spacing * (columns - 1))) / columns;

                      final stats = [
                        _StatCard(label: 'Total Players', value: _totalPlayers),
                        _StatCard(label: 'Total Tactics', value: _totalTactics),
                        _StatCard(
                          label: 'Training Sessions',
                          value: _totalTrainingSessions,
                        ),
                        _StatCard(label: 'Starters', value: _totalStarters),
                        _StatCard(
                          label: 'Substitutes',
                          value: _totalSubstitutes,
                        ),
                      ];

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: stats
                            .map(
                              (card) => SizedBox(width: cardWidth, child: card),
                            )
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
