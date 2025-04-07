import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class PrayerTimes {
  Future<Map<String, String>> getPrayerTimes(
      Position position, int asrMethod) async {
    try {
      final latitude = position.latitude;
      final longitude = position.longitude;
      final date = DateTime.now();

      final url = Uri.parse(
        'http://api.aladhan.com/v1/timings/${date.millisecondsSinceEpoch ~/ 1000}?latitude=$latitude&longitude=$longitude&method=2&asr=$asrMethod&school=$asrMethod',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          final timings = data['data']['timings'];
          return Map<String, String>.from(timings);
        } else {
          throw Exception(
              'Failed to load prayer times: ${data['code']} - ${data['status']}');
        }
      } else {
        throw Exception('Failed to load prayer times: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching prayer times: $e');
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Handle denied forever case more robustly.
      return Future.error(
          'Location permissions are permanently denied, please enable them in app settings.');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<Map<String, String>> getPrayerTimesBasedOnLocation(
      int asrMethod) async {
    try {
      final position = await _determinePosition();
      return await getPrayerTimes(position, asrMethod);
    } catch (e) {
      return {};
    }
  }
}
