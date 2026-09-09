import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../domain/user_activity.dart';
import '../../domain/emission_factors.dart';
import '../providers/dashboard_controller.dart';
import '../../../../core/widgets/milestone_celebration.dart';
import '../../../../core/services/gamification_service.dart';

/// Detailed activity entry form for custom activities
class ActivityEntryForm extends ConsumerStatefulWidget {
  const ActivityEntryForm({super.key});

  @override
  ConsumerState<ActivityEntryForm> createState() => _ActivityEntryFormState();
}

class _ActivityEntryFormState extends ConsumerState<ActivityEntryForm> {
  final _formKey = GlobalKey<FormState>();
  ActivityType _selectedType = ActivityType.transport;
  String? _selectedCategory;
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  // Category options for each activity type
  final Map<ActivityType, Map<String, String>> _categoryOptions = {
    ActivityType.transport: {
      'car_gasoline': 'Car (Gasoline)',
      'car_electric': 'Car (Electric)',
      'bus': 'Bus',
      'train_commuter': 'Train',
      'subway': 'Subway',
      'bike': 'Bicycle',
      'walk': 'Walking',
      'flight_short': 'Flight (Short <300mi)',
      'flight_medium': 'Flight (Medium)',
      'flight_long': 'Flight (Long >2300mi)',
    },
    ActivityType.diet: {
      'beef': 'Beef',
      'chicken': 'Chicken',
      'pork': 'Pork',
      'fish_farmed': 'Fish (Farmed)',
      'vegetables': 'Vegetables',
      'tofu': 'Tofu',
      'beans': 'Beans',
      'cheese': 'Cheese',
      'milk': 'Milk',
    },
    ActivityType.energy: {
      'electricity_us_avg': 'Electricity (US Avg)',
      'electricity_renewable': 'Electricity (Renewable)',
      'natural_gas_heating': 'Natural Gas Heating',
    },
    ActivityType.waste: {
      'landfill_general': 'Landfill',
      'recycled_paper': 'Recycled Paper',
      'recycled_plastic': 'Recycled Plastic',
      'recycled_metal': 'Recycled Metal',
      'composted': 'Composted',
    },
    ActivityType.shopping: {
      'fast_fashion_item': 'Fast Fashion',
      'sustainable_clothing': 'Sustainable Clothing',
      'smartphone': 'Smartphone',
      'laptop': 'Laptop',
    },
  };

  // Unit labels for each activity type
  String get _quantityLabel {
    switch (_selectedType) {
      case ActivityType.transport:
        return 'Distance (miles)';
      case ActivityType.diet:
        return 'Servings';
      case ActivityType.energy:
        return 'Energy (kWh)';
      case ActivityType.waste:
        return 'Weight (kg)';
      case ActivityType.shopping:
        return 'Quantity';
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedCategory = _categoryOptions[_selectedType]!.keys.first;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Text(
                  'Log Activity',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Activity Type
                  Text(
                    'Activity Type',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<ActivityType>(
                    segments: const [
                      ButtonSegment(
                        value: ActivityType.transport,
                        label: Text('Transport'),
                        icon: Icon(Icons.directions_car),
                      ),
                      ButtonSegment(
                        value: ActivityType.diet,
                        label: Text('Diet'),
                        icon: Icon(Icons.restaurant),
                      ),
                      ButtonSegment(
                        value: ActivityType.energy,
                        label: Text('Energy'),
                        icon: Icon(Icons.bolt),
                      ),
                      ButtonSegment(
                        value: ActivityType.waste,
                        label: Text('Waste'),
                        icon: Icon(Icons.delete),
                      ),
                      ButtonSegment(
                        value: ActivityType.shopping,
                        label: Text('Shopping'),
                        icon: Icon(Icons.shopping_bag),
                      ),
                    ],
                    selected: {_selectedType},
                    onSelectionChanged: (Set<ActivityType> selected) {
                      setState(() {
                        _selectedType = selected.first;
                        _selectedCategory =
                            _categoryOptions[_selectedType]!.keys.first;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category
                  Text(
                    'Category',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _categoryOptions[_selectedType]!
                        .entries
                        .map((entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Quantity
                  Text(
                    _quantityLabel,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a value';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      if (double.parse(value) <= 0) {
                        return 'Value must be greater than 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Notes (optional)
                  Text(
                    'Notes (Optional)',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Add any additional details...',
                      isDense: true,
                    ),
                    maxLines: 2,
                    maxLength: 500,
                  ),
                  const SizedBox(height: 24),

                  // Preview carbon impact
                  if (_quantityController.text.isNotEmpty &&
                      double.tryParse(_quantityController.text) != null)
                    _buildImpactPreview(),

                  const SizedBox(height: 16),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _submitActivity,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Log Activity'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactPreview() {
    final quantity = double.tryParse(_quantityController.text) ?? 0.0;
    if (quantity <= 0 || _selectedCategory == null) {
      return const SizedBox.shrink();
    }

    double impact = 0.0;
    switch (_selectedType) {
      case ActivityType.transport:
        impact = CarbonCalculator.transportation(
          mode: _selectedCategory!,
          miles: quantity,
        );
        break;
      case ActivityType.diet:
        impact = CarbonCalculator.diet(
          foodType: _selectedCategory!,
          servings: quantity,
        );
        break;
      case ActivityType.energy:
        impact = CarbonCalculator.energy(
          source: _selectedCategory!,
          kwh: quantity,
        );
        break;
      case ActivityType.waste:
        impact = CarbonCalculator.waste(
          wasteType: _selectedCategory!,
          kg: quantity,
        );
        break;
      case ActivityType.shopping:
        impact = CarbonCalculator.shopping(
          item: _selectedCategory!,
          quantity: quantity.toInt(),
        );
        break;
    }

    final colorScheme = Theme.of(context).colorScheme;
    final isPositive = impact < 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPositive
            ? colorScheme.primaryContainer
            : colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.trending_down : Icons.trending_up,
            color: isPositive ? colorScheme.primary : colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Carbon Impact',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                Text(
                  '${impact.abs().toStringAsFixed(2)} kg CO₂',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isPositive
                            ? colorScheme.primary
                            : colorScheme.error,
                      ),
                ),
              ],
            ),
          ),
          if (isPositive)
            Chip(
              label: const Text('Eco-friendly!'),
              backgroundColor: colorScheme.primaryContainer,
              side: BorderSide.none,
            ),
        ],
      ),
    );
  }

  Future<void> _submitActivity() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final quantity = double.parse(_quantityController.text);
      final activity = UserActivity.create(
        userId: user.uid,
        type: _selectedType,
        category: _selectedCategory!,
        quantity: quantity,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      // Save activity via dashboard controller to trigger gamification
      final results = await ref
          .read(dashboardControllerProvider.notifier)
          .addActivity(activity);

      if (mounted) {
        Navigator.of(context).pop();
        
        // Show celebration if leveled up or unlocked badge
        if (results != null) {
          _checkAndShowCelebration(results);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Activity logged! ${activity.carbonImpact < 0 ? "Saved" : "Generated"} ${activity.carbonImpact.abs().toStringAsFixed(1)} kg CO₂',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _checkAndShowCelebration(Map<String, dynamic> results) {
    // Check for level up
    if (results['levelUp'] == true) {
      final newLevel = results['newLevel'] as int;
      final rewards = gamificationService.getLevelUpRewards(newLevel);
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => MilestoneCelebration(
          title: 'Level Up!',
          subtitle: 'You reached Level $newLevel',
          iconUrl: '$newLevel',
          color: _hexToColor(gamificationService.getLevelColor(newLevel)),
          secondaryText: rewards['title'] as String,
          isLevelUp: true,
          onDismiss: () {
            Navigator.of(context).pop();
            // Check for badges after level up dialog closes
            _showBadgeCelebrations(results['badgesUnlocked'] as List<String>?);
          },
        ),
      );
      return; // Return to wait for dismiss callback
    }

    // Check for badges if no level up (or called from callback)
    _showBadgeCelebrations(results['badgesUnlocked'] as List<String>?);
  }

  void _showBadgeCelebrations(List<String>? badgeIds) {
    if (badgeIds == null || badgeIds.isEmpty) return;

    // Show first badge (in a real app, might want to queue them)
    // For now, just showing the first one to avoid dialog stacking issues
    // Note: In a real app we'd fetch the badge details. 
    // For this demo, we'll show a generic badge unlock message
    // or we could look it up from BadgeDefinitions if we had access
    
    // Using a generic celebration for now as we don't have easy synchronous access 
    // to badge details here without making another async call
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MilestoneCelebration(
        title: 'Badge Unlocked!',
        subtitle: 'You earned a new badge',
        iconUrl: '🏆',
        color: Colors.amber,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
