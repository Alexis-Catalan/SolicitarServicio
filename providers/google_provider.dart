import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:radio_taxi_alfa_app/src/api/environment.dart';
import 'package:radio_taxi_alfa_app/src/models/directions.dart';

class GoogleProvider {

  Future<dynamic> getGoogleMapsDirections (double origenLat, double origenLng, double destinoLat, double destinoLng) async {
    print('SE ESTA EJECUTANDO');

    Uri uri = Uri.https(
        'maps.googleapis.com',
        'maps/api/directions/json', {
      'key': Environment.API_KEY_MAPS,
      'origin': '$origenLat,$origenLng',
      'destination': '$destinoLat,$destinoLng',
      'traffic_model' : 'best_guess',
      'departure_time': DateTime.now().microsecondsSinceEpoch.toString(),
      'mode': 'driving',
      'transit_routing_preferences': 'less_driving'
    }
    );
    print('URL: $uri');
    final response = await http.get(uri);
    final decodedData = json.decode(response.body);
    final leg = new Direction.fromJsonMap(decodedData['routes'][0]['legs'][0]);
    return leg;
  }
}