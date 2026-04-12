import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:hush_app/l10n/app_localizations.dart';
import '../models/secret.dart';
import '../services/secret_service.dart';
import '../widgets/secret_card.dart';
import '../config/theme.dart';
import '../core/constants/icons.dart';
import '../widgets/hush_icon_widget.dart';
import '../widgets/hush_drawer.dart';

/// Map screen — shows the Echo Map with pulsing markers
class MapScreen extends StatefulWidget {
  final double? targetLat;
  final double? targetLng;

  const MapScreen({
    super.key,
    this.targetLat,
    this.targetLng,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final SecretService _secretService = SecretService();
  final MapController _mapController = MapController();
  
  List<Secret> _secrets = [];
  bool _isLoading = true;
  String? _error;
  Position? _currentPosition;
  Secret? _selectedSecret;

  @override
  void initState() {
    super.initState();
    _fetchMapData();
  }

  Future<void> _fetchMapData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services are disabled.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      _currentPosition = await Geolocator.getCurrentPosition();

      final secrets = await _secretService.getSecretsForMap(
        _currentPosition!.latitude, 
        _currentPosition!.longitude
      );

      if (mounted) {
        setState(() {
          _secrets = secrets;
          _isLoading = false;
        });

        // If target was passed, jump camera there
        if (widget.targetLat != null && widget.targetLng != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _mapController.move(LatLng(widget.targetLat!, widget.targetLng!), 18.0);
          });
        }
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

  void _onMarkerTapped(Secret secret) {
    setState(() {
      _selectedSecret = secret;
    });
    _mapController.move(LatLng(secret.lat, secret.lng), 16.0);
  }

  Color _getTierColor(String hexCode) {
    try {
      final code = hexCode.replaceAll('#', '0xFF');
      return Color(int.parse(code));
    } catch (_) {
      return Colors.grey;
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
        title: Text(l10n.mapTitle, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : HushColors.textPrimaryLight)),
        backgroundColor: (isDark ? HushColors.bgPrimary : HushColors.bgPrimaryLight).withValues(alpha: 0.8),
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: HushIcon(HushIcons.target, size: 20, color: isDark ? Colors.white : HushColors.textPrimaryLight),
            onPressed: () {
              if (_currentPosition != null) {
                _mapController.move(
                  LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 
                  15.0
                );
              } else {
                _fetchMapData();
              }
            },
          ),
          IconButton(
            icon: HushIcon(HushIcons.refresh, size: 20, color: isDark ? Colors.white : HushColors.textPrimaryLight),
            onPressed: _fetchMapData,
          ),
        ],
      ),
      body: _buildMapBody(),
    );
  }

  Widget _buildMapBody() {
    final bool isOverlay = widget.targetLat != null;
    
    if (_isLoading && _currentPosition == null) {
      return const Center(child: CircularProgressIndicator(color: HushColors.textAccent));
    }

    if (_error != null && _currentPosition == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HushIcon(HushIcons.error, size: 48, color: Colors.amber),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchMapData,
                child: const Text('Retry'),
              )
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            initialZoom: 15.0,
            onTap: (tapPosition, point) {
              if (_selectedSecret != null) {
                setState(() => _selectedSecret = null);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.hush.app',
              retinaMode: MediaQuery.of(context).devicePixelRatio > 1.0,
            ),
            MarkerLayer(
              markers: [
                // User Current Location Marker
                if (_currentPosition != null)
                  Marker(
                    point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Secrets Markers
                ..._secrets.map((secret) {
                  final isSelected = _selectedSecret?.id == secret.id;
                  final color = _getTierColor(secret.creatorTierColor);
                  
                  return Marker(
                    point: LatLng(secret.lat, secret.lng),
                    width: 80,
                    height: 80,
                    child: _PulsingMarkerWidget(
                      color: color,
                      isSelected: isSelected,
                      icon: secret.type == 'voice' ? Icons.mic : Icons.article,
                      onTap: () => _onMarkerTapped(secret),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
        
        // Selected Secret Overlay Card
        if (_selectedSecret != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: SafeArea(
              child: SecretCard(secret: _selectedSecret!, userPosition: _currentPosition),
            ),
          ),
          
        // Loading Overlay
        if (_isLoading && _currentPosition != null)
          Positioned(
            top: 100,
            left: MediaQuery.of(context).size.width / 2 - 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: HushColors.textAccent),
              ),
            ),
          ),
          
        if (isOverlay)
          Positioned(
            top: 48,
            left: 16,
            child: FloatingActionButton.small(
              onPressed: () => Navigator.pop(context),
              backgroundColor: HushColors.bgCard,
              elevation: 4,
              child: const HushIcon(HushIcons.arrowLeft, size: 24, color: HushColors.textAccent),
            ),
          )
      ],
    );
  }
}

class _PulsingMarkerWidget extends StatefulWidget {
  final Color color;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;

  const _PulsingMarkerWidget({
    required this.color,
    required this.isSelected,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_PulsingMarkerWidget> createState() => _PulsingMarkerWidgetState();
}

class _PulsingMarkerWidgetState extends State<_PulsingMarkerWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer Pulse Ring
              if (!widget.isSelected)
                Container(
                  width: 80 * _controller.value,
                  height: 80 * _controller.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(alpha: (1.0 - _controller.value) * 0.4),
                  ),
                ),
              // Inner Core Background (for selected state or base)
              Container(
                width: widget.isSelected ? 48 : 28,
                height: widget.isSelected ? 48 : 28,
                decoration: BoxDecoration(
                  color: widget.isSelected ? widget.color : widget.color.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: widget.isSelected ? 3 : 1),
                  boxShadow: widget.isSelected 
                      ? [BoxShadow(color: widget.color, blurRadius: 10, spreadRadius: 2)] 
                      : [],
                ),
                child: Center(
                  child: Icon(
                    widget.icon,
                    color: Colors.white,
                    size: widget.isSelected ? 24 : 14,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
