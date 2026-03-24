/// 그룹 모델 (groups 테이블)
///
/// weekday: 1=월 ~ 7=일
class Group {
  const Group({
    required this.id,
    required this.ownerId,
    this.successorId,
    required this.weekday,
    this.name,
    required this.weekBoundaryTimezone,
    required this.postCount,
    required this.streak,
    this.streakUpdatedAt,
    required this.createdAt,
  });

  final String id;
  final String ownerId;
  final String? successorId;
  final int weekday;
  final String? name;
  final String weekBoundaryTimezone;
  final int postCount;
  final int streak;
  final DateTime? streakUpdatedAt;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Group && other.id == id;

  @override
  int get hashCode => id.hashCode;

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      successorId: json['successor_id'] as String?,
      weekday: json['weekday'] as int,
      name: json['name'] as String?,
      weekBoundaryTimezone:
          json['week_boundary_timezone'] as String? ?? 'UTC',
      postCount: json['post_count'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      streakUpdatedAt: json['streak_updated_at'] != null
          ? DateTime.tryParse(json['streak_updated_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
