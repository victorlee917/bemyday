import 'package:bemyday/common/widgets/avatar/avatar_default.dart';
import 'package:bemyday/constants/gaps.dart';
import 'package:bemyday/constants/sizes.dart';
import 'package:bemyday/constants/styles.dart';
import 'package:go_router/go_router.dart';
import 'package:bemyday/features/profile/models/profile.dart';
import 'package:bemyday/features/profile/providers/profile_provider.dart';
import 'package:bemyday/features/profile/viewmodels/profile_image_viewmodel.dart';
import 'package:bemyday/features/profile/viewmodels/profile_viewmodel.dart';
import 'package:bemyday/features/profile/widgets/profile_image_sheet.dart';
import 'package:bemyday/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

  Future<void> _onSubmit() async {
    if (_formKey.currentState == null || !_isNicknameValid || _isSaving) return;

    _formKey.currentState!.save();
    final nickname = _nickname.trim();
    if (nickname.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(profileViewModelProvider).saveNickname(nickname);
      if (!mounted) return;
      _onSaveSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장에 실패했습니다. 다시 시도해 주세요.')));
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
    _formKey.currentState?.reset();
    setState(() {
      _nickname = "";
      _isNicknameValid = false;
      _errorText = null;
    });
  }

  static const int _nicknameMaxLength = 17;
  static const String _forbiddenCharError =
      '닉네임은 영문, 숫자, 마침표(.), 언더스코어(_)만 사용 가능합니다.';

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
    setState(() {
      _nickname = value;
      if (hasForbiddenChar) {
        _errorText = _forbiddenCharError;
        _isNicknameValid = false;
      } else if (value.isEmpty) {
        _errorText = 'Please write your nickname';
        _isNicknameValid = false;
      } else if (value.length > _nicknameMaxLength) {
        _errorText = '최대 $_nicknameMaxLength자까지 입력 가능합니다';
        _isNicknameValid = false;
      } else {
        _errorText = null;
        _isNicknameValid = true;
      }
    });
  }

  void _onSaveSuccess() {
    ref.invalidate(currentProfileProvider);
    if (widget.fromOnboarding) {
      context.go('/home');
    } else {
      context.pop();
    }
  }

  void _onAvatarTap() {
    final profile = ref.read(currentProfileProvider).valueOrNull;
    final hasImage = profile?.avatarUrl != null;

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

    // 1. 갤러리에서 이미지 선택
    final pickedImage = await viewModel.pickImage();
    if (pickedImage == null) return;

    // 2. 이미지 크롭 (정방형)
    if (!mounted) return;
    final croppedFile = await viewModel.cropImage(pickedImage.path, context);
    if (croppedFile == null) return;

    // 3. Supabase Storage에 업로드
    try {
      await viewModel.saveImage(croppedFile.path);
      if (!mounted) return;
      context.pop(); // 시트 닫기
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필 사진 업로드에 실패했습니다. 다시 시도해 주세요.')),
      );
    }
  }

  Future<void> _onDeletePhoto() async {
    final viewModel = ref.read(profileImageViewModelProvider.notifier);
    try {
      await viewModel.deleteImage();
      if (!mounted) return;
      context.pop(); // 시트 닫기
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필 사진 삭제에 실패했습니다. 다시 시도해 주세요.')),
      );
    }
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
        if (profile != null && !_initialDataLoaded && _nicknameController.text.isEmpty) {
          _initFormIfNeeded(profile);
        }
      });
    });

    return profileAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text('Profile')),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(title: Text('Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('프로필을 불러오지 못했습니다'),
              SizedBox(height: Sizes.size16),
              TextButton(
                onPressed: () => ref.invalidate(currentProfileProvider),
                child: Text('다시 시도'),
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
    _nicknameController.selection =
        TextSelection.collapsed(offset: profile.nickname.length);
    setState(() {
      _nickname = profile.nickname;
      _isNicknameValid = profile.nickname.isNotEmpty &&
          profile.nickname.length <= _nicknameMaxLength;
      _initialDataLoaded = true;
    });
  }

  Widget _buildBody(Profile? profile) {
    return GestureDetector(
      onTap: _onScaffoldTap,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Profile'),
          actions: [
            GestureDetector(
              onTap: _isSaving ? null : _onSubmit,
              child: Opacity(
                opacity: _isNicknameValid && !_isSaving ? 1.0 : 0.3,
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
                    AvatarDefault(
                      nickname: _nickname.isEmpty ? "?" : _nickname,
                      avatarUrl: profile?.avatarUrl,
                    ),
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
                  cursorColor: Theme.of(context).primaryColor,
                  cursorErrorColor: Theme.of(context).primaryColor,
                  autocorrect: false,
                  autofocus: true,
                  keyboardType: TextInputType.name,
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
                    hintText: "What's your Nickname?",
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
                              ),
                            ),
                          )
                        : null,
                  ),
                  onChanged: _onChange,
                  onEditingComplete: _onSubmit,
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
