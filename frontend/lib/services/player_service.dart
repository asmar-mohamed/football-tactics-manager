import '../core/api_client.dart';
import '../models/player.dart';

class PlayerService {
  final _api = ApiClient.instance;

  Future<List<Player>> fetchPlayers({String? role}) async {
    final res = await _api.get('/players');

    final list = res is Map<String, dynamic>
        ? (res['data'] as List<dynamic>? ?? [])
        : res is List
            ? res
            : <dynamic>[];

    final players = list.map((e) => Player.fromMap(e as Map<String, dynamic>)).toList();
    if (role == null || role.isEmpty) return players;
    return players.where((p) => p.role == role).toList();
  }

  Future<void> updatePlayerRole(int playerId, String role) async {
    await _api.put('/players/$playerId', {
      'role': role,
    });
  }

  Future<Player> createPlayer({
    required String name,
    required int number,
    required String position,
    required String role,
    int? categoryId,
    required int teamId,
  }) async {
    final res = await _api.post('/players', {
      'name': name,
      'number': number,
      'position': position,
      'role': role,
      'category_id': categoryId,
      'team_id': teamId,
    });

    final data = res is Map<String, dynamic> ? res['data'] : null;
    if (data is Map<String, dynamic>) return Player.fromMap(data);
    throw Exception('Invalid create player response');
  }

  Future<Player> updatePlayer({
    required int playerId,
    required String name,
    required int number,
    required String position,
    required String role,
    int? categoryId,
    required int teamId,
  }) async {
    final res = await _api.put('/players/$playerId', {
      'name': name,
      'number': number,
      'position': position,
      'role': role,
      'category_id': categoryId,
      'team_id': teamId,
    });

    final data = res is Map<String, dynamic> ? res['data'] : null;
    if (data is Map<String, dynamic>) return Player.fromMap(data);
    throw Exception('Invalid update player response');
  }

  Future<void> deletePlayer(int playerId) async {
    await _api.delete('/players/$playerId');
  }

  Future<List<({int id, String name})>> fetchTeams() async {
    final res = await _api.get('/teams');
    final list = res is Map<String, dynamic>
        ? (res['data'] as List<dynamic>? ?? [])
        : res is List
            ? res
            : <dynamic>[];

    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => (id: (e['id'] as int), name: (e['name'] as String? ?? 'Team #${e['id']}')))
        .toList();
  }
}
