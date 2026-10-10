import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hush_app/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../config/theme.dart';
import 'notifications_settings_screen.dart';
import 'change_username_screen.dart';
import '../widgets/title_setter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isUploadingPhoto = false;

  Future<void> _showPhotoOptions() async {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: HushColors.bgPrimary,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: Text(l10n.photoFromGallery, style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadPhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: Text(l10n.photoFromCamera, style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: HushColors.tierRed),
              title: Text(l10n.photoRemove, style: const TextStyle(color: HushColors.tierRed)),
              onTap: () async {
                Navigator.pop(ctx);
                setState(() => _isUploadingPhoto = true);
                await AuthService().removeProfilePhoto();
                if (!mounted) return;
                await context.read<AuthProvider>().refreshProfile();
                setState(() => _isUploadingPhoto = false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);

      if (image == null) return;
      
      if (!mounted) return;
      final isHe = Localizations.localeOf(context).languageCode == 'he';
      final title = isHe ? 'חיתוך תמונה' : 'Crop Photo';
      final doneBtn = isHe ? 'אישור' : 'Done';
      final cancelBtn = isHe ? 'ביטול' : 'Cancel';
      
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

      if (croppedFile == null) return;

      setState(() => _isUploadingPhoto = true);
      
      final authService = AuthService();
      await authService.updateProfilePhoto(File(croppedFile.path));
      
      if (!mounted) return;
      await context.read<AuthProvider>().refreshProfile();
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.photoUploadFailed}: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.hushUser;

    return TitleSetter(
      title: AppLocalizations.of(context)!.settingsMainTitle,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: user == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                ListView(
                  children: [
                    SwitchListTile(
                      title: Text(AppLocalizations.of(context)!.muteAppSoundsTitle),
                      subtitle: Text(AppLocalizations.of(context)!.muteAppSoundsSub, style: const TextStyle(fontSize: 12)),
                      secondary: const Icon(Icons.volume_off_outlined, color: HushColors.textAccent),
                      activeThumbColor: HushColors.textAccent,
                      value: user.appSoundsMuted,
                      onChanged: (value) {
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .update({'appSoundsMuted': value});
                      },
                    ),
                    ListTile(
                      title: Text(Localizations.localeOf(context).languageCode == 'he' ? 'ברירת מחדל של אופן יצירה מועדף' : 'Default Create Mode'),
                      leading: const Icon(Icons.mode_edit_outline, color: HushColors.textAccent),
                      trailing: SegmentedButton<String>(
                        segments: [
                          ButtonSegment(value: 'text', label: Text(Localizations.localeOf(context).languageCode == 'he' ? 'טקסט' : 'Text')),
                          ButtonSegment(value: 'voice', label: Text(Localizations.localeOf(context).languageCode == 'he' ? 'קול' : 'Voice')),
                        ],
                        selected: {user.defaultCreateMode},
                        onSelectionChanged: (Set<String> newSelection) {
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .update({'defaultCreateMode': newSelection.first});
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                            if (states.contains(WidgetState.selected)) {
                              return HushColors.textAccent.withValues(alpha: 0.2);
                            }
                            return Colors.transparent;
                          }),
                          foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                            if (states.contains(WidgetState.selected)) {
                              return HushColors.textAccent;
                            }
                            return HushColors.textSecondary;
                          }),
                        ),
                      ),
                    ),
                    ListTile(
                      title: Text(AppLocalizations.of(context)!.notificationsSettingsTitle),
                      subtitle: Text(AppLocalizations.of(context)!.notificationsSettingsSub, style: const TextStyle(fontSize: 12)),
                      leading: const Icon(Icons.notifications_active_outlined, color: HushColors.textAccent),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsSettingsScreen()));
                      },
                    ),
                    ListTile(
                      title: Text(AppLocalizations.of(context)!.changeUsernameTitle),
                      leading: const Icon(Icons.edit_outlined, color: HushColors.textAccent),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangeUsernameScreen()));
                      },
                    ),
                    ListTile(
                      title: Text(AppLocalizations.of(context)!.profilePhotoTitle),
                      subtitle: Text(AppLocalizations.of(context)!.profilePhotoSub, style: const TextStyle(fontSize: 12)),
                      leading: const Icon(Icons.account_circle_outlined, color: HushColors.textAccent),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _showPhotoOptions,
                    ),
                  ],
                ),
                if (_isUploadingPhoto)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(color: HushColors.textAccent),
                    ),
                  ),
              ],
            ),
      ),
    );
  }
}
