import 'package:flutter/material.dart';
import 'screens/weather_home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const BlueMoonWeathersApp());
}

class BlueMoonWeathersApp extends StatelessWidget {
  const BlueMoonWeathersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BlueMoonWeathers',
      debugShowCheckedModeBanner:
          false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home:
          const WeatherHomeScreen(),
    );
  }
}
