import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import 'package:hush_app/l10n/app_localizations.dart';
import '../services/analytics_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  
  DateTime? _dateOfBirth;
  String _gender = 'other'; // default
  bool _useGenericPhoto = false;

  bool _isSubmitting = false;
  bool _isUploadingPhoto = false;

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day), 
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: HushColors.textAccent,
              onPrimary: Colors.white,
              surface: HushColors.bgCard,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  Future<void> _showPhotoOptions() async {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.read<AuthProvider>();
    
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
            if (authProvider.firebaseUser?.photoURL != null)
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
      setState(() => _useGenericPhoto = false);
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Localizations.localeOf(context).languageCode == 'he' ? 'אנא בחר תאריך לידה' : 'Please select your Date of Birth')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authParams = context.read<AuthProvider>();
      final u = authParams.hushUser!;
      final firebaseUser = authParams.firebaseUser;
      
      final fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
      
      if (firebaseUser != null) {
        await firebaseUser.updateDisplayName(fullName);
      }
      
      await FirebaseFirestore.instance.collection('users').doc(u.uid).update({
        'isOnboarded': true,
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'displayName': fullName,
        'email': authParams.firebaseUser?.email,
        'dateOfBirth': Timestamp.fromDate(_dateOfBirth!),
        'gender': _gender,
        'useGenericPhoto': _useGenericPhoto,
        'searchName': fullName.toLowerCase(),
      });
      
      // Refresh the auth provider so the root router kicks us to the AppShell
      await authParams.refreshProfile();

      AnalyticsService().logOnboardingCompleted(gender: _gender, useGenericPhoto: _useGenericPhoto);
      AnalyticsService().logSignUp('firebase');

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.watch<AuthProvider>();
    final firebaseUser = authProvider.firebaseUser;
    final hushUser = authProvider.hushUser;
    
    // Prioritize the Firestore URL (hushUser) which we know is fully fresh
    final currentPhotoUrl = hushUser?.photoURL ?? firebaseUser?.photoURL;
    
    return Scaffold(
      backgroundColor: HushColors.bgPrimary,
      appBar: AppBar(
        title: Text(l10n.onboardingTitle),
        automaticallyImplyLeading: false, // Prevents back button to login page blindly
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.onboardingWelcome, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Text(l10n.onboardingSub, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 32),

              Center(
                child: GestureDetector(
                  onTap: _showPhotoOptions,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        key: ValueKey(currentPhotoUrl),
                        radius: 50,
                        backgroundColor: HushColors.bgCard,
                        backgroundImage: (currentPhotoUrl != null && !_useGenericPhoto)
                            ? CachedNetworkImageProvider(currentPhotoUrl)
                            : null,
                        child: (currentPhotoUrl == null || _useGenericPhoto)
                            ? const Icon(Icons.person, size: 50, color: HushColors.textSecondary)
                            : null,
                      ),
                      if (!_useGenericPhoto)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: HushColors.textAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                          ),
                        ),
                      if (_isUploadingPhoto)
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(color: HushColors.textAccent),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(labelText: l10n.firstName),
                validator: (val) => val == null || val.isEmpty ? l10n.firstNameReq : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(labelText: l10n.lastName),
                validator: (val) => val == null || val.isEmpty ? l10n.lastNameReq : null,
              ),
              const SizedBox(height: 24),

              InkWell(
                onTap: () => _pickDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(labelText: l10n.dateOfBirth),
                  child: Text(
                    _dateOfBirth != null 
                        ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}' 
                        : l10n.selectDate,
                    style: TextStyle(color: _dateOfBirth != null ? Colors.white : Colors.white54),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: InputDecoration(labelText: l10n.gender),
                items: [
                  DropdownMenuItem(value: 'male', child: Text(l10n.genderMale)),
                  DropdownMenuItem(value: 'female', child: Text(l10n.genderFemale)),
                  DropdownMenuItem(value: 'other', child: Text(l10n.genderOther)),
                ],
                onChanged: (val) => setState(() => _gender = val!),
              ),
              const SizedBox(height: 24),

              Card(
                color: HushColors.bgCard,
                child: SwitchListTile(
                  title: Text(l10n.hidePhoto),
                  subtitle: Text(l10n.hidePhotoSub, style: const TextStyle(fontSize: 12)),
                  value: _useGenericPhoto,
                  activeThumbColor: HushColors.textAccent,
                  onChanged: (val) => setState(() => _useGenericPhoto = val),
                ),
              ),
              const SizedBox(height: 48),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(l10n.completeReg, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
