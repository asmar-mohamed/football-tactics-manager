class Player {
  final int id;
  final String name;
  final int number;
  final String position;
  final String role;
  final int teamId;
  final int? categoryId;
  final String? categoryName;
  final DateTime? createdAt;

  Player({
    required this.id,
    required this.name,
    required this.number,
    required this.position,
    required this.role,
    required this.teamId,
    this.categoryId,
    this.categoryName,
    this.createdAt,
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
      role: map['role'] as String? ?? '',
      teamId: toInt(map['team_id']),
      categoryId: map['category_id'] != null ? toInt(map['category_id']) : null,
      categoryName: map['category'] is Map<String, dynamic>
          ? (map['category']['name'] as String?)
          : map['category_name'] as String?,
      createdAt: map['created_at'] is String ? DateTime.tryParse(map['created_at'] as String) : null,
    );
  }
}
