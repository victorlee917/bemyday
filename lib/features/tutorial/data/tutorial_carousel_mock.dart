/// 튜토리얼 첫 페이지 캐러셀 목업 데이터 (월~일)
/// 닉네임과 아바타 URL을 수정하여 표시 내용을 변경할 수 있습니다.
///
/// [avatarUrl]: null이면 기본 아바타 표시. asset 경로 또는 네트워크 URL 사용 가능.
class TutorialCarouselMock {
  const TutorialCarouselMock({required this.nickname, this.avatarUrl});

  final String nickname;
  final String? avatarUrl;
}

const _invitationBase = 'assets/mockups/invitation';

const List<TutorialCarouselMock> tutorialCarouselMocks = [
  TutorialCarouselMock(
    nickname: 'luna',
    avatarUrl: '$_invitationBase/monday.jpg',
  ),
  TutorialCarouselMock(
    nickname: 'blaze',
    avatarUrl: '$_invitationBase/tuesday.jpg',
  ),
  TutorialCarouselMock(
    nickname: 'aqua',
    avatarUrl: '$_invitationBase/wednesday.jpg',
  ),
  TutorialCarouselMock(
    nickname: 'rowan',
    avatarUrl: '$_invitationBase/thursday.jpg',
  ),
  TutorialCarouselMock(
    nickname: 'sterling',
    avatarUrl: '$_invitationBase/friday.jpg',
  ),
  TutorialCarouselMock(
    nickname: 'clay',
    avatarUrl: '$_invitationBase/saturday.jpg',
  ),
  TutorialCarouselMock(
    nickname: 'sunny',
    avatarUrl: '$_invitationBase/sunday.jpg',
  ),
];
