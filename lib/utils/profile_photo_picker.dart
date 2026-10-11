import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';

/// Shared pick + crop flow for profile photos (onboarding, settings, profile).
///
/// iOS notes:
/// - Screenshot protection (screen_protector) is suspended while the native
///   picker / cropper are on screen. Its secure-layer hack breaks when native
///   view controllers are presented on top of it, which left the app with a
///   black, unresponsive screen after a photo change.
/// - A short delay is inserted between the picker dismissal and the cropper
///   presentation, and before restoring protection, so UIKit can finish its
///   dismiss animations.
///
/// Returns the cropped file, or null if the user cancelled.
Future<File?> pickAndCropProfilePhoto(BuildContext context, ImageSource source) async {
  final authProvider = context.read<AuthProvider>();
  final isHe = Localizations.localeOf(context).languageCode == 'he';
  final title = isHe ? 'חיתוך תמונה' : 'Crop Photo';
  final doneBtn = isHe ? 'אישור' : 'Done';
  final cancelBtn = isHe ? 'ביטול' : 'Cancel';
  final isIOS = Platform.isIOS;

  await authProvider.suspendScreenProtection();
  try {
    final XFile? image = await ImagePicker().pickImage(source: source);
    if (image == null) return null;

    // Let the picker finish dismissing before presenting the cropper
    if (isIOS) await Future.delayed(const Duration(milliseconds: 500));

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 70,
      maxWidth: 512,
      maxHeight: 512,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: title,
          toolbarColor: HushColors.bgPrimary,
          toolbarWidgetColor: Colors.white,
          statusBarLight: true,
          activeControlsWidgetColor: HushColors.textAccent,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          cropStyle: CropStyle.circle,
        ),
        IOSUiSettings(
          title: title,
          doneButtonTitle: doneBtn,
          cancelButtonTitle: cancelBtn,
          cropStyle: CropStyle.circle,
        ),
      ],
    );

    if (croppedFile == null) return null;
    return File(croppedFile.path);
  } finally {
    // Let the cropper finish dismissing before re-applying the secure layer
    if (isIOS) await Future.delayed(const Duration(milliseconds: 500));
    await authProvider.resumeScreenProtection();
  }
}
