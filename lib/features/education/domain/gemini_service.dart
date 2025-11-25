class GeminiService {
  Future<List<String>> getSuggestedActions(String userProfile) async {
    // Mock Gemini response
    await Future.delayed(const Duration(seconds: 1));
    return [
      'Switch to LED bulbs to save energy.',
      'Try a plant-based diet for 3 days a week.',
      'Use public transport for your daily commute.',
      'Install a smart thermostat to optimize heating.',
    ];
  }
}
