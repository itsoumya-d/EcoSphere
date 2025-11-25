class LocationService {
  Future<Map<String, double>> getCurrentLocation() async {
    // Mock location (New York)
    await Future.delayed(const Duration(seconds: 1));
    return {
      'latitude': 40.7128,
      'longitude': -74.0060,
    };
  }
}
