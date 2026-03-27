// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Be My Day';

  @override
  String signUpTitle(String appName) {
    return 'Sign up for $appName';
  }

  @override
  String get tutorialTitle0 => 'Make your week\nfull of besties.';

  @override
  String get tutorialTitle1 => 'Share something.\nMake your besties\' day!';

  @override
  String get tutorialTitle2 => 'Your besties\' updates\nare revealed each day';

  @override
  String get tutorialTitle3 => 'Memories with besties,\nday by day!';

  @override
  String get tutorialButtonNext => 'Next';

  @override
  String get tutorialButtonStart => 'Start';

  @override
  String get revealsIn => 'Reveals in';

  @override
  String get statWeeks => 'Weeks';

  @override
  String get statStreaks => 'Streaks';

  @override
  String get statPosts => 'Posts';

  @override
  String get inviteFriends => 'Invite Friends';

  @override
  String get noPostYet => 'No post yet';

  @override
  String get addPosts => 'Add posts';

  @override
  String get myTabTitle => 'MY';

  @override
  String get profileFallback => 'profile';

  @override
  String get edit => 'Edit';

  @override
  String get mySectionApp => 'App';

  @override
  String get myAlarm => 'Alarm';

  @override
  String get alarmTileDailyReminder => 'Daily Reminder';

  @override
  String get alarmTileDailyReminderSubtitle => 'Daily at 10 PM';

  @override
  String get alarmTileNewPost => 'New Post';

  @override
  String get alarmTileNewPostSubtitle => 'When someone posts in your group';

  @override
  String get alarmTileNewComment => 'New Comment';

  @override
  String get alarmTileNewCommentSubtitle =>
      'When someone comments on your post';

  @override
  String get alarmTileNewLike => 'New Like';

  @override
  String get alarmTileNewLikeSubtitle => 'When someone likes your post';

  @override
  String get alarmTileCommentMention => 'Mentions';

  @override
  String get alarmTileCommentMentionSubtitle =>
      'When someone mentions you in a comment';

  @override
  String get alarmNotificationsDisabled =>
      'Notifications are off. Enable Be My Day in Settings to receive alerts.';

  @override
  String get alarmOpenSettings => 'Open Settings';

  @override
  String get alarmEnableNotifications => 'Enable Notifications';

  @override
  String get pushDailyReminder => 'Time to share your day with your besties!';

  @override
  String pushNewPost(String nickname) {
    return '$nickname posted in your group 🎉';
  }

  @override
  String pushNewComment(String nickname) {
    return '$nickname commented on your post 💬';
  }

  @override
  String pushNewLike(String nickname) {
    return '$nickname liked your post ❤️';
  }

  @override
  String get myTheme => 'Theme';

  @override
  String get myLanguage => 'Language';

  @override
  String get mySectionBmd => 'BMD';

  @override
  String get myInstagram => 'Instagram';

  @override
  String get myPrivacyPolicy => 'Privacy Policy';

  @override
  String get myTermsOfService => 'Terms of Service';

  @override
  String get myOpenSourceLicense => 'Open Source License';

  @override
  String get mySectionDangerZone => 'Danger Zone';

  @override
  String get myLogout => 'Logout';

  @override
  String get myDeleteAccount => 'Delete Account';

  @override
  String get deleteAccountTitle => 'Delete Account';

  @override
  String get deleteAccountMessage =>
      'Are you sure you want to delete your account? This action cannot be undone.';

  @override
  String get deleteAccountFailed =>
      'Failed to delete account. Please try again.';

  @override
  String get logoutTitle => 'Logout';

  @override
  String get logoutMessage => 'Are you sure you want to log out?';

  @override
  String get cancel => 'Cancel';

  @override
  String get done => 'Done';

  @override
  String get delete => 'Delete';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileLoadError => 'Failed to load profile';

  @override
  String get retry => 'Try again';

  @override
  String get profileNicknameHint => 'What\'s your Nickname?';

  @override
  String get profileNicknameRequired => 'Please write your nickname';

  @override
  String get profileNicknameForbiddenChars =>
      'Nickname can only contain letters, numbers, period (.), and underscore (_).';

  @override
  String profileNicknameMaxLengthError(int max) {
    return 'You can enter up to $max characters.';
  }

  @override
  String get profileNicknameInUse => 'This nickname is already in use.';

  @override
  String get profileSaveFailed => 'Failed to save. Please try again.';

  @override
  String get profileEditPhoto => 'Edit Photo';

  @override
  String get profileDeletePhoto => 'Delete Photo';

  @override
  String get friendsTabTitle => 'Weekdays';

  @override
  String get inviteFriendsToGetStarted => 'Invite friends to get started';

  @override
  String get inviteScreenTitle => 'Invite Friends';

  @override
  String inviteCreateFailed(String error) {
    return 'Failed to create invitation: $error';
  }

  @override
  String inviteShareMessage(String nickname, String url) {
    return 'Invitation from $nickname, $url';
  }

  @override
  String get inviteShareSubject => 'Be My Day - Invitation';

  @override
  String get inviteAlreadyFull => 'Already Full';

  @override
  String get inviteShareInvitation => 'Share Invitation';

  @override
  String get vacant => 'Vacant';

  @override
  String get invitationTitle => 'Invitation';

  @override
  String get invitationExpired => 'Expired Invitation';

  @override
  String get invitationLoadError => 'Failed to load invitation';

  @override
  String get invitationAlreadyOnWeekday =>
      'You already have a group on this weekday.';

  @override
  String get invitationInviterInOtherGroup =>
      'The inviter has already joined another group.';

  @override
  String get invitationGroupFull => 'A group can have up to 8 members.';

  @override
  String invitationAcceptFailed(String error) {
    return 'Failed to join: $error';
  }

  @override
  String get invitationAlreadyMember => 'Already a member';

  @override
  String get invitationInviterFallback => 'Inviter';

  @override
  String get ok => 'Ok';

  @override
  String get accept => 'Accept';

  @override
  String get weekdayMonday => 'Monday';

  @override
  String statPostsCount(int count) {
    return '$count Posts';
  }

  @override
  String get noPostsYet => 'No posts yet';

  @override
  String partyAboutTitle(String weekdayName) {
    return 'About My $weekdayName';
  }

  @override
  String partyLeaveTitle(String weekdayName) {
    return 'Leave My $weekdayName';
  }

  @override
  String get partyLeaveConfirmMessage => 'Are you sure you want to leave?';

  @override
  String get partyLeave => 'Leave';

  @override
  String get partyMembers => 'Members';

  @override
  String get postingSelectPhoto => 'Select Photo';

  @override
  String get postingAlbumFallback => 'Album';

  @override
  String get postingPhotoAccessDenied => 'Photo access denied';

  @override
  String get postingOpenSettings => 'Open Settings';

  @override
  String get postingNoPhotosFound => 'No photos found';

  @override
  String get postingPhotoLoadFailed =>
      'Could not load photo. If it\'s from iCloud, ensure it\'s downloaded and check your network.';

  @override
  String get postNoGroup => 'No group';

  @override
  String postError(String error) {
    return 'Error: $error';
  }

  @override
  String get postDeleteTitle => 'Delete Post';

  @override
  String get postDeleteConfirmMessage =>
      'Are you sure you want to delete this post?';

  @override
  String get postFailedToLoad => 'Failed to load';

  @override
  String postIndexOfCount(int index, int count) {
    return 'Post $index of $count';
  }

  @override
  String get timeAgoNow => 'now';

  @override
  String timeAgoMinutes(int count) {
    return '${count}m ago';
  }

  @override
  String timeAgoHours(int count) {
    return '${count}h ago';
  }

  @override
  String get timeAgoYesterday => 'yesterday';

  @override
  String timeAgoDays(int count) {
    return '${count}d ago';
  }

  @override
  String timeAgoWeeks(int count) {
    return '${count}w ago';
  }

  @override
  String timeAgoMonths(int count) {
    return '${count}mo ago';
  }

  @override
  String postNudgeMakeDay(String nickname) {
    return 'Make $nickname\'s day!';
  }

  @override
  String get postNudgeAddPost => 'Add post';

  @override
  String get likesTitle => 'Likes';

  @override
  String get commentsTitle => 'Comments';

  @override
  String commentsError(String error) {
    return 'Error: $error';
  }

  @override
  String get commentsHint => 'Leave a comment...';
}
