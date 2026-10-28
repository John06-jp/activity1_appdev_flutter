import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/local_spot.dart';

class LocalSpotsScreen extends StatefulWidget {
  const LocalSpotsScreen({super.key});
  @override
  State<LocalSpotsScreen> createState() => _LocalSpotsScreenState();
}

class _LocalSpotsScreenState extends State<LocalSpotsScreen>
    with WidgetsBindingObserver {
  final _map = MapController();
  final _tracker = FenceTracker();
  List<LocalSpot> _spots = [];
  List<Map<String, dynamic>> _events = [];
  StreamSubscription<Position>? _positions;
  Timer? _freshness;
  Position? _position;
  SharedPreferences? _storage;
  Future<void> _writes = Future.value();
  bool _loading = true,
      _tracking = false,
      _starting = false,
      _tileError = false;
  int _session = 0;
  String _message = 'Load your verified locations to begin.';

  Color _spotColor(LocalSpot spot) {
    const colors = [
      Color(0xFFD32F2F),
      Color(0xFF1976D2),
      Color(0xFF388E3C),
      Color(0xFFF57C00),
      Color(0xFF7B1FA2),
    ];
    final index = _spots.indexWhere((item) => item.id == spot.id);
    return colors[(index < 0 ? 0 : index) % colors.length];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString('assets/locations.json');
      final spots = (jsonDecode(raw.replaceFirst('\uFEFF', '')) as List)
          .map((e) => LocalSpot.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final storage = await SharedPreferences.getInstance();
      final saved = storage.getString('local_spots_events');
      final events = saved == null
          ? <Map<String, dynamic>>[]
          : (jsonDecode(saved) as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
      if (!mounted) return;
      setState(() {
        _spots = spots;
        _storage = storage;
        _events = events;
        _loading = false;
        _message =
            '${spots.where((s) => s.ready).length} of ${spots.length} locations verified. Tracking works while this screen is open.';
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _message =
              'Could not load locations or saved history. Check location data and restart.';
        });
      }
    }
  }

  Future<void> _persist() {
    final snapshot = jsonEncode(_events);
    _writes = _writes.then((_) async {
      try {
        if (await _storage?.setString('local_spots_events', snapshot) != true) {
          throw StateError('Storage unavailable');
        }
      } catch (_) {
        if (mounted) {
          setState(
            () => _message =
                'History could not be saved. Events remain available for this session.',
          );
        }
      }
    });
    return _writes;
  }

  Future<void> _start() async {
    final session = ++_session;
    setState(() => _starting = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError(
          'GPS is disabled. Enable location services and try again.',
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw StateError(
          'Location permission is blocked. Enable it in app settings.',
        );
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        throw StateError(
          'Location permission is required. Allow location and try again.',
        );
      }
      if (!mounted || session != _session) return;
      _tracker.reset();
      setState(() {
        _tracking = true;
        _message = 'Waiting for a fresh, accurate outdoor GPS reading.';
      });
      _positions =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 0,
            ),
          ).listen(
            (position) {
              if (!mounted || !_tracking || session != _session) return;
              final now = DateTime.now();
              final events = _tracker.update(
                _spots,
                latitude: position.latitude,
                longitude: position.longitude,
                accuracy: position.accuracy,
                timestamp: position.timestamp,
                now: now,
              );
              setState(() {
                _position = position;
                _events.insertAll(0, events.reversed);
                _message = now.difference(position.timestamp).inSeconds > 15
                    ? 'GPS reading is stale. Transitions are paused.'
                    : 'GPS accuracy: ${position.accuracy.toStringAsFixed(0)} m. Boundary uncertainty pauses transitions.';
              });
              if (events.isNotEmpty) {
                _persist();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      events
                          .map(
                            (e) =>
                                '${e['locationName']}: ${e['eventType']} at ${DateTime.parse(e['timestamp'] as String).toLocal()}',
                          )
                          .join('\n'),
                    ),
                  ),
                );
              }
            },
            onError: (Object error) {
              _stop(
                'Location updates failed. Check GPS and permissions, then start again.',
              );
            },
          );
      _freshness = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted || !_tracking) return;
        if (_position == null ||
            DateTime.now().difference(_position!.timestamp).inSeconds > 15) {
          _tracker.rejectReading();
          setState(
            () => _message =
                'Waiting for fresh GPS. Transitions are paused; try an open outdoor area.',
          );
        }
      });
    } catch (error) {
      if (mounted && session == _session) {
        setState(
          () => _message = error is StateError
              ? error.message.toString()
              : 'Unable to start location tracking. Check device settings.',
        );
      }
    } finally {
      if (mounted && session == _session) setState(() => _starting = false);
    }
  }

  void _stop([
    String message =
        'Tracking stopped. Start again to establish a new baseline.',
  ]) {
    ++_session;
    _positions?.cancel();
    _positions = null;
    _freshness?.cancel();
    _tracker.reset();
    _position = null;
    if (mounted) {
      setState(() {
        _tracking = false;
        _starting = false;
        _message = message;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && (_tracking || _starting)) {
      _stop(
        'Tracking paused because the app left the foreground. Tap Start tracking to resume.',
      );
    }
  }

  @override
  void dispose() {
    ++_session;
    WidgetsBinding.instance.removeObserver(this);
    _positions?.cancel();
    _freshness?.cancel();
    _map.dispose();
    super.dispose();
  }

  void _details(LocalSpot spot) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(spot.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(spot.description),
              const SizedBox(height: 12),
              Text(
                'Barangay ${spot.barangay} • Radius ${spot.radius.toStringAsFixed(0)} m',
              ),
              const SizedBox(height: 16),
              if (spot.ready)
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _map.move(LatLng(spot.latitude!, spot.longitude!), 18);
                  },
                  child: const Text('Focus on map'),
                )
              else
                const Text(
                  'Pending field verification. Collect coordinates, check for an existing Google Maps listing, and obtain permission before enabling this location.',
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ready = _spots.where((s) => s.ready).toList();
    final center = ready.isEmpty
        ? const LatLng(8.714, 125.748)
        : LatLng(ready.first.latitude!, ready.first.longitude!);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bayugan Local Spots'),
        actions: [
          IconButton(
            tooltip: 'Tracking help',
            icon: const Icon(Icons.help_outline),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Outdoor tracking'),
                content: const SingleChildScrollView(
                  child: Text(
                    'Tracking stops when you leave this screen or the app leaves the foreground.\n\nAllow precise location and enable GPS. Readings must be at most 15 seconds old, with accuracy within 25 m or half the fence radius. Three consecutive reliable readings confirm a transition. Readings whose accuracy overlaps a boundary do not trigger alerts.\n\nThe first reading establishes status without an entry event. GPS drift can delay alerts. Map tiles need internet; GPS can continue without them.\n\nOnly verified locations appear on the map. Exact private coordinates should not appear in public screenshots.',
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SizedBox(
                  height: 320,
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _map,
                        options: MapOptions(
                          initialCenter: center,
                          initialZoom: 16,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName:
                                'com.example.flutter_activity1_appdev',
                            errorTileCallback: (_, _, _) {
                              if (!_tileError) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (mounted) {
                                    setState(() => _tileError = true);
                                  }
                                });
                              }
                            },
                          ),
                          CircleLayer(
                            circles: ready
                                .map(
                                  (s) => CircleMarker(
                                    point: LatLng(s.latitude!, s.longitude!),
                                    radius: s.radius,
                                    useRadiusInMeter: true,
                                    color: _spotColor(s).withValues(alpha: 0.15),
                                    borderColor: _spotColor(s),
                                    borderStrokeWidth: 2,
                                  ),
                                )
                                .toList(),
                          ),
                          MarkerLayer(
                            markers: [
                              for (final spot in ready)
                                Marker(
                                  point: LatLng(
                                    spot.latitude!,
                                    spot.longitude!,
                                  ),
                                  width: 48,
                                  height: 48,
                                  child: IconButton(
                                    tooltip: spot.name,
                                    onPressed: () => _details(spot),
                                    icon: Icon(
                                      Icons.flag_rounded,
                                      color: _spotColor(spot),
                                      size: 36,
                                    ),
                                  ),
                                ),
                              if (_position != null)
                                Marker(
                                  point: LatLng(
                                    _position!.latitude,
                                    _position!.longitude,
                                  ),
                                  child: const Icon(
                                    Icons.my_location,
                                    color: Colors.blue,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        left: 6,
                        bottom: 6,
                        child: Container(
                          color: Theme.of(context).colorScheme.surface,
                          padding: const EdgeInsets.all(4),
                          child: const Text(
                            '© OpenStreetMap contributors',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: FloatingActionButton.small(
                          heroTag: 'local-spots-recenter',
                          tooltip: 'Recenter on current location',
                          onPressed: _position == null
                              ? null
                              : () => _map.move(
                                  LatLng(
                                    _position!.latitude,
                                    _position!.longitude,
                                  ),
                                  17,
                                ),
                          child: const Icon(Icons.my_location),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _message,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (_tileError)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Some map tiles could not load. Check internet and pan the map to retry. GPS tracking is independent of map tiles.',
                          ),
                        ),
                      if (ready.length < 5)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Setup pending: collect and verify five locations in one barangay. No placeholder coordinates are plotted.',
                          ),
                        ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _starting || ready.isEmpty
                            ? null
                            : (_tracking ? _stop : _start),
                        icon: Icon(_tracking ? Icons.stop : Icons.play_arrow),
                        label: Text(
                          _starting
                              ? 'Starting…'
                              : _tracking
                              ? 'Stop tracking'
                              : 'Start tracking',
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton(
                            onPressed: () => Geolocator.openLocationSettings(),
                            child: const Text('GPS settings'),
                          ),
                          TextButton(
                            onPressed: () => Geolocator.openAppSettings(),
                            child: const Text('App permissions'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Locations',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      for (final spot in _spots)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            spot.ready
                                ? Icons.flag_rounded
                                : Icons.edit_location_alt_outlined,
                            color: _spotColor(spot),
                          ),
                          title: Text(spot.name),
                          subtitle: Text(
                            !spot.ready
                                ? 'Pending verification'
                                : '${_tracker.states[spot.id]?.name ?? 'unknown'} • ${_tracker.distances[spot.id]?.toStringAsFixed(0) ?? '—'} m away',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _details(spot),
                        ),
                      const Divider(),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Event history',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          TextButton(
                            onPressed: _events.isEmpty
                                ? null
                                : () async {
                                    final clear = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text(
                                          'Clear event history?',
                                        ),
                                        content: const Text(
                                          'All saved entry and exit events will be removed.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Clear'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (clear == true && mounted) {
                                      setState(() => _events.clear());
                                      await _persist();
                                    }
                                  },
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                      if (_events.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'No events yet. Verified entries and exits will appear here.',
                          ),
                        ),
                      for (final event in _events)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            event['eventType'] == 'entry'
                                ? Icons.login
                                : Icons.logout,
                          ),
                          title: Text(
                            '${event['locationName']} — ${event['eventType']}',
                          ),
                          subtitle: Text(
                            DateTime.parse(
                              event['timestamp'] as String,
                            ).toLocal().toString(),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
