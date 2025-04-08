import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:prayer_times_test/prayer_calucations.dart';
import 'package:prayer_times_test/shimmer_loading_effect.dart';

class PrayerTimesPage extends StatefulWidget {
  const PrayerTimesPage({super.key});

  @override
  State<PrayerTimesPage> createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends State<PrayerTimesPage> {
  final prayerTimes = PrayerTimes();
  Map<String, String> _prayerTimes = {};
  bool _isLoading = true;
  String _location = 'Loading location...';
  int _asrMethod = 1; // 0 for standard, 1 for Hanafi

  @override
  void initState() {
    super.initState();
    _checkAndRequestLocationPermission(context); // Call the new function
  }

  // New function to check and request permissions:
  Future<void> _checkAndRequestLocationPermission(BuildContext context) async {
    final permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      final requestedPermission = await Geolocator.requestPermission();

      if (requestedPermission == LocationPermission.denied) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are required.')),
        );
        return;
      }
    } else if (permission == LocationPermission.deniedForever) {
      openAppSettings();
      return;
    }
    _fetchPrayerTimes();
    _getLocation();
  }

  Future<void> _fetchPrayerTimes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final times = await prayerTimes.getPrayerTimesBasedOnLocation(_asrMethod);

      if (times.isEmpty) {
        setState(() {
          _isLoading = false;
          _prayerTimes = {};
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Prayer times not available, check location permissions and internet connection.',
            ),
          ),
        );
        return;
      }

      final filteredTimes = Map<String, String>.from(times)..removeWhere(
        (key, value) =>
            key == 'Imsak' ||
            key == 'Sunrise' ||
            key == 'Sunset' ||
            key == 'Midnight' ||
            key == 'Firstthird' ||
            key == 'Lastthird',
      );

      setState(() {
        _prayerTimes = filteredTimes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _prayerTimes = {};
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching prayer times: $e')),
      );
    }
  }

  Future<void> _getLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        setState(() {
          _location =
              '${placemark.locality ?? 'Unknown'},\n${placemark.administrativeArea ?? 'Unknown'}';
        });
      } else {
        setState(() {
          _location = 'Lat: ${position.latitude}, Lon: ${position.longitude}';
        });
      }
    } catch (e) {
      setState(() {
        _location = 'Location not available: $e';
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Prayer Times')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _prayerTimes.isNotEmpty
              ? Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _location,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.tertiary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.tertiary,
                              fontSize: 14,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            // dropdownColor:
                            //     Theme.of(context).colorScheme.sec,
                            value: _asrMethod,
                            items: const [
                              DropdownMenuItem(
                                value: 0,
                                child: Text('Standard'),
                              ),
                              DropdownMenuItem(value: 1, child: Text('Hanafi')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _asrMethod = value!;
                                _isLoading = true;
                              });
                              _fetchPrayerTimes();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  ..._prayerTimes.entries.map((entry) {
                    return Card(
                      surfaceTintColor: Colors.transparent,
                      margin: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 10,
                      ),
                      child: ListTile(
                        title: Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Text(
                          entry.value,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              )
              : const Center(child: Text('Prayer times not available.')),
    );
  }
}
