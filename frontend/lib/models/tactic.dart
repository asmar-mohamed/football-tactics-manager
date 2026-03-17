class Tactic {
  final int id;
  final String name;
  final String formation;
  final int? teamId;
  final bool isDefault;

  Tactic({
    required this.id,
    required this.name,
    required this.formation,
    this.teamId,
    required this.isDefault,
  });

  factory Tactic.fromJson(Map<String, dynamic> json) {
    return Tactic(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown',
      formation: json['formation'] as String? ?? 'Unknown',
      teamId: json['team_id'] as int?,
      isDefault: json['is_default'] == true || json['is_default'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'formation': formation,
      'team_id': teamId,
      'is_default': isDefault,
    };
  }
}
