// Allowance setup screen for creating and configuring allowances
import 'package:flutter/material.dart';
import '../../models/child_model.dart';
import '../../models/allowance_model.dart';
import '../../services/allowance_service.dart';

class AllowanceSetupScreen extends StatefulWidget {
  final ChildModel child;

  const AllowanceSetupScreen({super.key, required this.child});

  @override
  State<AllowanceSetupScreen> createState() => _AllowanceSetupScreenState();
}

class _AllowanceSetupScreenState extends State<AllowanceSetupScreen> {
  final AllowanceService _allowanceService = AllowanceService();

  final TextEditingController _amountController = TextEditingController();
  AllowanceFrequency _frequency = AllowanceFrequency.weekly;
  AllowanceType _type = AllowanceType.standard;

  // Split configuration
  double _spendPercentage = 1.0;
  double _savePercentage = 0.0;

  // Reward-based settings
  bool _requiresApproval = false;
  final List<String> _linkedChores = [];

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _updateSplit(double spend, double save) {
    setState(() {
      _spendPercentage = spend;
      _savePercentage = save;
    });
  }

  Future<void> _createAllowance() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      setState(() => _errorMessage = 'Please enter an amount');
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid amount');
      return;
    }

    if (_spendPercentage + _savePercentage != 1.0) {
      setState(() => _errorMessage = 'Spend and save percentages must add up to 100%');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final allowanceId = await _allowanceService.createAllowance(
        childId: widget.child.id,
        childName: widget.child.name,
        amount: amount,
        frequency: _frequency,
        type: _type,
        spendPercentage: _spendPercentage,
        savePercentage: _savePercentage,
        requiresApproval: _requiresApproval,
        linkedChores: _linkedChores,
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Return success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Allowance created for ${widget.child.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to create allowance: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Setup Allowance for ${widget.child.name}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount input
            const Text(
              'Allowance Amount',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (R)',
                hintText: 'Enter allowance amount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Frequency selection
            const Text(
              'Frequency',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ...AllowanceFrequency.values.map((frequency) {
              return RadioListTile<AllowanceFrequency>(
                title: Text(frequency.displayName),
                value: frequency,
                groupValue: _frequency,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _frequency = value);
                  }
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
              );
            }),

            const SizedBox(height: 24),

            // Allowance type
            const Text(
              'Allowance Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ...AllowanceType.values.map((type) {
              return RadioListTile<AllowanceType>(
                title: Text(type == AllowanceType.standard ? 'Standard Allowance' : 'Reward-Based Allowance'),
                subtitle: Text(type == AllowanceType.standard
                    ? 'Regular automated payments'
                    : 'Payments tied to completed chores or tasks'),
                value: type,
                groupValue: _type,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _type = value);
                  }
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
              );
            }),

            const SizedBox(height: 24),

            // Split configuration
            const Text(
              'Spend vs Save Split',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildSplitSelector(),

            const SizedBox(height: 24),

            // Reward-based settings
            if (_type == AllowanceType.rewardBased) ...[
              const Text(
                'Reward Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Requires Parent Approval'),
                subtitle: const Text('Parent must approve before payment is released'),
                value: _requiresApproval,
                onChanged: (value) => setState(() => _requiresApproval = value),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              const SizedBox(height: 24),
            ],

            // Error message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Create button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createAllowance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Create Allowance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Spend percentage
          Row(
            children: [
              const Icon(Icons.shopping_cart, color: Colors.green),
              const SizedBox(width: 8),
              const Text('Spend'),
              const Spacer(),
              Text('${(_spendPercentage * 100).round()}%'),
            ],
          ),
          Slider(
            value: _spendPercentage,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            onChanged: (value) => _updateSplit(value, 1.0 - value),
            activeColor: Colors.green,
          ),

          const SizedBox(height: 16),

          // Save percentage
          Row(
            children: [
              const Icon(Icons.savings, color: Colors.orange),
              const SizedBox(width: 8),
              const Text('Save'),
              const Spacer(),
              Text('${(_savePercentage * 100).round()}%'),
            ],
          ),
          Slider(
            value: _savePercentage,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            onChanged: (value) => _updateSplit(1.0 - value, value),
            activeColor: Colors.orange,
          ),

          const SizedBox(height: 16),

          // Preview amounts
          if (_amountController.text.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Builder(
                builder: (context) {
                  final total = double.tryParse(_amountController.text) ?? 0;
                  final spend = total * _spendPercentage;
                  final save = total * _savePercentage;

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Spend Amount:'),
                          Text('R ${spend.toStringAsFixed(2)}'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Save Amount:'),
                          Text('R ${save.toStringAsFixed(2)}'),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}