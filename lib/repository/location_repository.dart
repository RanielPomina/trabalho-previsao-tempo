import 'package:shared_preferences/shared_preferences.dart';

class LocationRepository {
  static const _keyLastLocation = 'last_location';

  Future<String?> loadLastLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastLocation);
  }

  Future<void> saveLocation(String location) async {
    final prefs = await SharedPreferences.getInstance();
    final atual = prefs.getString(_keyLastLocation);
    if (atual != location) {
      await prefs.setString(_keyLastLocation, location);
    }
  }
}
