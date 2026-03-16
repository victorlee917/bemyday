import 'dart:io';

import 'package:bemyday/common/widgets/avatar/avatar_default.dart';
import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:go_router/go_router.dart';
import 'package:bemyday/features/group/providers/group_provider.dart';
import 'package:bemyday/features/profile/models/profile.dart';
import 'package:bemyday/features/profile/providers/profile_provider.dart';
import 'package:bemyday/features/profile/viewmodels/profile_image_viewmodel.dart';
import 'package:bemyday/features/profile/viewmodels/profile_viewmodel.dart';
import 'package:bemyday/features/profile/widgets/profile_image_sheet.dart';
import 'package:bemyday/generated/l10n/app_localizations.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({
    super.key,
    this.fromOnboarding = false,
    this.initialProfile,
  });
  static const routeName = "profile";
  static const routeUrl = "/profile";

  /// 최초 가입 플로우에서 온 경우: 저장 후 /home으로 이동
  /// 그 외(가입 후 수정): 저장 후 이전 화면으로 pop
  final bool fromOnboarding;

  /// 진입 시 전달된 프로필 (있으면 API 호출 없이 바로 표시)
  final Profile? initialProfile;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  String _nickname = "";
  bool _isNicknameValid = false;
  bool _isSaving = false;
  String? _errorText;
  bool _initialDataLoaded = false;

  String? _pendingImagePath;
  bool _pendingDeleteImage = false;

  /// 폼 초기화 시 원본 닉네임 (변경 여부 판단용)
  String _originalNickname = "";

  bool get _hasChanges =>
      _nickname.trim() != _originalNickname ||
      _pendingImagePath != null ||
      _pendingDeleteImage;

  Future<void> _onSubmit() async {
    if (_formKey.currentState == null ||
        !_isNicknameValid ||
        !_hasChanges ||
        _isSaving)
      return;

    _formKey.currentState!.save();
    final nickname = _nickname.trim();
    if (nickname.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(profileViewModelProvider).saveNickname(nickname);

      if (_pendingImagePath != null) {
        await ref
            .read(profileImageViewModelProvider.notifier)
            .saveImage(_pendingImagePath!);
      } else if (_pendingDeleteImage) {
        await ref.read(profileImageViewModelProvider.notifier).deleteImage();
      }

      if (!mounted) return;
      _onSaveSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      final l10n = AppLocalizations.of(context)!;
      final message = e is PostgrestException && e.code == '23505'
          ? l10n.profileNicknameInUse
          : l10n.profileSaveFailed;
      showAppSnackBar(context, message, hasBottomNavBar: false);
    }
  }

  void _onSaved(value) {
    if (value != null) {
      _nickname = value;
    }
  }

  void _onScaffoldTap() {
    FocusScope.of(context).unfocus();
  }

  void _onReset() {
    _nicknameController.clear();
    // Form.reset()은 controller와 함께 사용 시 초기값으로 복원해 clear를 덮어씀
    setState(() {
      _nickname = "";
      _isNicknameValid = false;
      _errorText = null;
    });
  }

  static const int _nicknameMaxLength = 17;

  void _onChange(value) {
    final filtered = value.replaceAll(RegExp(r'[^a-zA-Z0-9._]'), '');
    final hasForbiddenChar = filtered != value;
    if (hasForbiddenChar) {
      _nicknameController.text = filtered;
      _nicknameController.selection = TextSelection.collapsed(
        offset: filtered.length,
      );
      value = filtered;
    }
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _nickname = value;
      if (hasForbiddenChar) {
        _errorText = l10n.profileNicknameForbiddenChars;
        _isNicknameValid = false;
      } else if (value.isEmpty) {
        _errorText = l10n.profileNicknameRequired;
        _isNicknameValid = false;
      } else if (value.length > _nicknameMaxLength) {
        _errorText = l10n.profileNicknameMaxLengthError(_nicknameMaxLength);
        _isNicknameValid = false;
      } else {
        _errorText = null;
        _isNicknameValid = true;
      }
    });
  }

  void _onSaveSuccess() {
    ref.invalidate(currentProfileProvider);

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId != null) {
      ref.invalidate(profileProvider(currentUserId));
    }

    if (_pendingImagePath != null || _pendingDeleteImage) {
      final groups = ref.read(currentUserGroupsProvider).valueOrNull ?? [];
      for (final group in groups) {
        ref.invalidate(groupMemberAvatarsProvider(group.id));
        ref.invalidate(groupFirstAvatarProvider(group.id));
      }
    }

    if (widget.fromOnboarding) {
      context.go('/home');
    } else {
      context.pop();
    }
  }

  void _onAvatarTap() {
    final profile = ref.read(currentProfileProvider).valueOrNull;
    final hasImage =
        _pendingImagePath != null ||
        (!_pendingDeleteImage && profile?.avatarUrl != null);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfileImageSheet(
        hasImage: hasImage,
        onEditTap: _onEditPhoto,
        onDeleteTap: _onDeletePhoto,
      ),
    );
  }

  Future<void> _onEditPhoto() async {
    final viewModel = ref.read(profileImageViewModelProvider.notifier);

    final pickedImage = await viewModel.pickImage();
    if (pickedImage == null) return;

    if (!mounted) return;
    final croppedFile = await viewModel.cropImage(pickedImage.path, context);
    if (croppedFile == null) return;

    if (!mounted) return;
    setState(() {
      _pendingImagePath = croppedFile.path;
      _pendingDeleteImage = false;
    });
  }

  Future<void> _onDeletePhoto() async {
    if (!mounted) return;
    setState(() {
      _pendingDeleteImage = true;
      _pendingImagePath = null;
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. 전달된 값이 있으면 바로 사용 (API 호출 없음)
    if (widget.initialProfile != null) {
      _initFormIfNeeded(widget.initialProfile!);
      return _buildBody(widget.initialProfile);
    }

    // 2. 캐시에 값이 있으면 사용 (API 호출 없음)
    final cachedProfile = ref.read(currentProfileProvider).valueOrNull;
    if (cachedProfile != null) {
      _initFormIfNeeded(cachedProfile);
      return _buildBody(cachedProfile);
    }

    // 3. 전달값·캐시 모두 없으면 API 호출
    final profileAsync = ref.watch(currentProfileProvider);
    ref.listen(currentProfileProvider, (prev, next) {
      next.whenData((profile) {
        if (profile != null &&
            !_initialDataLoaded &&
            _nicknameController.text.isEmpty) {
          _initFormIfNeeded(profile);
        }
      });
    });

    final l10n = AppLocalizations.of(context)!;
    return profileAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.profileTitle)),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(title: Text(l10n.profileTitle)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.profileLoadError),
              SizedBox(height: Sizes.size16),
              TextButton(
                onPressed: () => ref.invalidate(currentProfileProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
      data: (profile) => _buildBody(profile),
    );
  }

  void _initFormIfNeeded(Profile profile) {
    if (_initialDataLoaded) return;
    if (_nicknameController.text.isNotEmpty) return;

    _nicknameController.text = profile.nickname;
    _nicknameController.selection = TextSelection.collapsed(
      offset: profile.nickname.length,
    );
    setState(() {
      _nickname = profile.nickname;
      _originalNickname = profile.nickname;
      _isNicknameValid =
          profile.nickname.isNotEmpty &&
          profile.nickname.length <= _nicknameMaxLength;
      _initialDataLoaded = true;
    });
  }

  Widget _buildAvatar(Profile? profile) {
    final nickname = _nickname.isEmpty ? "?" : _nickname;
    if (_pendingImagePath != null) {
      final size = CustomSizes.avatarDefault * 2;
      return ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: Image(
            image: FileImage(File(_pendingImagePath!)),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    if (_pendingDeleteImage) {
      return AvatarDefault(nickname: nickname);
    }
    return AvatarDefault(nickname: nickname, avatarUrl: profile?.avatarUrl);
  }

  Widget _buildBody(Profile? profile) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: _onScaffoldTap,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.profileTitle),
          actions: [
            GestureDetector(
              onTap: (_hasChanges && _isNicknameValid && !_isSaving)
                  ? _onSubmit
                  : null,
              child: Opacity(
                opacity: _hasChanges && _isNicknameValid && !_isSaving
                    ? 1.0
                    : 0.3,
                child: FaIcon(FontAwesomeIcons.solidCircleCheck),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.only(
            left: Paddings.scaffoldH,
            right: Paddings.scaffoldH,
            top: Paddings.profileV,
            bottom: Paddings.scaffoldV,
          ),
          child: Column(
            children: [
              GestureDetector(
                onTap: _onAvatarTap,
                child: Stack(
                  children: [
                    _buildAvatar(profile),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        alignment: Alignment.center,
                        width: Sizes.size20,
                        height: Sizes.size20,
                        decoration: BoxDecoration(
                          color: isDarkMode(context)
                              ? CustomColors.clickableAreaDark
                              : CustomColors.clickableAreaLight,
                          borderRadius: BorderRadius.circular(Sizes.size24),
                          border: Border.all(
                            color: isDarkMode(context)
                                ? CustomColors.borderDark
                                : CustomColors.borderLight,
                          ),
                        ),
                        child: FaIcon(
                          FontAwesomeIcons.pencil,
                          size: Sizes.size10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Gaps.v32,
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _nicknameController,
                  maxLength: _nicknameMaxLength,
                  style: TextStyle(fontSize: Sizes.size14),
                  cursorHeight: Sizes.size14,
                  cursorColor: isDarkMode(context)
                      ? Colors.white
                      : Colors.black,
                  cursorErrorColor: isDarkMode(context)
                      ? Colors.white
                      : Colors.black,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofocus: true,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.done,
                  hintLocales: const [Locale('en', 'US')],
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(_nicknameMaxLength),
                  ],
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(RValues.button),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDarkMode(context)
                        ? CustomColors.clickableAreaDark
                        : CustomColors.clickableAreaLight,
                    prefix: SizedBox(width: Sizes.size16),
                    suffix: GestureDetector(
                      onTap: _onReset,
                      child: Opacity(
                        opacity: _nickname.isNotEmpty ? 1.0 : 0.0,
                        child: FaIcon(
                          FontAwesomeIcons.circleXmark,
                          size: Sizes.size16,
                        ),
                      ),
                    ),
                    hintText: l10n.profileNicknameHint,
                    counterText: '', // maxLength 기본 카운터 숨김
                    hintStyle: TextStyle(
                      color: isDarkMode(context)
                          ? CustomColors.hintColorDark
                          : CustomColors.hintColorLight,
                    ),
                    errorStyle: TextStyle(
                      fontSize: Sizes.size12,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode(context)
                          ? CustomColors.destructiveColorDark
                          : CustomColors.destructiveColorLight,
                    ),
                    error: _errorText != null
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: Sizes.size6),
                              child: Text(
                                _errorText!,
                                style: TextStyle(
                                  fontSize: Sizes.size12,
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode(context)
                                      ? CustomColors.destructiveColorDark
                                      : CustomColors.destructiveColorLight,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : null,
                  ),
                  onChanged: _onChange,
                  onEditingComplete: () {
                    // return 누르면 키보드 먼저 내림 (iOS에서 키보드 타입이 숫자로 바뀌는 버그 회피)
                    FocusScope.of(context).unfocus();
                    _onSubmit();
                  },
                  onSaved: _onSaved,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
