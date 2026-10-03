import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hush_app/l10n/app_localizations.dart';
import '../widgets/title_setter.dart';
import '../config/theme.dart';
import '../models/secret.dart';
import '../services/secret_service.dart';
import '../widgets/secret_card.dart';

class SecretDetailScreen extends StatefulWidget {
  final String secretId;
  final bool openComments;
  final String? highlightCommentId;

  const SecretDetailScreen({
    super.key, 
    required this.secretId,
    this.openComments = false,
    this.highlightCommentId,
  });

  @override
  State<SecretDetailScreen> createState() => _SecretDetailScreenState();
}

class _SecretDetailScreenState extends State<SecretDetailScreen> {
  final SecretService _secretService = SecretService();
  Secret? _secret;
  bool _isLoading = true;
  String? _error;
  bool _isDeleted = false;
  bool _isNetworkError = false;
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _fetchSecretDetails();
  }

  Future<void> _fetchSecretDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _isDeleted = false;
      _isNetworkError = false;
    });

    try {
      // Fetch user position (optional, but good for distance calculation)
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          _userPosition = await Geolocator.getCurrentPosition();
        }
      }

      final secret = await _secretService.getSecret(widget.secretId);
      if (secret == null) {
        if (mounted) {
          setState(() {
            _isDeleted = true;
            _isLoading = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _secret = secret;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final errorStr = e.toString().toLowerCase();
          if (errorStr.contains('network') || 
              errorStr.contains('offline') || 
              errorStr.contains('failed host lookup') || 
              errorStr.contains('unavailable') ||
              errorStr.contains('socket')) {
            _isNetworkError = true;
          } else {
            _error = e.toString();
          }
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TitleSetter(
      title: 'Hushhh',
      child: Scaffold(
        extendBodyBehindAppBar: true,
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
              ? [HushColors.bgPrimary, const Color(0xFF0D1320), HushColors.bgPrimary]
              : [HushColors.bgPrimaryLight, HushColors.bgPrimaryLight, HushColors.bgPrimaryLight],
          ),
        ),
        child: SafeArea(
          child: _buildBody(l10n),
        ),
      ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: HushColors.textAccent));
    }

    if (_isNetworkError) {
      return _buildErrorState(
        icon: Icons.wifi_off_rounded,
        message: l10n.networkError,
        buttonText: l10n.retry,
        onButtonPressed: _fetchSecretDetails,
      );
    }

    if (_isDeleted) {
      return _buildErrorState(
        icon: Icons.auto_awesome_outlined,
        message: l10n.secretDeletedMessage,
        buttonText: l10n.discoverMoreHushhh,
        onButtonPressed: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      );
    }

    if (_error != null || _secret == null) {
      return _buildErrorState(
        icon: Icons.error_outline,
        message: _error ?? 'Something went wrong',
        buttonText: l10n.retry,
        onButtonPressed: _fetchSecretDetails,
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 60,
        bottom: 24,
      ),
      child: _buildContent(),
    );
  }

  Widget _buildErrorState({
    required IconData icon,
    required String message,
    required String buttonText,
    required VoidCallback onButtonPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: HushColors.textAccent.withValues(alpha: 0.5)),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onButtonPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: HushColors.textAccent,
                foregroundColor: HushColors.bgPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_secret == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SecretCard(
        secret: _secret!,
        userPosition: _userPosition,
        autoOpenComments: widget.openComments,
        highlightCommentId: widget.highlightCommentId,
        onDelete: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
