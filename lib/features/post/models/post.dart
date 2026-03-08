/// 포스트 모델 - posts 테이블
class Post {
  const Post({
    required this.id,
    required this.groupId,
    required this.authorId,
    required this.weekIndex,
    required this.photoUrl,
    this.storagePath,
    this.caption,
    required this.createdAt,
  });

  final String id;
  final String groupId;
  final String authorId;
  final int weekIndex;

  /// signed URL (화면 표시용)
  final String photoUrl;

  /// Storage 내 경로 (캐시 키로 사용, signed URL이 바뀌어도 캐시 히트)
  final String? storagePath;

  final String? caption;
  final DateTime createdAt;

  factory Post.fromJson(Map<String, dynamic> json) {
    final createdAt = json['created_at'];
    final photoUrl = json['photo_url'] as String;
    return Post(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      authorId: json['author_id'] as String,
      weekIndex: json['week_index'] as int,
      photoUrl: photoUrl,
      storagePath: photoUrl,
      caption: json['caption'] as String?,
      createdAt: createdAt is String
          ? DateTime.parse(createdAt)
          : (createdAt as DateTime),
    );
  }

  Post copyWith({String? photoUrl, String? storagePath}) {
    return Post(
      id: id,
      groupId: groupId,
      authorId: authorId,
      weekIndex: weekIndex,
      photoUrl: photoUrl ?? this.photoUrl,
      storagePath: storagePath ?? this.storagePath,
      caption: caption,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Post && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
