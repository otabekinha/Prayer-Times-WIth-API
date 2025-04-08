import 'package:flutter/material.dart';
import 'package:prayer_times_test/pages/prayer_times.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      home: PrayerTimesPage(),
    );
  }
}
