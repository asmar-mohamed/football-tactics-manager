class Player {
  final int id;
  final String name;
  final int number;
  final String position;
  final int teamId;
  final int? categoryId;

  Player({
    required this.id,
    required this.name,
    required this.number,
    required this.position,
    required this.teamId,
    this.categoryId,
  });

  factory Player.fromMap(Map<String, dynamic> map) {
    int toInt(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return Player(
      id: map['id'] as int,
      name: map['name'] as String? ?? '',
      number: toInt(map['number']),
      position: map['position'] as String? ?? '',
      teamId: toInt(map['team_id']),
      categoryId: map['category_id'] != null ? toInt(map['category_id']) : null,
    );
  }
}
