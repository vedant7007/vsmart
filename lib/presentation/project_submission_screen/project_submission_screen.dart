import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/beneficiary_count_widget.dart';
import './widgets/date_picker_widget.dart';
import './widgets/location_section_widget.dart';
import './widgets/photo_gallery_widget.dart';
import './widgets/project_description_field_widget.dart';
import './widgets/project_form_header_widget.dart';
import './widgets/project_title_field_widget.dart';
import './widgets/project_type_picker_widget.dart';
import './widgets/submit_button_widget.dart';

class ProjectSubmissionScreen extends StatefulWidget {
  @override
  State<ProjectSubmissionScreen> createState() =>
      _ProjectSubmissionScreenState();
}

class _ProjectSubmissionScreenState extends State<ProjectSubmissionScreen> {
  // Form Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _beneficiaryController = TextEditingController();

  // Form State
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Timer? _draftSaveTimer;

  // Project Data
  List<String> _projectPhotos = [];
  String? _selectedProjectType;
  DateTime? _startDate;
  DateTime? _completionDate;

  // UI State
  bool _isDraftSaving = false;
  bool _isSubmitting = false;
  bool _isLoadingLocation = false;
  bool _isGpsEnabled = false;
  bool _isOffline = false;
  bool _isPhotoLoading = false;

  // Validation Errors
  String? _titleError;
  String? _descriptionError;
  String? _locationError;
  String? _projectTypeError;
  String? _startDateError;
  String? _beneficiaryError;

  // Carbon Restoration Project Types - Updated to focus only on carbon restoration
  final List<String> _projectTypes = [
    'Tree Plantation',
    'Mangrove Restoration',
    'Forest Conservation',
    'Agroforestry',
    'Wetland Restoration',
    'Grassland Restoration',
    'Bamboo Cultivation',
    'Carbon Sequestration',
    'Soil Carbon Enhancement',
    'Community Reforestation',
  ];

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    _startDraftAutoSave();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _addressController.dispose();
    _beneficiaryController.dispose();
    _draftSaveTimer?.cancel();
    super.dispose();
  }

  void _initializeScreen() {
    _checkLocationPermission();
    _checkNetworkStatus();
  }

  void _startDraftAutoSave() {
    _draftSaveTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_hasFormData()) {
        _saveDraft();
      }
    });
  }

  bool _hasFormData() {
    return _titleController.text.isNotEmpty ||
        _descriptionController.text.isNotEmpty ||
        _projectPhotos.isNotEmpty ||
        _selectedProjectType != null;
  }

  Future<void> _checkLocationPermission() async {
    final status = await Permission.location.status;
    setState(() {
      _isGpsEnabled = status.isGranted;
    });
  }

  Future<void> _checkNetworkStatus() async {
    // Simulate network check
    setState(() {
      _isOffline = false; // In real app, use connectivity_plus package
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      final permission = await Permission.location.request();
      if (!permission.isGranted) {
        setState(() {
          _locationError = 'Location permission denied';
          _isLoadingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitudeController.text = position.latitude.toStringAsFixed(6);
        _longitudeController.text = position.longitude.toStringAsFixed(6);
        _isGpsEnabled = true;
        _isLoadingLocation = false;
      });

      // Get address from coordinates (mock implementation)
      _getAddressFromCoordinates(position.latitude, position.longitude);
    } catch (e) {
      setState(() {
        _locationError = 'Failed to get location: ${e.toString()}';
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _getAddressFromCoordinates(double lat, double lng) async {
    // Mock address lookup
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _addressController.text = 'Sample Address, City, State, India';
    });
  }

  void _toggleManualLocationEntry() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manual Location Entry'),
        content: Text(
          'You can manually enter coordinates or select location on map.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _addPhoto() async {
    if (_projectPhotos.length >= 10) return;

    setState(() {
      _isPhotoLoading = true;
    });

    try {
      final ImagePicker picker = ImagePicker();

      // Show options for camera or gallery
      final source = await _showImageSourceDialog();
      if (source == null) {
        setState(() {
          _isPhotoLoading = false;
        });
        return;
      }

      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _projectPhotos.add(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to add photo: ${e.toString()}');
    } finally {
      setState(() {
        _isPhotoLoading = false;
      });
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CustomIconWidget(
                iconName: 'camera_alt',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 6.w,
              ),
              title: Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'photo_library',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 6.w,
              ),
              title: Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  void _removePhoto(int index) {
    setState(() {
      _projectPhotos.removeAt(index);
    });
  }

  void _reorderPhotos(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final String item = _projectPhotos.removeAt(oldIndex);
      _projectPhotos.insert(newIndex, item);
    });
  }

  void _saveDraft() async {
    if (_isDraftSaving) return;

    setState(() {
      _isDraftSaving = true;
    });

    // Simulate saving draft
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _isDraftSaving = false;
    });

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CustomIconWidget(
              iconName: 'check_circle',
              color: AppTheme.lightTheme.colorScheme.onPrimary,
              size: 5.w,
            ),
            SizedBox(width: 2.w),
            Text('Draft saved successfully'),
          ],
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  bool _validateForm() {
    bool isValid = true;

    // Title validation
    if (_titleController.text.trim().isEmpty) {
      setState(() {
        _titleError = 'Project title is required';
      });
      isValid = false;
    } else if (_titleController.text.trim().length < 5) {
      setState(() {
        _titleError = 'Title must be at least 5 characters';
      });
      isValid = false;
    } else {
      setState(() {
        _titleError = null;
      });
    }

    // Description validation
    if (_descriptionController.text.trim().isEmpty) {
      setState(() {
        _descriptionError = 'Project description is required';
      });
      isValid = false;
    } else if (_descriptionController.text.trim().length < 20) {
      setState(() {
        _descriptionError = 'Description must be at least 20 characters';
      });
      isValid = false;
    } else {
      setState(() {
        _descriptionError = null;
      });
    }

    // Location validation
    if (_latitudeController.text.isEmpty || _longitudeController.text.isEmpty) {
      setState(() {
        _locationError = 'Location coordinates are required';
      });
      isValid = false;
    } else {
      setState(() {
        _locationError = null;
      });
    }

    // Project type validation
    if (_selectedProjectType == null) {
      setState(() {
        _projectTypeError = 'Please select a project type';
      });
      isValid = false;
    } else {
      setState(() {
        _projectTypeError = null;
      });
    }

    // Start date validation
    if (_startDate == null) {
      setState(() {
        _startDateError = 'Project start date is required';
      });
      isValid = false;
    } else {
      setState(() {
        _startDateError = null;
      });
    }

    // Beneficiary count validation
    if (_beneficiaryController.text.isEmpty) {
      setState(() {
        _beneficiaryError = 'Beneficiary count is required';
      });
      isValid = false;
    } else if (int.tryParse(_beneficiaryController.text) == null ||
        int.parse(_beneficiaryController.text) <= 0) {
      setState(() {
        _beneficiaryError = 'Please enter a valid number greater than 0';
      });
      isValid = false;
    } else {
      setState(() {
        _beneficiaryError = null;
      });
    }

    // Photos validation
    if (_projectPhotos.isEmpty) {
      _showErrorSnackBar('Please add at least one project photo');
      isValid = false;
    }

    return isValid;
  }

  double _calculateProgress() {
    int completedFields = 0;
    int totalFields = 7;

    if (_titleController.text.trim().isNotEmpty) completedFields++;
    if (_descriptionController.text.trim().isNotEmpty) completedFields++;
    if (_latitudeController.text.isNotEmpty &&
        _longitudeController.text.isNotEmpty) completedFields++;
    if (_projectPhotos.isNotEmpty) completedFields++;
    if (_selectedProjectType != null) completedFields++;
    if (_startDate != null) completedFields++;
    if (_beneficiaryController.text.isNotEmpty) completedFields++;

    return completedFields / totalFields;
  }

  Future<void> _submitProject() async {
    if (!_validateForm()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Create project data object
      final projectData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'latitude': double.parse(_latitudeController.text),
        'longitude': double.parse(_longitudeController.text),
        'address': _addressController.text.trim(),
        'projectType': _selectedProjectType,
        'startDate': _startDate!.toIso8601String(),
        'completionDate': _completionDate?.toIso8601String(),
        'beneficiaryCount': int.parse(_beneficiaryController.text),
        'photos': _projectPhotos,
        'status': 'pending_review',
        'submittedAt': DateTime.now().toIso8601String(),
        'submittedBy': 'current_user_id', // In real app, get from auth service
        'isOfflineSubmission': _isOffline,
      };

      // Save project data to local storage
      await _saveProjectData(projectData);

      // If online, also attempt to sync with server
      if (!_isOffline) {
        await _syncProjectWithServer(projectData);
      }

      // Show success dialog with actual project ID
      _showSuccessDialog(projectData['id'] as String);
    } catch (e) {
      _showErrorSnackBar('Failed to submit project: ${e.toString()}');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _saveProjectData(Map<String, dynamic> projectData) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing projects
      final String? existingProjectsJson = prefs.getString(
        'submitted_projects',
      );
      List<Map<String, dynamic>> existingProjects = [];

      if (existingProjectsJson != null) {
        final List<dynamic> decoded = json.decode(existingProjectsJson);
        existingProjects = decoded.cast<Map<String, dynamic>>();
      }

      // Add new project
      existingProjects.add(projectData);

      // Save back to storage
      await prefs.setString(
        'submitted_projects',
        json.encode(existingProjects),
      );

      // Also save individual project for easy retrieval
      await prefs.setString(
        'project_${projectData['id']}',
        json.encode(projectData),
      );

      // Update project count
      await prefs.setInt('total_submitted_projects', existingProjects.length);

      print('Project saved successfully with ID: ${projectData['id']}');
    } catch (e) {
      throw Exception('Failed to save project data locally: $e');
    }
  }

  Future<void> _syncProjectWithServer(Map<String, dynamic> projectData) async {
    try {
      // Simulate API call to server
      await Future.delayed(Duration(seconds: 2));

      // In real implementation, this would be:
      // final response = await http.post(
      //   Uri.parse('$API_BASE_URL/projects'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: json.encode(projectData),
      // );

      // Mark as synced in local storage
      final prefs = await SharedPreferences.getInstance();
      projectData['syncedWithServer'] = true;
      projectData['serverSyncAt'] = DateTime.now().toIso8601String();
      await prefs.setString(
        'project_${projectData['id']}',
        json.encode(projectData),
      );

      print('Project synced with server successfully');
    } catch (e) {
      // If sync fails, mark for retry
      final prefs = await SharedPreferences.getInstance();
      projectData['syncedWithServer'] = false;
      projectData['pendingSync'] = true;
      await prefs.setString(
        'project_${projectData['id']}',
        json.encode(projectData),
      );

      throw Exception('Failed to sync with server: $e');
    }
  }

  void _showSuccessDialog(String projectId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary.withValues(
                  alpha: 0.1,
                ),
                shape: BoxShape.circle,
              ),
              child: CustomIconWidget(
                iconName: 'check_circle',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 15.w,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Project Submitted Successfully!',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Project ID: $projectId',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              _isOffline
                  ? 'Your project has been saved locally and will be uploaded when internet connection is restored.'
                  : 'Your carbon restoration project has been successfully submitted for review. You will be notified once it\'s verified and approved.',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      _resetForm(); // Reset form for new submission
                    },
                    child: Text('Submit Another'),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      // Navigate to project list to see submitted projects
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.projectList,
                        (route) =>
                            route.settings.name == AppRoutes.ngoHome ||
                            route.settings.name == AppRoutes.adminDashboard,
                      );
                    },
                    child: Text('View Projects'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            // Additional navigation option to go to home
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                // Navigate to appropriate home screen based on user role
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes
                      .ngoHome, // Default to NGO home, could be dynamic based on user role
                  (route) => false, // Clear entire navigation stack
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomIconWidget(
                    iconName: 'home',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 5.w,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Go to Home',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
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

  void _resetForm() {
    // Clear all controllers
    _titleController.clear();
    _descriptionController.clear();
    _latitudeController.clear();
    _longitudeController.clear();
    _addressController.clear();
    _beneficiaryController.clear();

    // Reset state variables
    setState(() {
      _projectPhotos.clear();
      _selectedProjectType = null;
      _startDate = null;
      _completionDate = null;

      // Clear validation errors
      _titleError = null;
      _descriptionError = null;
      _locationError = null;
      _projectTypeError = null;
      _startDateError = null;
      _beneficiaryError = null;
    });

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CustomIconWidget(
              iconName: 'refresh',
              color: AppTheme.lightTheme.colorScheme.onPrimary,
              size: 5.w,
            ),
            SizedBox(width: 2.w),
            Text('Form reset for new project submission'),
          ],
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Add method to retrieve submitted projects (for testing)
  Future<List<Map<String, dynamic>>> getSubmittedProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final String? projectsJson = prefs.getString('submitted_projects');

    if (projectsJson != null) {
      final List<dynamic> decoded = json.decode(projectsJson);
      return decoded.cast<Map<String, dynamic>>();
    }

    return [];
  }

  // Add method to get project by ID
  Future<Map<String, dynamic>?> getProjectById(String projectId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? projectJson = prefs.getString('project_$projectId');

    if (projectJson != null) {
      return json.decode(projectJson);
    }

    return null;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CustomIconWidget(
              iconName: 'error',
              color: AppTheme.lightTheme.colorScheme.onError,
              size: 5.w,
            ),
            SizedBox(width: 2.w),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.error,
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header with progress
          ProjectFormHeaderWidget(
            progress: _calculateProgress(),
            onBackPressed: () => Navigator.pop(context),
            onSaveDraft: _saveDraft,
            isDraftSaving: _isDraftSaving,
          ),

          // Scrollable Form
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Project Title
                    ProjectTitleFieldWidget(
                      controller: _titleController,
                      onChanged: (value) {
                        setState(() {
                          _titleError = null;
                        });
                      },
                      errorText: _titleError,
                    ),

                    SizedBox(height: 3.h),

                    // Project Description
                    ProjectDescriptionFieldWidget(
                      controller: _descriptionController,
                      onChanged: (value) {
                        setState(() {
                          _descriptionError = null;
                        });
                      },
                      errorText: _descriptionError,
                    ),

                    SizedBox(height: 3.h),

                    // Location Section
                    LocationSectionWidget(
                      latitudeController: _latitudeController,
                      longitudeController: _longitudeController,
                      addressController: _addressController,
                      isGpsEnabled: _isGpsEnabled,
                      isLoadingLocation: _isLoadingLocation,
                      onGetCurrentLocation: _getCurrentLocation,
                      onToggleManualEntry: _toggleManualLocationEntry,
                      onLatitudeChanged: (value) {
                        setState(() {
                          _locationError = null;
                        });
                      },
                      onLongitudeChanged: (value) {
                        setState(() {
                          _locationError = null;
                        });
                      },
                      onAddressChanged: (value) {},
                      locationError: _locationError,
                    ),

                    SizedBox(height: 3.h),

                    // Photo Gallery
                    PhotoGalleryWidget(
                      photos: _projectPhotos,
                      onAddPhoto: _addPhoto,
                      onRemovePhoto: _removePhoto,
                      onReorderPhotos: _reorderPhotos,
                      isLoading: _isPhotoLoading,
                    ),

                    SizedBox(height: 3.h),

                    // Project Type Picker
                    ProjectTypePickerWidget(
                      selectedType: _selectedProjectType,
                      onTypeSelected: (type) {
                        setState(() {
                          _selectedProjectType = type;
                          _projectTypeError = null;
                        });
                      },
                      projectTypes: _projectTypes,
                      errorText: _projectTypeError,
                    ),

                    SizedBox(height: 3.h),

                    // Date Pickers
                    DatePickerWidget(
                      selectedDate: _startDate,
                      onDateSelected: (date) {
                        setState(() {
                          _startDate = date;
                          _startDateError = null;
                        });
                      },
                      label: 'Project Start Date',
                      isRequired: true,
                      errorText: _startDateError,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    ),

                    SizedBox(height: 3.h),

                    DatePickerWidget(
                      selectedDate: _completionDate,
                      onDateSelected: (date) {
                        setState(() {
                          _completionDate = date;
                        });
                      },
                      label: 'Expected Completion Date',
                      isRequired: false,
                      firstDate: _startDate ?? DateTime.now(),
                      lastDate: DateTime(2030),
                    ),

                    SizedBox(height: 3.h),

                    // Beneficiary Count
                    BeneficiaryCountWidget(
                      controller: _beneficiaryController,
                      onChanged: (value) {
                        setState(() {
                          _beneficiaryError = null;
                        });
                      },
                      errorText: _beneficiaryError,
                    ),

                    SizedBox(height: 10.h), // Space for sticky button
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // Sticky Submit Button
      bottomNavigationBar: SubmitButtonWidget(
        isEnabled: _calculateProgress() == 1.0,
        isSubmitting: _isSubmitting,
        isOffline: _isOffline,
        onSubmit: _submitProject,
      ),
    );
  }
}
