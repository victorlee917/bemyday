import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// App title
  ///
  /// In en, this message translates to:
  /// **'Be My Day'**
  String get appTitle;

  /// No description provided for @signUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign up for {appName}'**
  String signUpTitle(String appName);

  /// Tutorial page 1 title
  ///
  /// In en, this message translates to:
  /// **'Make your week\nfull of besties.'**
  String get tutorialTitle0;

  /// Tutorial page 2 title
  ///
  /// In en, this message translates to:
  /// **'Share something.\nMake your besties\' day!'**
  String get tutorialTitle1;

  /// Tutorial page 3 title
  ///
  /// In en, this message translates to:
  /// **'Your besties\' updates\nare revealed each day'**
  String get tutorialTitle2;

  /// Tutorial page 4 title
  ///
  /// In en, this message translates to:
  /// **'Memories with besties,\nday by day!'**
  String get tutorialTitle3;

  /// Tutorial next button
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tutorialButtonNext;

  /// Tutorial start button
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get tutorialButtonStart;

  /// Reveal countdown label
  ///
  /// In en, this message translates to:
  /// **'Reveals in'**
  String get revealsIn;

  /// Stats label for weeks count
  ///
  /// In en, this message translates to:
  /// **'Weeks'**
  String get statWeeks;

  /// Stats label for streaks count
  ///
  /// In en, this message translates to:
  /// **'Streaks'**
  String get statStreaks;

  /// Stats label for posts count
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get statPosts;

  /// Invite friends button label
  ///
  /// In en, this message translates to:
  /// **'Invite Friends'**
  String get inviteFriends;

  /// Empty post state message
  ///
  /// In en, this message translates to:
  /// **'No post yet'**
  String get noPostYet;

  /// Add posts prompt
  ///
  /// In en, this message translates to:
  /// **'Add posts'**
  String get addPosts;

  /// My tab title
  ///
  /// In en, this message translates to:
  /// **'MY'**
  String get myTabTitle;

  /// Profile fallback when nickname is empty
  ///
  /// In en, this message translates to:
  /// **'profile'**
  String get profileFallback;

  /// Edit button
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// My screen App section title
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get mySectionApp;

  /// Alarm menu item
  ///
  /// In en, this message translates to:
  /// **'Alarm'**
  String get myAlarm;

  /// Alarm tile for daily reminder at 10 PM
  ///
  /// In en, this message translates to:
  /// **'Daily Reminder'**
  String get alarmTileDailyReminder;

  /// Alarm tile subtitle for daily reminder
  ///
  /// In en, this message translates to:
  /// **'Daily at 10 PM'**
  String get alarmTileDailyReminderSubtitle;

  /// Alarm tile for new posts
  ///
  /// In en, this message translates to:
  /// **'New Post'**
  String get alarmTileNewPost;

  /// Alarm tile subtitle for new posts
  ///
  /// In en, this message translates to:
  /// **'When someone posts in your group'**
  String get alarmTileNewPostSubtitle;

  /// Alarm tile for new comments
  ///
  /// In en, this message translates to:
  /// **'New Comment'**
  String get alarmTileNewComment;

  /// Alarm tile subtitle for new comments
  ///
  /// In en, this message translates to:
  /// **'When someone comments on your post'**
  String get alarmTileNewCommentSubtitle;

  /// Alarm tile for new likes
  ///
  /// In en, this message translates to:
  /// **'New Like'**
  String get alarmTileNewLike;

  /// Alarm tile subtitle for new likes
  ///
  /// In en, this message translates to:
  /// **'When someone likes your post'**
  String get alarmTileNewLikeSubtitle;

  /// Push notification message for daily reminder
  ///
  /// In en, this message translates to:
  /// **'Time to share your day with your besties!'**
  String get pushDailyReminder;

  /// No description provided for @pushNewPost.
  ///
  /// In en, this message translates to:
  /// **'{nickname} posted in your group'**
  String pushNewPost(String nickname);

  /// No description provided for @pushNewComment.
  ///
  /// In en, this message translates to:
  /// **'{nickname} commented on your post'**
  String pushNewComment(String nickname);

  /// No description provided for @pushNewLike.
  ///
  /// In en, this message translates to:
  /// **'{nickname} liked your post'**
  String pushNewLike(String nickname);

  /// Theme menu item
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get myTheme;

  /// Language menu item
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get myLanguage;

  /// My screen BMD section title
  ///
  /// In en, this message translates to:
  /// **'BMD'**
  String get mySectionBmd;

  /// Instagram link
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get myInstagram;

  /// Privacy Policy link
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get myPrivacyPolicy;

  /// Terms of Service link
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get myTermsOfService;

  /// Open Source License menu item
  ///
  /// In en, this message translates to:
  /// **'Open Source License'**
  String get myOpenSourceLicense;

  /// My screen Danger Zone section title
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get mySectionDangerZone;

  /// Logout menu item
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get myLogout;

  /// Delete Account menu item
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get myDeleteAccount;

  /// Delete account dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountTitle;

  /// Delete account confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone.'**
  String get deleteAccountMessage;

  /// Delete account error message
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account. Please try again.'**
  String get deleteAccountFailed;

  /// Logout dialog title
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutTitle;

  /// Logout dialog message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutMessage;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Done button
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Profile screen title
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// Profile load error message
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile'**
  String get profileLoadError;

  /// Retry button
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// Nickname input hint
  ///
  /// In en, this message translates to:
  /// **'What\'s your Nickname?'**
  String get profileNicknameHint;

  /// Nickname required error
  ///
  /// In en, this message translates to:
  /// **'Please write your nickname'**
  String get profileNicknameRequired;

  /// Nickname invalid characters error
  ///
  /// In en, this message translates to:
  /// **'Nickname can only contain letters, numbers, period (.), and underscore (_).'**
  String get profileNicknameForbiddenChars;

  /// No description provided for @profileNicknameMaxLengthError.
  ///
  /// In en, this message translates to:
  /// **'You can enter up to {max} characters.'**
  String profileNicknameMaxLengthError(int max);

  /// Nickname duplicate error
  ///
  /// In en, this message translates to:
  /// **'This nickname is already in use.'**
  String get profileNicknameInUse;

  /// Profile save error
  ///
  /// In en, this message translates to:
  /// **'Failed to save. Please try again.'**
  String get profileSaveFailed;

  /// Edit photo option
  ///
  /// In en, this message translates to:
  /// **'Edit Photo'**
  String get profileEditPhoto;

  /// Delete photo option
  ///
  /// In en, this message translates to:
  /// **'Delete Photo'**
  String get profileDeletePhoto;

  /// Friends tab title
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get friendsTabTitle;

  /// Friends empty state message
  ///
  /// In en, this message translates to:
  /// **'Invite friends to get started'**
  String get inviteFriendsToGetStarted;

  /// Invite screen title
  ///
  /// In en, this message translates to:
  /// **'Invite Friends'**
  String get inviteScreenTitle;

  /// No description provided for @inviteCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create invitation: {error}'**
  String inviteCreateFailed(String error);

  /// No description provided for @inviteShareMessage.
  ///
  /// In en, this message translates to:
  /// **'Invitation from {nickname}, {url}'**
  String inviteShareMessage(String nickname, String url);

  /// Invite share subject
  ///
  /// In en, this message translates to:
  /// **'Be My Day - Invitation'**
  String get inviteShareSubject;

  /// Invite button when group is full
  ///
  /// In en, this message translates to:
  /// **'Already Full'**
  String get inviteAlreadyFull;

  /// Invite share button
  ///
  /// In en, this message translates to:
  /// **'Share Invitation'**
  String get inviteShareInvitation;

  /// Weekday picker label when no one has joined
  ///
  /// In en, this message translates to:
  /// **'Vacant'**
  String get vacant;

  /// Invitation screen title
  ///
  /// In en, this message translates to:
  /// **'Invitation'**
  String get invitationTitle;

  /// Expired invitation error message
  ///
  /// In en, this message translates to:
  /// **'Expired Invitation'**
  String get invitationExpired;

  /// Invitation load error
  ///
  /// In en, this message translates to:
  /// **'Failed to load invitation'**
  String get invitationLoadError;

  /// Error when user already has group on same weekday
  ///
  /// In en, this message translates to:
  /// **'You already have a group on this weekday.'**
  String get invitationAlreadyOnWeekday;

  /// Error when inviter joined another group
  ///
  /// In en, this message translates to:
  /// **'The inviter has already joined another group.'**
  String get invitationInviterInOtherGroup;

  /// Error when group is full
  ///
  /// In en, this message translates to:
  /// **'A group can have up to 8 members.'**
  String get invitationGroupFull;

  /// No description provided for @invitationAcceptFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to join: {error}'**
  String invitationAcceptFailed(String error);

  /// Chip when user is already in the group
  ///
  /// In en, this message translates to:
  /// **'Already a member'**
  String get invitationAlreadyMember;

  /// Fallback when inviter nickname is empty
  ///
  /// In en, this message translates to:
  /// **'Inviter'**
  String get invitationInviterFallback;

  /// Ok button
  ///
  /// In en, this message translates to:
  /// **'Ok'**
  String get ok;

  /// Accept button
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// Monday weekday name (fallback when group is null)
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get weekdayMonday;

  /// No description provided for @statPostsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Posts'**
  String statPostsCount(int count);

  /// Week grid empty state message
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get noPostsYet;

  /// No description provided for @partyAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About My {weekdayName}'**
  String partyAboutTitle(String weekdayName);

  /// No description provided for @partyLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave My {weekdayName}'**
  String partyLeaveTitle(String weekdayName);

  /// Leave group confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave?'**
  String get partyLeaveConfirmMessage;

  /// Leave group button
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get partyLeave;

  /// Party detail members section title
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get partyMembers;

  /// Posting album screen title
  ///
  /// In en, this message translates to:
  /// **'Select Photo'**
  String get postingSelectPhoto;

  /// Album dropdown fallback when no album name
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get postingAlbumFallback;

  /// Photo permission denied message
  ///
  /// In en, this message translates to:
  /// **'Photo access denied'**
  String get postingPhotoAccessDenied;

  /// Open app settings button
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get postingOpenSettings;

  /// Empty album state message
  ///
  /// In en, this message translates to:
  /// **'No photos found'**
  String get postingNoPhotosFound;

  /// Post screen when group is null
  ///
  /// In en, this message translates to:
  /// **'No group'**
  String get postNoGroup;

  /// No description provided for @postError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String postError(String error);

  /// Delete post sheet/dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Post'**
  String get postDeleteTitle;

  /// Delete post confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this post?'**
  String get postDeleteConfirmMessage;

  /// Post image load error
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get postFailedToLoad;

  /// No description provided for @postIndexOfCount.
  ///
  /// In en, this message translates to:
  /// **'Post {index} of {count}'**
  String postIndexOfCount(int index, int count);

  /// Time ago when less than 1 minute
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get timeAgoNow;

  /// No description provided for @timeAgoMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String timeAgoMinutes(int count);

  /// No description provided for @timeAgoHours.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String timeAgoHours(int count);

  /// Time ago for 1 day
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get timeAgoYesterday;

  /// No description provided for @timeAgoDays.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String timeAgoDays(int count);

  /// No description provided for @timeAgoWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count}w ago'**
  String timeAgoWeeks(int count);

  /// No description provided for @timeAgoMonths.
  ///
  /// In en, this message translates to:
  /// **'{count}mo ago'**
  String timeAgoMonths(int count);

  /// No description provided for @postNudgeMakeDay.
  ///
  /// In en, this message translates to:
  /// **'Make {nickname}\'s day!'**
  String postNudgeMakeDay(String nickname);

  /// Post nudge banner add button
  ///
  /// In en, this message translates to:
  /// **'Add post'**
  String get postNudgeAddPost;

  /// Likes sheet title
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get likesTitle;

  /// Comments sheet title
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get commentsTitle;

  /// No description provided for @commentsError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String commentsError(String error);

  /// Comment input hint
  ///
  /// In en, this message translates to:
  /// **'Leave a comment...'**
  String get commentsHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
