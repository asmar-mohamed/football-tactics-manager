import '../core/api_client.dart';
import '../models/player.dart';

class PlayerService {
  final _api = ApiClient.instance;

  Future<List<Player>> fetchPlayers() async {
    final res = await _api.get('/players');

    final list = res is Map<String, dynamic>
        ? (res['data'] as List<dynamic>? ?? [])
        : res is List
            ? res
            : <dynamic>[];

    return list.map((e) => Player.fromMap(e as Map<String, dynamic>)).toList();
  }
}
