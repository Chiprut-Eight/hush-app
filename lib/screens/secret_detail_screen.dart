import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:hush_app/l10n/app_localizations.dart';
import '../widgets/title_setter.dart';
import '../config/theme.dart';
import '../models/secret.dart';
import '../services/secret_service.dart';
import '../services/geo_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/secret_card.dart';

class SecretDetailScreen extends StatefulWidget {
  static String? activeSecretId;

  final String secretId;
  final bool openComments;
  final String? highlightCommentId;
  final bool bypassDistance;

  const SecretDetailScreen({
    super.key, 
    required this.secretId,
    this.openComments = false,
    this.highlightCommentId,
    this.bypassDistance = false,
  });

  @override
  State<SecretDetailScreen> createState() => _SecretDetailScreenState();
}

class _SecretDetailScreenState extends State<SecretDetailScreen> with WidgetsBindingObserver {
  final SecretService _secretService = SecretService();
  Secret? _secret;
  bool _isLoading = true;
  String? _error;
  bool _isDeleted = false;
  bool _isNetworkError = false;
  Position? _userPosition;
  Timer? _autoRefreshTimer;
  StreamSubscription<Position>? _positionStreamSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SecretDetailScreen.activeSecretId = widget.secretId;
    _fetchSecretDetails();
    _startLocationTracking();
    _startAutoRefresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<AuthProvider>().enableScreenProtectionForScreen();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _autoRefreshTimer?.cancel();
      _autoRefreshTimer = null;
      _positionStreamSub?.cancel();
      _positionStreamSub = null;
    } else if (state == AppLifecycleState.resumed) {
      _fetchSecretDetails(silent: true);
      _startLocationTracking();
      _startAutoRefresh();
    }
  }

  void _startLocationTracking() {
    _positionStreamSub?.cancel();
    try {
      _positionStreamSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3, // Live GPS update every 3 meters moved
        ),
      ).listen((Position position) {
        if (mounted) {
          setState(() {
            _userPosition = position;
          });
        }
      }, onError: (err) {
        debugPrint('[SecretDetailScreen] Location stream error: $err');
      });
    } catch (e) {
      debugPrint('[SecretDetailScreen] Failed to start location stream: $e');
    }
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (mounted && !_isLoading) {
        _fetchSecretDetails(silent: true);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRefreshTimer?.cancel();
    _positionStreamSub?.cancel();
    if (SecretDetailScreen.activeSecretId == widget.secretId) {
      SecretDetailScreen.activeSecretId = null;
    }
    super.dispose();
  }

  Future<void> _fetchSecretDetails({bool silent = false, bool isPullToRefresh = false}) async {
    if (!silent && !isPullToRefresh && _secret == null) {
      setState(() {
        _isLoading = true;
        _error = null;
        _isDeleted = false;
        _isNetworkError = false;
      });
    }

    try {
      // Safely fetch GPS position
      try {
        final position = await GeoService.getCurrentPositionSafe();
        if (mounted) {
          setState(() {
            _userPosition = position;
          });
        }
      } catch (geoError) {
        debugPrint('[SecretDetailScreen] Location fetch failed: $geoError');
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
          _error = null;
          _isNetworkError = false;
        });
      }
    } catch (e) {
      if (mounted && (_secret == null || isPullToRefresh)) {
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
      return RefreshIndicator(
        onRefresh: () => _fetchSecretDetails(isPullToRefresh: true),
        color: HushColors.textAccent,
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: _buildErrorState(
              icon: Icons.wifi_off_rounded,
              message: l10n.networkError,
              buttonText: l10n.retry,
              onButtonPressed: _fetchSecretDetails,
            ),
          ),
        ),
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
      return RefreshIndicator(
        onRefresh: () => _fetchSecretDetails(isPullToRefresh: true),
        color: HushColors.textAccent,
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: _buildErrorState(
              icon: Icons.error_outline,
              message: _error ?? 'Something went wrong',
              buttonText: l10n.retry,
              onButtonPressed: _fetchSecretDetails,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _fetchSecretDetails(silent: false, isPullToRefresh: true);
      },
      color: HushColors.textAccent,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 60,
          bottom: 24,
        ),
        child: _buildContent(),
      ),
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
        bypassDistance: widget.bypassDistance,
        onDelete: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

