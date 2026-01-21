import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/child_model.dart';
import '../../models/transaction_model.dart' as tx;
import '../../models/wallet_model.dart';
import '../../services/child_service.dart';
import '../../services/wallet_service.dart';
import '../../services/security_service.dart';
import '../../services/auth_service.dart';

class SendMoneyDialog extends StatefulWidget {
  final String parentId;
  final List<ChildModel> children;

  const SendMoneyDialog({
    super.key,
    required this.parentId,
    required this.children,
  });

  @override
  State<SendMoneyDialog> createState() => _SendMoneyDialogState();
}

class _SendMoneyDialogState extends State<SendMoneyDialog> {
  int _currentStep = 0;
  String _selectedRecipientType = 'child'; // child, parent, external
  ChildModel? _selectedChild;
  String _externalRecipient = '';
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isScheduled = false;
  DateTime? _scheduledDate;
  bool _isLoading = false;
  String _dailyLimit = 'R 2,000.00';

  final List<double> _quickAmounts = [50, 100, 200, 500];

  // Services
  final ChildService _childService = ChildService();
  final WalletService _walletService = WalletService();
  final SecurityService _securityService = SecurityService();
  final AuthService _authService = AuthService();

  // User data
  WalletModel? _userWallet;
  tx.TransferLimits? _transferLimits;
  List<tx.Transaction> _recentTransactions = [];

  // Authentication
  bool _needsAuth = false;
  String? _authError;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user != null) {
      try {
        // Load wallet
        _userWallet = await _walletService.getOrCreateWallet(user.uid, 'Parent Wallet');

        // Load transfer limits (create if doesn't exist)
        final limitsDoc = await FirebaseFirestore.instance.collection('transfer_limits').doc(user.uid).get();
        if (limitsDoc.exists) {
          _transferLimits = tx.TransferLimits.fromMap(user.uid, limitsDoc.data()!);
        } else {
          _transferLimits = tx.TransferLimits.defaultLimits(user.uid);
          await FirebaseFirestore.instance.collection('transfer_limits').doc(user.uid).set(_transferLimits!.toMap());
        }

        // Reset limits if needed
        _transferLimits = _transferLimits!.resetIfNeeded();
        if (_transferLimits!.dailyUsed > 0) {
          await FirebaseFirestore.instance.collection('transfer_limits').doc(user.uid).update(_transferLimits!.toMap());
        }

        // Load recent transactions
        _recentTransactions = await _walletService.getRecentTransactions(user.uid, limit: 5);

        if (mounted) setState(() {});
      } catch (e) {
        _showError('Failed to load user data: $e');
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF2196F3),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Send Money',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Fast, flexible & secure',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Progress Steps
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  _buildStepIndicator(1, 'To', _currentStep >= 0),
                  _buildStepLine(_currentStep >= 1),
                  _buildStepIndicator(2, 'Amount', _currentStep >= 1),
                  _buildStepLine(_currentStep >= 2),
                  _buildStepIndicator(3, 'Confirm', _currentStep >= 2),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_currentStep == 0) _buildRecipientStep(),
                    if (_currentStep == 1) _buildAmountStep(),
                    if (_currentStep == 2) _buildConfirmStep(),
                  ],
                ),
              ),
            ),

            // Bottom Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _currentStep--;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _currentStep < 2 ? _nextStep : _confirmTransfer,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentStep < 2 ? 'Continue' : 'Confirm Transfer',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
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

  Widget _buildStepIndicator(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF2196F3) : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isActive
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    '$step',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? const Color(0xFF2196F3) : Colors.grey.shade500,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2196F3) : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  Widget _buildRecipientStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Send to',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        // Recipient Type Selection
        Row(
          children: [
            _buildRecipientTypeCard(
              icon: Icons.child_care,
              label: 'Child',
              isSelected: _selectedRecipientType == 'child',
              onTap: () => setState(() => _selectedRecipientType = 'child'),
            ),
            const SizedBox(width: 12),
            _buildRecipientTypeCard(
              icon: Icons.person,
              label: 'Parent',
              isSelected: _selectedRecipientType == 'parent',
              onTap: () => setState(() => _selectedRecipientType = 'parent'),
            ),
            const SizedBox(width: 12),
            _buildRecipientTypeCard(
              icon: Icons.account_balance_wallet,
              label: 'External',
              isSelected: _selectedRecipientType == 'external',
              onTap: () => setState(() => _selectedRecipientType = 'external'),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Child Selection
        if (_selectedRecipientType == 'child') ...[
          const Text(
            'Select Child',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          if (widget.children.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No children added yet. Add a child first.',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            )
          else
            ...widget.children.map((child) => _buildChildTile(child)),
        ],

        // External Recipient
        if (_selectedRecipientType == 'external') ...[
          const Text(
            'Enter Wallet ID or Phone',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: 'Wallet ID or Phone number',
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) => _externalRecipient = value,
          ),
        ],

        // Recent Transfers
        if (_recentTransactions.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            'Quick Resend',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ..._recentTransactions.take(3).map((transaction) => _buildRecentTransferTile(transaction)),
        ],

        // Daily Limit Info
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber.shade800),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Transfer Limit',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade900,
                      ),
                    ),
                    Text(
                      'Remaining: R ${(_transferLimits?.dailyLimit ?? 5000.0) - (_transferLimits?.dailyUsed ?? 0.0)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecipientTypeCard({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF2196F3).withValues(alpha: 0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF2196F3)
                    : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: isSelected ? const Color(0xFF2196F3) : Colors.grey.shade600,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF2196F3)
                        : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChildTile(ChildModel child) {
    final isSelected = _selectedChild?.id == child.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF2196F3).withValues(alpha: 0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF2196F3) : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF2196F3),
                const Color(0xFF1976D2)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              child.initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Text(
          child.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          'Balance: R ${child.balance.toStringAsFixed(2)}',
          style: TextStyle(
            color: child.isFrozen ? Colors.red : Colors.grey.shade600,
          ),
        ),
        trailing: child.isFrozen
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Frozen',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : null,
        onTap: child.isFrozen
            ? null
            : () {
                setState(() {
                  _selectedChild = child;
                });
              },
      ),
    );
  }

  Widget _buildRecentTransferTile(tx.Transaction transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF2196F3),
                const Color(0xFF1976D2)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.send, color: Colors.white, size: 20),
        ),
        title: Text(
          transaction.receiverName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          transaction.formattedDate,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Text(
          transaction.formattedAmount,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: transaction.type == tx.TransactionType.transfer ? Colors.green.shade700 : Colors.red.shade700,
          ),
        ),
        onTap: () {
          // Quick resend - populate the form with this transaction's details
          if (transaction.transferType == tx.TransferType.toChild) {
            setState(() {
              _selectedRecipientType = 'child';
              _selectedChild = widget.children.firstWhere(
                (child) => child.id == transaction.receiverId,
                orElse: () => widget.children.first,
              );
            });
          } else {
            setState(() {
              _selectedRecipientType = 'external';
              _externalRecipient = transaction.receiverName;
            });
          }
          _amountController.text = transaction.amount.toString();
          _messageController.text = transaction.message ?? '';
          _nextStep();
        },
      ),
    );
  }

  Widget _buildAmountStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recipient Info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: _selectedRecipientType == 'child'
                      ? Text(
                          _selectedChild?.initials ?? '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : const Icon(Icons.person, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedRecipientType == 'child'
                          ? _selectedChild?.name ?? 'Child'
                          : _selectedRecipientType == 'parent'
                              ? 'Another Parent'
                              : 'External Wallet',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      _selectedRecipientType == 'external'
                          ? _externalRecipient
                          : 'Send money',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Amount Input
        const Text(
          'Amount',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2196F3),
            ),
            decoration: InputDecoration(
              prefixText: 'R ',
              prefixStyle: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            onChanged: (value) => setState(() {}),
          ),
        ),

        // Quick Amounts
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickAmounts.map((amount) {
            final isSelected = _amountController.text == amount.toString();
            return ChoiceChip(
              label: Text('R $amount'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _amountController.text = amount.toString();
                  setState(() {});
                }
              },
              selectedColor: const Color(0xFF2196F3),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF2196F3)
                      : Colors.grey.shade300,
                ),
              ),
            );
          }).toList(),
        ),

        // Message
        const SizedBox(height: 24),
        const Text(
          'Message (Optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _messageController,
          decoration: InputDecoration(
            hintText: 'e.g., Lunch money, Transport...',
            prefixIcon: const Icon(Icons.message),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // Schedule Transfer
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: SwitchListTile(
            value: _isScheduled,
            onChanged: (value) {
              setState(() {
                _isScheduled = value;
                if (value) {
                  _selectDate();
                }
              });
            },
            title: const Text(
              'Schedule for later',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: _isScheduled && _scheduledDate != null
                ? Text(
                    'Scheduled: ${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year} ${_scheduledDate!.hour}:${_scheduledDate!.minute.toString().padLeft(2, '0')}',
                  )
                : const Text('Send now or schedule for later'),
            secondary: const Icon(Icons.schedule),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmStep() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Confirmation Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF2196F3).withValues(alpha: 0.1),
                const Color(0xFF1976D2).withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text(
                'Transferring',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'R ${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2196F3),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.arrow_forward, color: Colors.grey, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _selectedRecipientType == 'child'
                        ? _selectedChild?.name ?? 'Child'
                        : _selectedRecipientType == 'parent'
                            ? 'Another Parent'
                            : 'External Wallet',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Transfer Details
        _buildDetailRow('From', 'Main Wallet'),
        _buildDetailRow('To',
            _selectedRecipientType == 'child' ? _selectedChild?.name ?? 'Child' : 'External'),
        _buildDetailRow('Message', _messageController.text.isEmpty ? 'None' : _messageController.text),
        _buildDetailRow('Timing', _isScheduled ? 'Scheduled' : 'Instant'),
        if (_isScheduled && _scheduledDate != null)
          _buildDetailRow('Date', '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}'),

        // PIN Confirmation
        const SizedBox(height: 24),
        if (_needsAuth) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.lock_outline, color: Colors.orange.shade600),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'PIN Required',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE65100),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _showPinDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Enter PIN'),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green.shade600),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Authentication completed',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_selectedRecipientType == 'child' && _selectedChild == null) {
        _showError('Please select a child');
        return;
      }
      if (_selectedRecipientType == 'external' && _externalRecipient.isEmpty) {
        _showError('Please enter recipient details');
        return;
      }
    }
    if (_currentStep == 1) {
      final amount = double.tryParse(_amountController.text);
      if (amount == null || amount <= 0) {
        _showError('Please enter a valid amount');
        return;
      }
    }
    setState(() {
      _currentStep++;
    });
  }

  Future<void> _confirmTransfer() async {
    if (_userWallet == null || _transferLimits == null) {
      _showError('User data not loaded. Please try again.');
      return;
    }

    setState(() {
      _isLoading = true;
      _authError = null;
    });

    try {
      final amount = double.parse(_amountController.text);

      // Check balance
      if (_userWallet!.balance < amount) {
        _showError('Insufficient balance. Available: ${_userWallet!.formattedBalance}');
        return;
      }

      // Check transfer limits
      final limitResult = _transferLimits!.canTransfer(amount);
      if (!limitResult.allowed) {
        _showError(limitResult.errorMessage);
        return;
      }

      // Authenticate user
      final authResult = await _securityService.authenticateUser(widget.parentId);
      if (!authResult.success) {
        if (authResult.reason == AuthFailureReason.pinRequired) {
          setState(() {
            _needsAuth = true;
          });
          return;
        } else {
          _showError('Authentication failed. Please try again.');
          return;
        }
      }

      // Perform transfer based on type
      bool success = false;
      if (_selectedRecipientType == 'child' && _selectedChild != null) {
        success = await _childService.transferToChild(
          parentId: widget.parentId,
          childId: _selectedChild!.id,
          amount: amount,
          message: _messageController.text.isEmpty ? null : _messageController.text,
        );
      } else if (_selectedRecipientType == 'external') {
        // For demo, assume external transfer succeeds
        // In production, integrate with payment gateway
        success = true;
      }

      if (success) {
        // Update transfer limits
        _transferLimits = _transferLimits!.copyWithUsage(amount);
        await FirebaseFirestore.instance.collection('transfer_limits').doc(widget.parentId).update(_transferLimits!.toMap());

        // Update wallet balance
        await _walletService.deductFromBalance(_userWallet!.id, amount);

        // Generate receipt
        final receipt = _generateReceipt(amount);

        if (mounted) {
          Navigator.of(context).pop();
          _showSuccessDialog(amount, receipt);
        }
      } else {
        _showError('Transfer failed. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        _showError('Transfer failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _generateReceipt(double amount) {
    return {
      'transactionId': DateTime.now().millisecondsSinceEpoch.toString(),
      'date': DateTime.now().toIso8601String(),
      'sender': _userWallet?.userName ?? 'Parent',
      'receiver': _selectedRecipientType == 'child'
          ? _selectedChild?.name ?? 'Child'
          : _externalRecipient,
      'amount': amount,
      'message': _messageController.text,
      'status': 'completed',
      'transferType': _selectedRecipientType,
    };
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _scheduledDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _showPinDialog() async {
    final pinController = TextEditingController();
    bool isVerifying = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Enter PIN',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Please enter your 4-digit PIN to complete the transfer',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: '****',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  counterText: '',
                ),
              ),
              if (_authError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _authError!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _needsAuth = false;
                  _authError = null;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isVerifying
                  ? null
                  : () async {
                      if (pinController.text.length != 4) {
                        setState(() {
                          _authError = 'Please enter a 4-digit PIN';
                        });
                        return;
                      }

                      setState(() {
                        isVerifying = true;
                        _authError = null;
                      });

                      final success = await _securityService.verifyPIN(
                        widget.parentId,
                        pinController.text,
                      );

                      if (success) {
                        Navigator.of(context).pop();
                        setState(() {
                          _needsAuth = false;
                        });
                        // Retry the transfer
                        _confirmTransfer();
                      } else {
                        setState(() {
                          isVerifying = false;
                          _authError = 'Invalid PIN. Please try again.';
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isVerifying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(double amount, Map<String, dynamic> receipt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Transfer Successful!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'R ${amount.toStringAsFixed(2)} sent successfully',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'Transaction ID: ${receipt['transactionId']}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Date: ${DateTime.parse(receipt['date']).toLocal().toString().split('.')[0]}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: Share receipt
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Share Receipt'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFF2196F3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
