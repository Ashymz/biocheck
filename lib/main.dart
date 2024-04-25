// import 'package:biocheck/splashScreen.dart';
// // import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:flutter/services.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   SystemChrome.setPreferredOrientations([
//     DeviceOrientation.portraitUp,
//     DeviceOrientation.portraitDown,
//   ]);

//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     Color myColor = const Color(0xFF6614CF);
//     return GetMaterialApp(
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: myColor),
//         useMaterial3: true,
//       ),
//       home: const Splashscreen(),
//       defaultTransition: Transition.cupertino,
//     );
//   }
// }
import 'dart:io';
import 'package:biocheck/presentation/scan.dart';
import 'package:biocheck/splashScreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Color myColor = const Color(0xFF6614CF);
    return GetMaterialApp(
      title: 'Facial Reconigtion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: myColor),
        useMaterial3: true,
      ),
      home: const Splashscreen(),
      defaultTransition: Transition.cupertino,
    );
  }
}
