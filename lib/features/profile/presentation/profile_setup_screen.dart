import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  int _currentStep = 0;
  final int _totalSteps = 3;

  // Selections
  String? _commute;
  String? _diet;
  String? _energy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalize Your Experience'),
        actions: [
          TextButton(
            onPressed: () {
               context.go('/home');
            },
            child: const Text('Skip'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: _buildStepContent(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _currentStep--;
                        });
                      },
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox.shrink(),
                  FilledButton(
                    onPressed: _canContinue()
                        ? () {
                            if (_currentStep < _totalSteps - 1) {
                              setState(() {
                                _currentStep++;
                              });
                            } else {
                              // Finish Setup
                              context.go('/home');
                            }
                          }
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Text(_currentStep == _totalSteps - 1 ? 'Finish' : 'Next'),
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

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildQuestion(
          'How do you usually commute?',
          ['Car', 'Public Transit', 'Bike / Walk', 'Remote Work'],
          _commute,
          (val) => setState(() => _commute = val),
        );
      case 1:
        return _buildQuestion(
          'What describes your diet best?',
          ['Meat-heavy', 'Balanced', 'Vegetarian', 'Vegan'],
          _diet,
          (val) => setState(() => _diet = val),
        );
      case 2:
        return _buildQuestion(
          'How would you rate your home energy usage?',
          ['Low (Eco-conscious)', 'Average', 'High (Always on)'],
          _energy,
          (val) => setState(() => _energy = val),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildQuestion(
    String question,
    List<String> options,
    String? selectedValue,
    Function(String) onSelect,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 32),
        ...options.map((option) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: InkWell(
                onTap: () => onSelect(option),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selectedValue == option
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: selectedValue == option
                        ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selectedValue == option
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: selectedValue == option
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        option,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: selectedValue == option
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            )),
      ],
    );
  }

  bool _canContinue() {
    switch (_currentStep) {
      case 0:
        return _commute != null;
      case 1:
        return _diet != null;
      case 2:
        return _energy != null;
      default:
        return false;
    }
  }
}
