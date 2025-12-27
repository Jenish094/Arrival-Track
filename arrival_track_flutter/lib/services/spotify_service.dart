import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/track.dart';
import 'package:shared_preferences/shared_preferences.dart';

//genuienly the worst part of this entire project
// I did use AI for some parts of this (VSCode Copilot)
class SpotifyService {
  static String? _accessToken;
  static String? _refreshToken;
  static String? _codeVerifier;
  static final String _clientId = dotenv.env['SPOTIFY_CLIENT_ID'] ?? '';
  static final String _redirectUri = dotenv.env['SPOTIFY_REDIRECT_URI'] ?? '';
  static const String _scopes = 'user-read-private user-read-email user-read-currently-playing user-read-playback-state';

  static Future<void> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('spotify_access_token');
    _refreshToken = prefs.getString('spotify_refresh_token');
    print('SpotifyService: Loaded tokens. isAuthenticated=$_accessToken');
  }

  static Future<void> _saveTokens(String access, String? refresh) async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = access;
    if (refresh != null) _refreshToken = refresh;
    await prefs.setString('spotify_access_token', access);
    if (refresh != null) await prefs.setString('spotify_refresh_token', refresh);
    print('SpotifyService: Saved tokens. Now isAuthenticated=$_accessToken');
  }

  static String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~';
    final rnd = Random.secure();
    return List.generate(length, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  static String _sha256Base64Url(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  static Future<String> _ensureCodeVerifier() async {
    _codeVerifier ??= _randomString(64);
    return _codeVerifier!;
  }

  static Future<String> getAuthorizationUrl() async {
    final verifier = await _ensureCodeVerifier();
    final challenge = _sha256Base64Url(verifier);
    return 'https://accounts.spotify.com/authorize?'
        'client_id=$_clientId'
        '&response_type=code'
        '&redirect_uri=${Uri.encodeComponent(_redirectUri)}'
        '&scope=${Uri.encodeComponent(_scopes)}'
        '&code_challenge_method=S256'
        '&code_challenge=$challenge';
  }

  static Future<void> initiateLogin() async {
    final url = Uri.parse(await getAuthorizationUrl());
    print('SpotifyService: Attempting to launch URL: $url');
    try {
      if (await canLaunchUrl(url)) {
        print('SpotifyService: canLaunchUrl returned true, launching with externalApplication mode');
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        print('SpotifyService: canLaunchUrl returned false, trying platformDefault mode');
        final launched = await launchUrl(url, mode: LaunchMode.platformDefault);
        if (!launched) {
          print('SpotifyService: platformDefault also failed');
          throw Exception('Could not launch Spotify auth URL - no browser available');
        }
      }
    } catch (e) {
      print('SpotifyService: Error launching auth URL: $e');
      rethrow;
    }
  }

  static void setAccessToken(String token) {
    _accessToken = token;
  }

  static bool isAuthenticated() {
    print('SpotifyService: isAuthenticated check: _accessToken=$_accessToken');
    return _accessToken != null;
  }

  static Future<bool> exchangeCodeForToken(String code) async {
    print('SpotifyService: Exchanging code for token');
    try {
      final verifier = await _ensureCodeVerifier();
      print('SpotifyService: Using verifier: $verifier');
      final response = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': _clientId,
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': _redirectUri,
          'code_verifier': verifier,
        },
      ).timeout(const Duration(seconds: 15));

      print('SpotifyService: Token exchange response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('SpotifyService: Got token response: ${data.keys}');
        final access = data['access_token'] as String;
        final refresh = data['refresh_token'] as String?;
        await _saveTokens(access, refresh);
        print('SpotifyService: Token exchange complete. isAuthenticated=${isAuthenticated()}');
        return true;
      } else {
        print('SpotifyService: Token exchange failed: ${response.body}');
      }
      return false;
    } catch (e) {
      print('SpotifyService: Token exchange error: $e');
      return false;
    }
  }

  static Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null || _clientId.isEmpty) {
      print('SpotifyService: No refresh token or clientId to refresh');
      return false;
    }
    try {
      final response = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': _clientId,
          'grant_type': 'refresh_token',
          'refresh_token': _refreshToken!,
        },
      ).timeout(const Duration(seconds: 15));
      print('SpotifyService: Refresh token response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final access = data['access_token'] as String;
        final refresh = data['refresh_token'] as String?;
        await _saveTokens(access, refresh);
        return true;
      } else {
        print('SpotifyService: Refresh failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('SpotifyService: Error refreshing token: $e');
      return false;
    }
  }

  static Future<({Track? current, List<Track> queue})> fetchSnapshot() async {
    if (_accessToken == null) {
      print('No access token available');
      return (current: null, queue: <Track>[]);
    }

    try {
      final currentResponse = await http.get(
        Uri.parse('https://api.spotify.com/v1/me/player/currently-playing'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (currentResponse.statusCode == 401) {
        final refreshed = await _refreshAccessToken();
        if (!refreshed) {
          return (current: null, queue: <Track>[]);
        }
        final retryCurrent = await http.get(
          Uri.parse('https://api.spotify.com/v1/me/player/currently-playing'),
          headers: {'Authorization': 'Bearer $_accessToken'},
        );
        final currentResponseParsed = retryCurrent;
        Track? currentTrack;
        if (currentResponseParsed.statusCode == 200 && currentResponseParsed.body.isNotEmpty) {
          final currentJson = json.decode(currentResponseParsed.body);
          if (currentJson['item'] != null) {
            currentTrack = Track.fromJson(currentJson['item']);
          }
        }
        final queueResponse = await http.get(
          Uri.parse('https://api.spotify.com/v1/me/player/queue'),
          headers: {'Authorization': 'Bearer $_accessToken'},
        );
        List<Track> queue = [];
        if (queueResponse.statusCode == 200) {
          final queueJson = json.decode(queueResponse.body);
          if (queueJson['queue'] != null) {
            queue = (queueJson['queue'] as List)
                .take(50)
                .map((item) => Track.fromJson(item))
                .toList();
          }
        }
        return (current: currentTrack, queue: queue);
      }

      Track? currentTrack;
      if (currentResponse.statusCode == 200 && currentResponse.body.isNotEmpty) {
        final currentJson = json.decode(currentResponse.body);
        if (currentJson['item'] != null) {
          currentTrack = Track.fromJson(currentJson['item']);
        }
      }

      final queueResponse = await http.get(
        Uri.parse('https://api.spotify.com/v1/me/player/queue'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      List<Track> queue = [];
      if (queueResponse.statusCode == 200) {
        final queueJson = json.decode(queueResponse.body);
        if (queueJson['queue'] != null) {
          queue = (queueJson['queue'] as List)
              .take(50)
              .map((item) => Track.fromJson(item))
              .toList();
        }
      }

      return (current: currentTrack, queue: queue);
    } catch (e) {
      print('Error fetching Spotify data: $e');
      return (current: null, queue: <Track>[]);
    }
  }
}
