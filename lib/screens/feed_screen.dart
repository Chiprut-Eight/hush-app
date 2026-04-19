import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hush_app/l10n/app_localizations.dart';
import '../models/secret.dart';
import '../services/secret_service.dart';
import '../widgets/secret_card.dart';
import '../config/theme.dart';
import '../core/constants/icons.dart';
import '../widgets/hush_icon_widget.dart';
import '../widgets/hush_drawer.dart';
import '../widgets/notifications_button.dart';

/// Feed screen — displays nearby secrets with auto-refresh
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final SecretService _secretService = SecretService();
  List<Secret> _secrets = [];
  bool _isLoading = true;
  String? _error;
  Position? _userPosition;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchSecrets();
    // Task 2: Auto-refresh every 45 seconds
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (!_isLoading) {
        _fetchSecrets();
      }
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchSecrets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied, we cannot request permissions.');
      }

      Position position = await Geolocator.getCurrentPosition();

      final secrets = await _secretService.getNearbySecrets(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _secrets = secrets;
          _userPosition = position;
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
      drawer: const HushDrawer(),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.feedTitle, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : HushColors.textPrimaryLight)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          const NotificationsButton(),
          IconButton(
            icon: HushIcon(HushIcons.refresh, size: 20, color: isDark ? Colors.white : HushColors.textPrimaryLight),
            onPressed: _fetchSecrets,
          ),
        ],
      ),
      body: Container(
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

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HushIcon(HushIcons.error, size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchSecrets,
                child: Text(l10n.retry),
              )
            ],
          ),
        ),
      );
    }

    if (_secrets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HushIcon(HushIcons.hearingOff, size: 64, color: HushColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              l10n.feedEmpty,
              style: const TextStyle(color: HushColors.textSecondary, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchSecrets,
      color: HushColors.textAccent,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80, top: 8),
        itemCount: _secrets.length,
        itemBuilder: (context, index) {
          return SecretCard(
            secret: _secrets[index],
            userPosition: _userPosition,
            onDelete: _fetchSecrets,
          );
        },
      ),
    );
  }
}
