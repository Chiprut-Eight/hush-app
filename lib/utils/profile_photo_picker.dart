import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../config/theme.dart';

/// Shared pick + crop flow for profile photos (onboarding, settings, profile).
///
/// Returns the cropped file, or null if the user cancelled.
Future<File?> pickAndCropProfilePhoto(BuildContext context, ImageSource source) async {
  final isHe = Localizations.localeOf(context).languageCode == 'he';
  final title = isHe ? 'חיתוך תמונה' : 'Crop Photo';
  final doneBtn = isHe ? 'אישור' : 'Done';
  final cancelBtn = isHe ? 'ביטול' : 'Cancel';
  final isIOS = Platform.isIOS;

  final XFile? image = await ImagePicker().pickImage(source: source);
  if (image == null) return null;

  // Small delay for iOS to finish UIKit dismiss animation before presenting cropper
  if (isIOS) await Future.delayed(const Duration(milliseconds: 300));

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
}
