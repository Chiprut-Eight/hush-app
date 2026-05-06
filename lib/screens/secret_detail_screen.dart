import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hush_app/l10n/app_localizations.dart';
import '../config/theme.dart';
import '../models/secret.dart';
import '../services/secret_service.dart';
import '../widgets/secret_card.dart';

class SecretDetailScreen extends StatefulWidget {
  final String secretId;

  const SecretDetailScreen({super.key, required this.secretId});

  @override
  State<SecretDetailScreen> createState() => _SecretDetailScreenState();
}

class _SecretDetailScreenState extends State<SecretDetailScreen> {
  final SecretService _secretService = SecretService();
  Secret? _secret;
  bool _isLoading = true;
  String? _error;
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
        throw Exception('Secret not found or deleted.');
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
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.hushhh, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : HushColors.textPrimaryLight)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : HushColors.textPrimaryLight),
      ),
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
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: HushColors.textAccent));
    }

    if (_error != null || _secret == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            _error ?? 'Secret not found',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SecretCard(
        secret: _secret!,
        userPosition: _userPosition,
        onDelete: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
