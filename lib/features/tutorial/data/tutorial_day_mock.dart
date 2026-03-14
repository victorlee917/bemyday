import 'package:bemyday/common/widgets/stat/stats_collection.dart';

/// 요일별 튜토리얼 목업 데이터
class TutorialDayMock {
  const TutorialDayMock({
    required this.weekday,
    required this.imagePaths,
    required this.avatarNicknames,
    required this.avatarUrls,
    required this.groupName,
    required this.stats,
  });

  final String weekday;
  final List<String> imagePaths;
  final List<String> avatarNicknames;

  /// 아바타 프로필 이미지 경로. avatarNicknames와 동일한 길이.
  /// null이면 해당 아바타는 닉네임 첫 글자로 표시.
  final List<String> avatarUrls;
  final String groupName;
  final (int weeks, int streaks, int posts) stats;

  /// Localized StatItems는 호출 측에서 AppLocalizations로 생성.
  List<StatItem> statItems(String weeks, String streaks, String posts) => [
    StatItem(title: weeks, value: stats.$1),
    StatItem(title: streaks, value: stats.$2),
    StatItem(title: posts, value: stats.$3),
  ];
}

const _invitationBase = 'assets/mockups/invitation';
const _postBase = 'assets/mockups/posts';

/// 요일별 튜토리얼 목업 데이터 (Monday ~ Sunday)
const tutorialDayMocks = [
  TutorialDayMock(
    weekday: 'Monday',
    imagePaths: [
      '$_postBase/post1.jpg',
      '$_postBase/post2.jpg',
      '$_postBase/post3.jpg',
      '$_postBase/post4.jpg',
    ],
    avatarNicknames: ['A', 'B'],
    avatarUrls: ['$_invitationBase/monday.jpg', '$_invitationBase/tuesday.jpg'],
    groupName: 'Monday Blues',
    stats: (12, 5, 23),
  ),
  TutorialDayMock(
    weekday: 'Wednesday',
    imagePaths: [
      '$_postBase/post5.jpg',
      '$_postBase/post6.jpg',
      '$_postBase/post7.jpg',
      '$_postBase/post8.jpg',
    ],
    avatarNicknames: ['M'],
    avatarUrls: ['$_invitationBase/wednesday.jpg'],
    groupName: 'Aqua',
    stats: (15, 7, 42),
  ),
  TutorialDayMock(
    weekday: 'Friday',
    imagePaths: [
      '$_postBase/post9.jpg',
      '$_postBase/post10.jpg',
      '$_postBase/post11.jpg',
      '$_postBase/post12.jpg',
    ],
    avatarNicknames: ['M', 'T'],
    avatarUrls: [
      '$_invitationBase/thursday.jpg',
      '$_invitationBase/friday.jpg',
    ],
    groupName: 'T.G.I.F',
    stats: (15, 7, 42),
  ),
  TutorialDayMock(
    weekday: 'Sunday',
    imagePaths: [
      '$_postBase/post13.jpg',
      '$_postBase/post14.jpg',
      '$_postBase/post15.jpg',
      '$_postBase/post16.jpg',
    ],
    avatarNicknames: ['B', 'C'],
    avatarUrls: [
      '$_invitationBase/saturday.jpg',
      '$_invitationBase/sunday.jpg',
    ],
    groupName: 'Sundae',
    stats: (11, 4, 28),
  ),
];
