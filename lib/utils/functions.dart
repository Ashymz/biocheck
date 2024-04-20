import 'package:intl/intl.dart';

greeting() {
  DateTime now = DateTime.now();
  int currentHour = now.hour;
  String greeting;

  if (currentHour >= 0 && currentHour < 12) {
    greeting = 'Good Morning! 🌅😃';
  } else if (currentHour >= 12 && currentHour < 18) {
    greeting = 'Good Afternoon! 🌤😊';
  } else {
    greeting = 'Good Evening! 🌙🌜';
  }
  return greeting;
}
