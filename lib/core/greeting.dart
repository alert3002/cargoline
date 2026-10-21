/// Local-time greeting for Cargo Line splash / welcome.
String getGreeting([DateTime? date]) {
  final d = date ?? DateTime.now();
  final minutes = d.hour * 60 + d.minute;
  // 05:00–18:59 → day; 19:00–04:59 → evening
  if (minutes >= 5 * 60 && minutes < 19 * 60) {
    return 'Добрый день';
  }
  return 'Добрый вечер';
}

/// Day welcome art for 05:00–18:59, night art otherwise.
bool isDayGreetingPeriod([DateTime? date]) {
  final d = date ?? DateTime.now();
  final minutes = d.hour * 60 + d.minute;
  return minutes >= 5 * 60 && minutes < 19 * 60;
}
