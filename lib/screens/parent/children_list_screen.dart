// Children list screen showing all children with profile cards
import 'package:flutter/material.dart';
import '../../models/child_model.dart';
import '../../services/child_service.dart';
import '../../services/auth_service.dart';
import 'child_detail_screen.dart';
import 'add_child_dialog.dart';

class ChildrenListScreen extends StatefulWidget {
  const ChildrenListScreen({super.key});

  @override
  State<ChildrenListScreen> createState() => _ChildrenListScreenState();
}

class _ChildrenListScreenState extends State<ChildrenListScreen> {
  final ChildService _childService = ChildService();
  final AuthService _authService = AuthService();

  List<ChildModel> _children = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final children = await _childService.getChildren(user.uid);
      if (mounted) {
        setState(() {
          _children = children;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addChild() async {
    final result = await showDialog<ChildModel>(
      context: context,
      builder: (context) => const AddChildDialog(),
    );

    if (result != null) {
      _loadChildren();
    }
  }

  Future<void> _deleteChild(ChildModel child) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Child'),
        content: Text('Are you sure you want to delete ${child.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _childService.deleteChild(child.id);
        _loadChildren();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${child.name} deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete child: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Children'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _addChild,
            icon: const Icon(Icons.add),
            tooltip: 'Add Child',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadChildren,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _children.isEmpty
                  ? _buildEmptyState()
                  : _buildChildrenGrid(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.family_restroom,
              size: 60,
              color: Colors.blue.shade300,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No children added yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first child to start managing their finances',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _addChild,
            icon: const Icon(Icons.add),
            label: const Text('Add Child'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildrenGrid() {
    return RefreshIndicator(
      onRefresh: _loadChildren,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: _children.length,
        itemBuilder: (context, index) {
          final child = _children[index];
          return _buildChildCard(child);
        },
      ),
    );
  }

  Widget _buildChildCard(ChildModel child) {
    return GestureDetector(
      onTap: () => _navigateToChildDetail(child),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Profile Picture
            Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                color: child.isFrozen ? Colors.grey.shade200 : Colors.blue.shade50,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: child.profilePhoto != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Image.network(
                        child.profilePhoto!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildProfilePlaceholder(child),
                      ),
                    )
                  : _buildProfilePlaceholder(child),
            ),

            // Child Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            child.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (child.isFrozen)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Frozen',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${child.age} years old',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'R ${child.balance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: child.isFrozen ? Colors.grey : Colors.green.shade600,
                      ),
                    ),
                    if (child.savingsGoal != null) ...[
                      const SizedBox(height: 4),
                      _buildSavingsProgress(child),
                    ],
                  ],
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _navigateToChildDetail(child),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _deleteChild(child),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    color: Colors.red.shade400,
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePlaceholder(ChildModel child) {
    return Center(
      child: Text(
        child.initials,
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: child.isFrozen ? Colors.grey.shade500 : Colors.blue.shade600,
        ),
      ),
    );
  }

  Widget _buildSavingsProgress(ChildModel child) {
    final progress = child.savingsCurrent! / child.savingsGoal!;
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Savings',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              '${(clampedProgress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        LinearProgressIndicator(
          value: clampedProgress,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(
            clampedProgress >= 1.0 ? Colors.green : Colors.orange,
          ),
        ),
      ],
    );
  }

  void _navigateToChildDetail(ChildModel child) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChildDetailScreen(child: child),
      ),
    ).then((_) => _loadChildren()); // Refresh when returning
  }
}