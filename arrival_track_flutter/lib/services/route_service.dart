import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RouteService {
  static final String _apiKey = dotenv.env['OPENROUTE_API_KEY'] ?? '';

  static Future<double?> calculateETA(Position currentLocation, String destinationAddress) async {
    print('RouteService: starting ETA calc');
    print('RouteService: Destination: $destinationAddress');
    print('RouteService: Current location: ${currentLocation.latitude}, ${currentLocation.longitude}');
    print('RouteService: API key present: ${_apiKey.isNotEmpty}');
    if (_apiKey.isEmpty) {
      print('RouteService: no api key');
      return null;
    }
    
    try {
      // geocode
      print('RouteService: Geogoding');
      final geocodeUrl = Uri.parse(
        'https://api.openrouteservice.org/geocode/search?'
        'text=${Uri.encodeComponent(destinationAddress)}'
        '&api_key=$_apiKey',
      );
      print('RouteService: Geocode URL: $geocodeUrl');

      final geocodeResponse = await http.get(geocodeUrl).timeout(const Duration(seconds: 10));
      print('RouteService: Geocode status: ${geocodeResponse.statusCode}');
      print('RouteService: Geocode response body: ${geocodeResponse.body}');
      
      if (geocodeResponse.statusCode != 200) {
        print('RouteService: Geocode failed with status ${geocodeResponse.statusCode}');
        return null;
      }
      
      final geocodeJson = json.decode(geocodeResponse.body);
      if (geocodeJson['features'] == null || (geocodeJson['features'] as List).isEmpty) {
        print('RouteService: No geocode results for "$destinationAddress"');
        return null;
      }

      final coords = geocodeJson['features'][0]['geometry']['coordinates'];
      final destLon = coords[0];
      final destLat = coords[1];
      print('RouteService: Geocoded to: $destLat, $destLon');

      // calc route
      print('RouteService: Route calc');
      final routeUrl = Uri.parse(
        'https://api.openrouteservice.org/v2/directions/driving-car?'
        'start=${currentLocation.longitude},${currentLocation.latitude}'
        '&end=$destLon,$destLat'
        '&api_key=$_apiKey',
      );
      print('RouteService: Route URL: $routeUrl');

      final routeResponse = await http.get(routeUrl).timeout(const Duration(seconds: 10));
      print('RouteService: Route status: ${routeResponse.statusCode}');
      print('RouteService: Route response body: ${routeResponse.body}');
      
      if (routeResponse.statusCode != 200) {
        print('RouteService: Route failed with status ${routeResponse.statusCode}');
        return null;
      }
      
      final routeJson = json.decode(routeResponse.body);
      if (routeJson['features'] == null || (routeJson['features'] as List).isEmpty) {
        print('RouteService: No route found between start and end points');
        print('RouteService: Start: ${currentLocation.latitude}, ${currentLocation.longitude}');
        print('RouteService: End: $destLat, $destLon');
        return null;
      }

      final durationSeconds = routeJson['features'][0]['properties']['segments'][0]['duration'] as num;
      print('RouteService: ETA: $durationSeconds seconds (${(durationSeconds / 60).toStringAsFixed(1)} minutes)');
      print('RouteService: ETA calced is that a word?');
      return durationSeconds.toDouble();
    } on TimeoutException catch (e) {
      print('RouteService: TIMEOUT: Request took too long: $e');
      return null;
    } catch (e) {
      print('RouteService: ERROR: $e');
      print('RouteService: Stack trace: ${e.toString()}');
      return null;
    }
  }
}
