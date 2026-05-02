import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hush_app/l10n/app_localizations.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    final error = await context.read<AuthProvider>().signInWithGoogle();
    if (mounted) {
      setState(() => _isLoading = false);
      if (error != null && error != 'User cancelled sign in') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    final error = await context.read<AuthProvider>().signInWithApple();
    if (mounted) {
      setState(() => _isLoading = false);
      if (error != null && error != 'User cancelled sign in') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              HushColors.bgPrimary,
              Color(0xFF0D1320),
              HushColors.bgPrimary,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo with pulse animation
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: child,
                          );
                        },
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: HushColors.textAccent.withValues(alpha: 0.2),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo_hushhh2.jpeg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Title
                      ShaderMask(
                        shaderCallback: (bounds) => HushColors.brandGradient.createShader(bounds),
                        child: Text(
                          l10n.loginTitle,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        l10n.loginSubtitle,
                        style: const TextStyle(
                          fontSize: 16,
                          color: HushColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 48),

                      if (_isLoading)
                        const CircularProgressIndicator(color: HushColors.textAccent)
                      else ...[
                        // Google Sign-In button
                        _buildSignInButton(
                          onPressed: _signInWithGoogle,
                          icon: Icons.g_mobiledata,
                          label: l10n.signInWithGoogle,
                          backgroundColor: Colors.white,
                          textColor: Colors.black87,
                        ),

                        const SizedBox(height: 16),

                        // Apple Sign-In button
                        _buildSignInButton(
                          onPressed: _signInWithApple,
                          icon: Icons.apple,
                          label: l10n.signInWithApple,
                          backgroundColor: Colors.white,
                          textColor: Colors.black87,
                        ),
                      ],

                      const SizedBox(height: 48),

                      // Decorative wave lines (matching web)
                      _buildSoundWaves(),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.language, color: Colors.white),
                  onPressed: () {
                    context.read<LocaleProvider>().toggleLocale();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24, color: textColor),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildSoundWaves() {
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(7, (index) {
          final heights = [12.0, 20.0, 28.0, 36.0, 28.0, 20.0, 12.0];
          return AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              final offset = (index * 0.15);
              final value = (_pulseAnimation.value + offset).clamp(0.5, 1.0);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 3,
                height: heights[index] * value,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: HushColors.brandGradient,
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
