/// 프로필 조회 결과 모델
class Profile {
  const Profile({
    required this.id,
    required this.nickname,
    this.avatarUrl,
  });

  final String id;
  final String nickname;
  final String? avatarUrl;

  /// DB/트리거가 부여한 시스템 기본 닉네임 (user_ + uuid 앞 8자)
  /// 최초 가입 시 유저에게는 공란으로 보여야 함
  bool get isSystemDefaultNickname {
    if (nickname.isEmpty) return false;
    final prefix = 'user_${id.replaceAll('-', '').substring(0, 8)}';
    return nickname.toLowerCase() == prefix.toLowerCase();
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      nickname: json['nickname'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}
