/// Emission factors for various activities (kg CO2 equivalent)
/// Sources: EPA, DEFRA, and scientific research
class EmissionFactors {
  // TRANSPORTATION (kg CO2 per mile)
  static const Map<String, double> transportation = {
    // Personal vehicles
    'car_gasoline': 0.404, // Average passenger car
    'car_diesel': 0.411,
    'car_hybrid': 0.243,
    'car_electric': 0.082, // US average grid
    'suv_gasoline': 0.548,
    'truck_gasoline': 0.694,
    
    // Public transit
    'bus': 0.101,
    'train_commuter': 0.041,
    'subway': 0.035,
    'light_rail': 0.038,
    
    // Rideshare
    'uber_pool': 0.152,
    'uber_solo': 0.404,
    
    // Air travel (kg CO2 per passenger mile)
    'flight_short':  0.255, // < 300 miles
    'flight_medium': 0.180, // 300-2300 miles
    'flight_long': 0.160, // > 2300 miles
    
    // Active transport
    'bike': 0.0,
    'walk': 0.0,
    'scooter_electric': 0.008,
  };

  // DIET (kg CO2 per serving/kg)
  static const Map<String, double> diet = {
    // Meat (per 100g serving)
    'beef': 27.0,
    'lamb': 23.0,
    'pork': 6.9,
    'chicken': 5.7,
    'turkey': 4.8,
    'fish_farmed': 5.0,
    'fish_wild': 3.0,
    
    // Dairy (per 100g/ml)
    'milk': 1.9,
    'cheese': 13.5,
    'butter': 12.0,
    'yogurt': 2.5,
    'ice_cream': 4.0,
    
    // Plant-based
    'tofu': 2.0,
    'beans': 0.9,
    'lentils': 0.9,
    'rice': 2.7,
    'pasta': 1.4,
    'bread': 0.7,
    'vegetables': 0.4,
    'fruits': 0.4,
    'nuts': 1.5,
    
    // Beverages (per liter)
    'coffee': 1.2,
    'tea': 0.4,
    'soda': 0.5,
    'beer': 0.5,
    'wine': 1.4,
  };

  // ENERGY (kg CO2 per kWh)
  static const Map<String, double> energy = {
    'electricity_us_avg': 0.385,
    'electricity_coal': 0.820,
    'electricity_natural_gas': 0.450,
    'electricity_renewable': 0.0,
    'natural_gas_heating': 0.184, // per therm
    'heating_oil': 10.16, // per gallon
  };

  // WASTE (kg CO2 equivalent)
  static const Map<String, double> waste = {
    'landfill_general': 0.5, // per kg
    'recycled_paper': -1.0, // savings
    'recycled_plastic': -1.5,
    'recycled_metal': -2.0,
    'recycled_glass': -0.3,
    'composted': -0.05,
  };

  // SHOPPING (kg CO2 per item)
  static const Map<String, double> shopping = {
    'fast_fashion_item': 15.0,
    'sustainable_clothing': 3.0, 
    'shoes': 13.0,
    'smartphone': 80.0,
    'laptop': 300.0,
    'cheap_electronics': 50.0,
  };

  // MONTHLY AVERAGES (kg CO2/month)
  static const Map<String, double> monthlyAverages = {
    'streaming_1h_per_day': 3.0,
    'social_media_2h_per_day': 1.5,
    'home_heating_avg': 150.0,
    'home_cooling_avg': 100.0,
  };
}

/// Typical distances and usage patterns
class UsagePatterns {
  static const double avgCommuteMiles = 10.0; // per day
  static const double avgAnnualFlightMiles = 2000.0;
  static const double avgDailyCalories = 2000.0;
  static const double avgHouseholdKwhPerMonth = 877.0; // US average
}

/// Carbon footprint calculator
class CarbonCalculator {
  static double _emissions(double factor, num quantity, String name) {
    if (!quantity.isFinite || quantity < 0) {
      throw ArgumentError.value(quantity, name, 'Must be finite and non-negative');
    }
    final result = factor * quantity;
    if (!result.isFinite) {
      throw ArgumentError.value(quantity, name, 'Carbon impact is too large');
    }
    return result;
  }

  static void _requireFinite(double value, String name) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, name, 'Must be finite');
    }
  }

  /// Calculate transportation emissions (kg CO2)
  static double transportation({
    required String mode,
    required double miles,
  }) {
    final factor = EmissionFactors.transportation[mode] ?? 0.0;
    return _emissions(factor, miles, 'miles');
  }

  /// Calculate diet emissions (kg CO2)
  static double diet({
    required String foodType,
    required double servings,
  }) {
    final factor = EmissionFactors.diet[foodType] ?? 0.0;
    return _emissions(factor, servings, 'servings');
  }

  /// Calculate energy emissions (kg CO2)
  static double energy({
    required String source,
    required double kwh,
  }) {
    final factor = EmissionFactors.energy[source] ?? 0.0;
    return _emissions(factor, kwh, 'kwh');
  }

  /// Calculate waste emissions (kg CO2)
  static double waste({
    required String wasteType,
    required double kg,
  }) {
    final factor = EmissionFactors.waste[wasteType] ?? 0.0;
    return _emissions(factor, kg, 'kg');
  }

  /// Calculate shopping emissions (kg CO2)
  static double shopping({
    required String item,
    required int quantity,
  }) {
    final factor = EmissionFactors.shopping[item] ?? 0.0;
    return _emissions(factor, quantity, 'quantity');
  }

  /// Estimate daily carbon footprint based on lifestyle
  static double estimateDailyFootprint({
    required String commuteMode,
    required double commuteMiles,
    required String dietType, // omnivore, pescatarian, vegetarian, vegan
    required double homeEnergy, // kWh per day
    bool recycling = false,
  }) {
    double total = 0.0;

    // Transportation
    total += transportation(mode: commuteMode, miles: commuteMiles);

    // Diet
    switch (dietType) {
      case 'omnivore':
        total += diet(foodType: 'beef', servings: 0.3);
        total += diet(foodType: 'chicken', servings: 0.5);
        total += diet(foodType: 'vegetables', servings: 2.0);
        break;
      case 'pescatarian':
        total += diet(foodType: 'fish_farmed', servings: 0.5);
        total += diet(foodType: 'vegetables', servings: 2.5);
        break;
      case 'vegetarian':
        total += diet(foodType: 'cheese', servings: 0.3);
        total += diet(foodType: 'vegetables', servings: 3.0);
        break;
      case 'vegan':
        total += diet(foodType: 'tofu', servings: 0.5);
        total += diet(foodType: 'vegetables', servings: 3.5);
        break;
    }

    // Energy
    total += energy(source: 'electricity_us_avg', kwh: homeEnergy);

    // Waste (with recycling bonus)
    if (recycling) {
      total += waste(wasteType: 'recycled_paper', kg: 0.5);
    } else {
      total += waste(wasteType: 'landfill_general', kg: 1.5);
    }

    _requireFinite(total, 'dailyFootprint');
    return total;
  }

  /// Convert daily emissions to yearly
  static double dailyToYearly(double dailyKgCO2) {
    _requireFinite(dailyKgCO2, 'dailyKgCO2');
    final yearly = dailyKgCO2 * 365;
    _requireFinite(yearly, 'yearlyKgCO2');
    return yearly;
  }

  /// Convert to eco score (0-1000 scale, lower emissions = higher score)
  /// Average US carbon footprint is ~16 tons/year = 43.8 kg/day
  /// Target: < 5 tons/year = 13.7 kg/day
  static double toEcoScore(double dailyKgCO2) {
    _requireFinite(dailyKgCO2, 'dailyKgCO2');
    const double targetDaily = 13.7; // kg CO2 per day
    const double avgDaily = 43.8; // US average
    
    if (dailyKgCO2 <= targetDaily) {
      return 1000.0; // Perfect score
    } else if (dailyKgCO2 >= avgDaily) {
      return 300.0; // Below average
    } else {
      // Linear scale between target and average
      final ratio = (avgDaily - dailyKgCO2) / (avgDaily - targetDaily);
      return 300 + (700 * ratio);
    }
  }

  /// Get eco score label
  static String getScoreLabel(double score) {
    if (score >= 900) return 'Outstanding';
    if (score >= 750) return 'Excellent';
    if (score >= 600) return 'Good';
    if (score >= 450) return 'Fair';
    if (score >= 300) return 'Needs Improvement';
    return 'Critical';
  }

  /// Get recommendation based on biggest emission source
  static String getTopRecommendation(Map<String, double> breakdown) {
    if (breakdown.isEmpty) return 'Start logging your activities!';
    
    final sorted = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final top = sorted.first.key;
    
    switch (top) {
      case 'transport':
        return 'Try carpooling or public transit to reduce transport emissions';
      case 'diet':
        return 'Consider a plant-based meal 2x per week';
      case 'energy':
        return 'Switch to LED bulbs and unplug unused devices';
      case 'waste':
        return 'Start composting and recycling to reduce waste';
      default:
        return 'Keep up the great work!';
    }
  }
}

