import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../config/theme.dart';

class ChangeUsernameScreen extends StatefulWidget {
  const ChangeUsernameScreen({super.key});

  @override
  State<ChangeUsernameScreen> createState() => _ChangeUsernameScreenState();
}

class _ChangeUsernameScreenState extends State<ChangeUsernameScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().hushUser;
    if (user != null && user.displayName != null) {
      _controller.text = user.displayName!;
    }
  }

  bool _canChangeUsername() {
    final user = context.read<AuthProvider>().hushUser;
    if (user == null) return false;
    if (user.lastUsernameChange == null) return true;

    final daysSinceLastChange = DateTime.now().difference(user.lastUsernameChange!).inDays;
    return daysSinceLastChange >= 180;
  }

  String _getTimeRemaining() {
    final user = context.read<AuthProvider>().hushUser;
    if (user == null || user.lastUsernameChange == null) return "";
    
    final daysSinceLastChange = DateTime.now().difference(user.lastUsernameChange!).inDays;
    final daysLeft = 180 - daysSinceLastChange;
    return "תוכל לשנות שוב בעוד $daysLeft ימים";
  }

  Future<void> _saveUsername() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.hushUser;
    final firebaseUser = authProvider.firebaseUser;
    if (user == null || firebaseUser == null) return;

    final newName = _controller.text.trim();
    if (newName.isEmpty) {
      setState(() => _error = "שם המשתמש אינו יכול להיות ריק");
      return;
    }
    if (newName.length < 3) {
      setState(() => _error = "שם המשתמש חייב להכיל לפחות 3 תווים");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Update Firebase Auth
      await firebaseUser.updateDisplayName(newName);
      
      // Update Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'displayName': newName,
        'searchName': newName.toLowerCase(),
        'lastUsernameChange': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("שם המשתמש עודכן בהצלחה!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = "שגיאה בעדכון השם: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final canChange = _canChangeUsername();

    return Scaffold(
      appBar: AppBar(
        title: Text("שינוי שם משתמש", style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "שם משתמש חדש",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              enabled: canChange,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: HushColors.textAccent, width: 2),
                ),
                hintText: "הכנס את שמך...",
              ),
            ),
            const SizedBox(height: 16),
            if (!canChange)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "שינוי שם מתאפשר רק אחת לחצי שנה (180 ימים).\n${_getTimeRemaining()}",
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: canChange && !_isLoading ? _saveUsername : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: HushColors.textAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("שמור שם חדש", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
