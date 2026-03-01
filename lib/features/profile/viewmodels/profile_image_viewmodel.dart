import 'dart:io';

import 'package:bemyday/features/profile/providers/profile_provider.dart';
import 'package:bemyday/features/profile/providers/profile_repository_provider.dart';
import 'package:bemyday/features/profile/repositories/profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

/// [ViewModel] 프로필 이미지 상태 관리
///
/// - 이미지 선택, 크롭, 저장, 삭제 로직 담당
/// - Supabase Storage 업로드 후 profiles.avatar_url 연동
class ProfileImageViewModel extends Notifier<String?> {
  ProfileRepository get _profileRepo => ref.read(profileRepositoryProvider);

  final ImagePicker _picker = ImagePicker();

  @override
  String? build() => null;

  /// 현재 프로필 이미지 경로
  String? get currentImagePath => state;

  /// 프로필 이미지가 있는지 확인
  bool get hasImage => state != null && state!.isNotEmpty;

  /// 갤러리에서 이미지 선택
  Future<XFile?> pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    return image;
  }

  /// 이미지 크롭 (정방형)
  Future<CroppedFile?> cropImage(String sourcePath, BuildContext context) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Edit Photo',
          toolbarColor: Theme.of(context).scaffoldBackgroundColor,
          toolbarWidgetColor: Theme.of(context).iconTheme.color,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          activeControlsWidgetColor: Theme.of(context).primaryColor,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: 'Edit Photo',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          aspectRatioPickerButtonHidden: true,
          cancelButtonTitle: 'Cancel',
          doneButtonTitle: 'Done',
          // 크롭 영역 외부 배경색
          // hidesNavigationBar: false,
          // rotateButtonsHidden: true,
          // rotateClockwiseButtonHidden: true,
        ),
      ],
    );
    return croppedFile;
  }

  /// 프로필 이미지 저장 (Supabase Storage 업로드 + profiles.avatar_url 업데이트)
  Future<void> saveImage(String path) async {
    final file = File(path);
    if (!await file.exists()) return;

    await _profileRepo.uploadAvatar(file);
    state = null;
    ref.invalidate(currentProfileProvider);
  }

  /// 프로필 이미지 삭제 (Storage에서 삭제 + profiles.avatar_url null 처리)
  Future<void> deleteImage() async {
    await _profileRepo.deleteAvatar();
    state = null;
    ref.invalidate(currentProfileProvider);
  }
}

/// ViewModel Provider
final profileImageViewModelProvider =
    NotifierProvider<ProfileImageViewModel, String?>(
  () => ProfileImageViewModel(),
);
