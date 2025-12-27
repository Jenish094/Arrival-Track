import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';
import '../services/spotify_service.dart';
import '../services/route_service.dart';
import '../services/autocomplete_service.dart';
import '../services/engine_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _destinationController = TextEditingController();
  List<String> _suggestions = [];
  bool _isLoading = false;
  bool _isCalculating = false;
  String _etaText = '';
  String? _selectedAddress;
  Timer? _debounce;
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    print('HomeScreen: initState called');
    _initDeepLinks();
    _requestPermissions();
    _loadTokensAndRefresh();
    _destinationController.addListener(_onDestinationChanged);
  }

  Future<void> _loadTokensAndRefresh() async {
    await SpotifyService.loadTokens();
    print('HomeScreen: Tokens loaded, isAuthenticated=${SpotifyService.isAuthenticated()}');
    if (mounted) {
      setState(() {
        print('HomeScreen: setState after loading tokens');
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _destinationController.dispose();
    _linkSub?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();
    print('HomeScreen: Initializing deep links');
    final initial = await _appLinks.getInitialLink();
    if (initial != null) {
      print('HomeScreen: Got initial link: $initial');
      _handleIncomingLink(initial);
    }
    
    // 67
    _linkSub = _appLinks.uriLinkStream.listen(
      (uri) {
        print('HomeScreen: Got stream link: $uri');
        _handleIncomingLink(uri);
      },
      onError: (e) {
        print('HomeScreen: Deep link error: $e');
      },
    );
  }

  Future<void> _handleIncomingLink(Uri uri) async {
    print('HomeScreen: Incoming link: $uri');
    if (uri.scheme == 'arrivaltrack' && uri.host == 'auth') {
      final code = uri.queryParameters['code'];
      print('HomeScreen: Extracted code: $code');
      if (code != null) {
        print('HomeScreen: Attempting token exchange...');
        final ok = await SpotifyService.exchangeCodeForToken(code);
        print('HomeScreen: Token exchange result: $ok, isAuthenticated=${SpotifyService.isAuthenticated()}');
        if (ok && mounted) {
          setState(() {
            print('HomeScreen: Calling setState to refresh button');
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✓ Spotify connected')),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✗ Auth failed: status=$ok')),
          );
        }
      } else {
        print('HomeScreen: No code in URL params: ${uri.queryParameters}');
      }
    }
  }

  Future<void> _requestPermissions() async {
    await Permission.location.request();
  }

  void _onDestinationChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (_destinationController.text.length >= 3) {
        setState(() => _isLoading = true);
        final suggestions = await AutocompleteService.fetchSuggestions(_destinationController.text);
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
        });
      } else {
        setState(() => _suggestions = []);
      }
    });
  }

  Future<void> _startTracking() async {
    if (!SpotifyService.isAuthenticated()) {
      print('HomeScreen: Not authenticated, initiating login');
      try {
        await SpotifyService.initiateLogin();
      } catch (e) {
        print('HomeScreen: Login initiation failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open Spotify login: $e')),
          );
        }
      }
      return;
    }

    final destination = _selectedAddress ?? _destinationController.text;
    if (destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a destination')),
      );
      return;
    }

    setState(() {
      _isCalculating = true;
      _etaText = 'Calculating...';
    });

    try {
      print('HomeScreen: Getting current location...');
      // get location
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      print('HomeScreen: Got location: ${position.latitude}, ${position.longitude}');

      // calc the eta
      print('HomeScreen: Calculating ETA for: $destination');
      final etaSeconds = await RouteService.calculateETA(position, destination);
      print('HomeScreen: ETA result: $etaSeconds seconds');
      
      if (etaSeconds == null) {
        print('HomeScreen: ETA calculation returned null');
        if (mounted) {
          setState(() {
            _etaText = 'Could not calculate route. Check your address or try a different location.';
            _isCalculating = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Route calculation failed.\nPossible issues:\n• Invalid address\n• No route exists\n• API key problem'),
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      print('HomeScreen: ETA = ${(etaSeconds / 60).round()} minutes');
      setState(() => _etaText = '${(etaSeconds / 60).round()} min');

      // fetch spotify data
      print('HomeScreen: Fetching Spotify snapshot...');
      final snapshot = await SpotifyService.fetchSnapshot();
      print('HomeScreen: Got snapshot: current=${snapshot.current?.title}, queue length=${snapshot.queue.length}');
      
      if (snapshot.current == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No Spotify track playing')),
          );
        }
        setState(() => _isCalculating = false);
        return;
      }

      // calc arrival
      print('HomeScreen: Calculating arrival...');
      final result = EngineService.calculateArrivalTrack(
        snapshot.current!,
        0,
        snapshot.queue,
        etaSeconds.toInt(),
      );
      print('HomeScreen: Arrival track = ${result.track.title}');

      final songsBetween = snapshot.queue.takeWhile((t) => t.id != result.track.id).length;

      //open google maps
      final mapsUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(destination)}&travelmode=driving');
      if (await canLaunchUrl(mapsUrl)) {
        await launchUrl(mapsUrl, mode: LaunchMode.externalApplication);
      }

      // show popup dialog in the center of the app
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => Dialog(
            backgroundColor: Colors.black.withOpacity(0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF1DB954), width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ArrivalTrack',
                        style: TextStyle(
                          color: Color(0xFF1DB954),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (snapshot.current!.title.isNotEmpty) ...[
                    const Text(
                      'Now Playing:',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      snapshot.current!.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                  ],
                  Center(
                    child: Column(
                      children: [
                        Text(
                          '$songsBetween',
                          style: const TextStyle(
                            fontSize: 48,
                            color: Color(0xFFFFD700),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'songs until arrival',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (result.track.title.isNotEmpty) ...[
                    const Text(
                      "You'll arrive to:",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      result.track.title,
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1DB954),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Got it'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      print('HomeScreen: Error in _startTracking: $e');
      if (mounted) {
        setState(() {
          _etaText = 'Error: ${e.toString().substring(0, 50)}';
          _isCalculating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCalculating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'ArrivalTrack',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1DB954),
                ),
              ),
              const Text(
                '- Jenish Pathak',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // destination
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _destinationController,
                        decoration: InputDecoration(
                          labelText: 'Where to?',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      if (_etaText.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('ETA: $_etaText', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                      if (_isLoading) const LinearProgressIndicator(),
                    ],
                  ),
                ),
              ),

              // autofill
              if (_suggestions.isNotEmpty)
                Card(
                  margin: const EdgeInsets.only(top: 8),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        dense: true,
                        title: Text(_suggestions[index], style: const TextStyle(fontSize: 14)),
                        onTap: () {
                          setState(() {
                            _selectedAddress = _suggestions[index];
                            _destinationController.text = _suggestions[index];
                            _suggestions = [];
                          });
                        },
                      );
                    },
                  ),
                ),

              const Spacer(),

              // start
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isCalculating ? null : _startTracking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1DB954),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _isCalculating
                        ? 'Calculating...'
                        : (SpotifyService.isAuthenticated() ? 'Start Tracking' : 'Login with Spotify'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
