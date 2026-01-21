import 'package:flutter/material.dart';
import '../../models/business_profile_model.dart';
import '../../services/business_profile_service.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final BusinessProfileService _profileService = BusinessProfileService();
  BusinessProfileModel? _profile;
  bool _isLoading = true;
  bool _isEditing = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Get current vendor ID from auth
      _profile = await _profileService
          .getBusinessProfileByVendorId('current_vendor_id');
      if (_profile != null) {
        _populateControllers();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _populateControllers() {
    if (_profile != null) {
      _nameController.text = _profile!.businessName;
      _descriptionController.text = _profile!.description;
      _addressController.text = _profile!.address;
      _phoneController.text = _profile!.phone;
      _emailController.text = _profile!.email;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final profileData = BusinessProfileModel(
        id: _profile?.id ?? '',
        vendorId: 'current_vendor_id', // TODO: Get from auth
        businessName: _nameController.text,
        description: _descriptionController.text,
        address: _addressController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        logoUrl: _profile?.logoUrl ?? '',
        categories: _profile?.categories ?? [],
        businessHours: _profile?.businessHours ?? {},
        isVerified: _profile?.isVerified ?? false,
        createdAt: _profile?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_profile == null) {
        final profileId =
            await _profileService.createBusinessProfile(profileData);
        _profile = profileData.copyWith(id: profileId);
      } else {
        await _profileService.updateBusinessProfile(
            _profile!.id, profileData.toMap());
        _profile = profileData;
      }

      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Profile'),
        actions: [
          if (_profile != null)
            IconButton(
              icon: Icon(_isEditing ? Icons.save : Icons.edit),
              onPressed: _isEditing
                  ? _saveProfile
                  : () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null && !_isEditing
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Header
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                  child: _profile?.logoUrl.isNotEmpty ?? false
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(40),
                                          child: Image.network(
                                            _profile!.logoUrl,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.business,
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _profile?.businessName ??
                                            'Business Name',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.verified,
                                            size: 16,
                                            color:
                                                (_profile?.isVerified ?? false)
                                                    ? Colors.green
                                                    : Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            (_profile?.isVerified ?? false)
                                                ? 'Verified'
                                                : 'Not Verified',
                                            style: TextStyle(
                                              color: (_profile?.isVerified ??
                                                      false)
                                                  ? Colors.green
                                                  : Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Basic Information
                        const Text(
                          'Basic Information',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _nameController,
                          label: 'Business Name',
                          icon: Icons.business,
                          enabled: _isEditing,
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required' : null,
                        ),

                        _buildTextField(
                          controller: _descriptionController,
                          label: 'Description',
                          icon: Icons.description,
                          maxLines: 3,
                          enabled: _isEditing,
                        ),

                        _buildTextField(
                          controller: _addressController,
                          label: 'Address',
                          icon: Icons.location_on,
                          enabled: _isEditing,
                        ),

                        _buildTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          icon: Icons.phone,
                          enabled: _isEditing,
                          keyboardType: TextInputType.phone,
                        ),

                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email,
                          enabled: _isEditing,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Required';
                            final emailRegex =
                                RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegex.hasMatch(value!))
                              return 'Invalid email';
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Business Hours
                        const Text(
                          'Business Hours',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),

                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Text(
                                  'Business hours will be configurable in the next update',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Current: ${_profile?.businessHours.isNotEmpty ?? false ? "Set" : "Not set"}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Categories
                        const Text(
                          'Categories',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),

                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Text(
                                  'Business categories will be configurable in the next update',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: _profile?.categories
                                          .map((category) => Chip(
                                                label: Text(category),
                                              ))
                                          .toList() ??
                                      [],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Save Button
                        if (_isEditing)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveProfile,
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('Save Profile'),
                            ),
                          ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.business,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No business profile yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => setState(() => _isEditing = true),
            icon: const Icon(Icons.add),
            label: const Text('Create Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          enabled: enabled,
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        enabled: enabled,
      ),
    );
  }
}
