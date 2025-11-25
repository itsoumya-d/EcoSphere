import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'emission_factors.dart';

/// Enhanced Impact Calculator with real carbon calculations
/// Replaces the placeholder logic with comprehensive emission factors
class ImpactCalculator {
  /// Calculate impact score (0-1000 scale)
  /// Based on daily carbon footprint compared to targets
  double calculateScore({
    required String commute,
    required String diet,
    required String energy,
  }) {
    // Calculate daily emissions based on user's lifestyle choices
    final dailyEmissions = CarbonCalculator.estimateDailyFootprint(
      commuteMode: _getCommuteMode(commute),
      commuteMiles: _getCommuteMiles(commute),
      dietType: _getDietType(diet),
      homeEnergy: _getEnergyUsage(energy),
      recycling: _doesRecycle(energy),
    );

    // Convert to eco score
    return CarbonCalculator.toEcoScore(dailyEmissions);
  }

  /// Get commute mode from user selection
  String _getCommuteMode(String commute) {
    switch (commute) {
      case 'Car':
        return 'car_gasoline';
      case 'Public Transit':
        return 'bus';
      case 'Bike / Walk':
        return 'bike';
      case 'Remote Work':
        return 'bike'; // 0 emissions
      default:
        return 'car_gasoline';
    }
  }

  /// Get commute miles from user selection
  double _getCommuteMiles(String commute) {
    switch (commute) {
      case 'Car':
      case 'Public Transit':
        return 20.0; // Round trip
      case 'Bike / Walk':
        return 10.0; // Shorter distances
      case 'Remote Work':
        return 0.0;
      default:
        return 10.0;
    }
  }

  /// Get diet type from user selection
  String _getDietType(String diet) {
    switch (diet) {
      case 'Meat-heavy':
        return 'omnivore';
      case 'Balanced':
        return 'omnivore';
      case 'Vegetarian':
        return 'vegetarian';
      case 'Vegan':
        return 'vegan';
      default:
        return 'omnivore';
    }
  }

  /// Get energy usage from user selection
  double _getEnergyUsage(String energy) {
    switch (energy) {
      case 'High (Always on)':
        return 35.0; // kWh per day
      case 'Average':
        return 25.0;
      case 'Low (Eco-conscious)':
        return 15.0;
      default:
        return 25.0;
    }
  }

  /// Check if user recycles based on energy behavior
  bool _doesRecycle(String energy) {
    return energy == 'Low (Eco-conscious)';
  }

  /// Calculate detailed breakdown by category
  Map<String, double> calculateBreakdown({
    required String commute,
    required String diet,
    required String energy,
  }) {
    final breakdown = <String, double>{};

    // Transport emissions
    final commuteMode = _getCommuteMode(commute);
    final commuteMiles = _getCommuteMiles(commute);
    breakdown['transport'] = CarbonCalculator.transportation(
      mode: commuteMode,
      miles: commuteMiles,
    );

    // Diet emissions
    final dietType = _getDietType(diet);
    double dietEmissions = 0.0;
    
    switch (dietType) {
      case 'omnivore':
        dietEmissions += CarbonCalculator.diet(foodType: 'beef', servings: 0.3);
        dietEmissions += CarbonCalculator.diet(foodType: 'chicken', servings: 0.5);
        dietEmissions += CarbonCalculator.diet(foodType: 'vegetables', servings: 2.0);
        break;
      case 'vegetarian':
        dietEmissions += CarbonCalculator.diet(foodType: 'cheese', servings: 0.3);
        dietEmissions += CarbonCalculator.diet(foodType: 'vegetables', servings: 3.0);
        break;
      case 'vegan':
        dietEmissions += CarbonCalculator.diet(foodType: 'tofu', servings: 0.5);
        dietEmissions += CarbonCalculator.diet(foodType: 'vegetables', servings: 3.5);
        break;
    }
    breakdown['diet'] = dietEmissions;

    // Energy emissions
    final energyUsage = _getEnergyUsage(energy);
    breakdown['energy'] = CarbonCalculator.energy(
      source: 'electricity_us_avg',
      kwh: energyUsage,
    );

    // Waste emissions
    final recycling = _doesRecycle(energy);
    if (recycling) {
      breakdown['waste'] = CarbonCalculator.waste(
        wasteType: 'recycled_paper',
        kg: 0.5,
      );
    } else {
      breakdown['waste'] = CarbonCalculator.waste(
        wasteType: 'landfill_general',
        kg: 1.5,
      );
    }

    return breakdown;
  }

  /// Get personalized recommendations based on breakdown
  List<String> getRecommendations(Map<String, double> breakdown) {
    final recommendations = <String>[];

    // Sort by impact (highest first)
    final sorted = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Top 3 recommendations based on highest emissions
    for (var i = 0; i < sorted.length && i < 3; i++) {
      final category = sorted[i].key;
      final impact = sorted[i].value;

      switch (category) {
        case 'transport':
          if (impact > 8.0) {
            recommendations.add('🚴 Try biking or public transit 2x per week - save ~4 kg CO₂/week');
          } else if (impact > 4.0) {
            recommendations.add('🚌 Carpool when possible to cut transport emissions in half');
          }
          break;
        case 'diet':
          if (impact > 15.0) {
            recommendations.add('🥗 Replace 1 beef meal with chicken/plant-based - save ~20 kg CO₂/week');
          } else if (impact > 8.0) {
            recommendations.add('🌱 Try Meatless Monday - save ~3 kg CO₂/week');
          }
          break;
        case 'energy':
          if (impact > 10.0) {
            recommendations.add('💡 Switch to LED bulbs and smart plugs - save ~5 kg CO₂/month');
          } else if (impact > 5.0) {
            recommendations.add('🔌 Unplug electronics when not in use - save ~2 kg CO₂/month');
          }
          break;
        case 'waste':
          if (impact > 0.5) {
            recommendations.add('♻️ Start recycling and composting - save ~1.5 kg CO₂/week');
          }
          break;
      }
    }

    if (recommendations.isEmpty) {
      recommendations.add('🌟 You\'re doing great! Keep up your eco-friendly habits');
    }

    return recommendations;
  }

  /// Calculate yearly projection based on current habits
  double calculateYearlyProjection(double dailyEmissions) {
    return CarbonCalculator.dailyToYearly(dailyEmissions);
  }

  /// Compare to average person
  Map<String, dynamic> compareToAverage(double dailyEmissions) {
    const usAverage = 43.8; // kg CO2/day
    const globalAverage = 11.0;
    const target = 13.7;

    final vsUSAverage = ((dailyEmissions - usAverage) / usAverage) * 100;
    final vsGlobalAverage = ((dailyEmissions - globalAverage) / globalAverage) * 100;
    final vsTarget = ((dailyEmissions - target) / target) * 100;

    return {
      'vsUSAverage': vsUSAverage,
      'vsGlobalAverage': vsGlobalAverage,
      'vsTarget': vsTarget,
      'isAboveTarget': dailyEmissions > target,
      'isAboveUSAverage': dailyEmissions > usAverage,
      'isAboveGlobalAverage': dailyEmissions > globalAverage,
    };
  }
}

final impactCalculatorProvider = Provider<ImpactCalculator>((ref) {
  return ImpactCalculator();
});
