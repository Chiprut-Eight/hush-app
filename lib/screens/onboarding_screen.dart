import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import 'package:hush_app/l10n/app_localizations.dart';

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select your Date of Birth')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authParams = context.read<AuthProvider>();
      final u = authParams.hushUser!;
      
      await FirebaseFirestore.instance.collection('users').doc(u.uid).update({
        'isOnboarded': true,
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'dateOfBirth': Timestamp.fromDate(_dateOfBirth!),
        'gender': _gender,
        'useGenericPhoto': _useGenericPhoto,
      });
      
      // Refresh the auth provider so the root router kicks us to the AppShell
      await authParams.refreshProfile();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: HushColors.bgPrimary,
      appBar: AppBar(
        title: Text(l10n.onboardingTitle),
        automaticallyImplyLeading: false, // Prevents back button to login page blindly
      ),
      body: SingleChildScrollView(
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
                value: _gender,
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
                  activeColor: HushColors.textAccent,
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
    );
  }
}
