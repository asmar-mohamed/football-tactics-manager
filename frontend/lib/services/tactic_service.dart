import '../core/api_client.dart';
import '../models/tactic.dart';

class TacticService {
  final ApiClient _api = ApiClient.instance;

  Future<List<Tactic>> fetchTactics({int? teamId}) async {
    final query = teamId != null ? '?team_id=$teamId' : '';
    final response = await _api.get('/tactics$query');
    final data = _extractDataList(response);

    return data.map((json) => Tactic.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Tactic> createTactic(String name, String formation, int teamId) async {
    final response = await _api.post('/tactics', {
      'name': name,
      'formation': formation,
      'team_id': teamId,
    });
    
    if (response is Map<String, dynamic> && response['data'] != null) {
      return Tactic.fromJson(response['data']);
    }
    
    throw Exception('Failed to create tactic');
  }

  Future<Tactic> updateTactic(int id, String name, String formation) async {
    final response = await _api.put('/tactics/$id', {
      'name': name,
      'formation': formation,
    });
    
    if (response is Map<String, dynamic> && response['data'] != null) {
      return Tactic.fromJson(response['data']);
    }
    
    throw Exception('Failed to update tactic');
  }

  Future<void> deleteTactic(int id) async {
    await _api.delete('/tactics/$id');
  }

  List<dynamic> _extractDataList(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) return data;
      return const [];
    }
    if (response is List) return response;
    return const [];
  }
}
