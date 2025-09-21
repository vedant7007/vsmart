import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/bulk_action_toolbar_widget.dart';
import './widgets/empty_state_widget.dart';
import './widgets/filter_bottom_sheet_widget.dart';
import './widgets/offline_indicator_widget.dart';
import './widgets/project_card_widget.dart';
import './widgets/search_bar_widget.dart';
import './widgets/sort_options_widget.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  // State variables
  List<Map<String, dynamic>> _allProjects = [];
  List<Map<String, dynamic>> _filteredProjects = [];
  Set<int> _selectedProjects = {};
  bool _isMultiSelectMode = false;
  bool _isLoading = false;
  bool _isOffline = false;
  String _searchQuery = '';
  String _currentSort = 'recent';
  Map<String, dynamic> _currentFilters = {
    'status': 'All',
    'dateRange': 'All Time',
    'location': 'All Locations',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProjects();
    _simulateConnectivity();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Mock data
  final List<Map<String, dynamic>> _mockProjects = [];

  void _loadProjects() {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _allProjects = List.from(_mockProjects);
        _filteredProjects = List.from(_allProjects);
        _isLoading = false;
      });
      _applyFiltersAndSort();
    });
  }

  void _simulateConnectivity() {
    // Simulate offline/online status changes
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isOffline = true;
        });
      }
    });
  }

  void _applyFiltersAndSort() {
    List<Map<String, dynamic>> filtered = List.from(_allProjects);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((project) {
        final title = (project['title'] as String? ?? '').toLowerCase();
        final location = (project['location'] as String? ?? '').toLowerCase();
        final description =
            (project['description'] as String? ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();

        return title.contains(query) ||
            location.contains(query) ||
            description.contains(query);
      }).toList();
    }

    // Apply status filter
    if (_currentFilters['status'] != 'All') {
      filtered = filtered
          .where((project) => project['status'] == _currentFilters['status'])
          .toList();
    }

    // Apply location filter
    if (_currentFilters['location'] != 'All Locations') {
      filtered = filtered
          .where((project) => (project['location'] as String? ?? '')
              .contains(_currentFilters['location'] as String))
          .toList();
    }

    // Apply sorting
    switch (_currentSort) {
      case 'alphabetical':
        filtered.sort((a, b) => (a['title'] as String? ?? '')
            .compareTo(b['title'] as String? ?? ''));
        break;
      case 'status':
        filtered.sort((a, b) => (a['status'] as String? ?? '')
            .compareTo(b['status'] as String? ?? ''));
        break;
      case 'location':
        filtered.sort((a, b) => (a['location'] as String? ?? '')
            .compareTo(b['location'] as String? ?? ''));
        break;
      case 'recent':
      default:
        filtered.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));
        break;
    }

    setState(() {
      _filteredProjects = filtered;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFiltersAndSort();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheetWidget(
        currentFilters: _currentFilters,
        onFiltersApplied: (filters) {
          setState(() {
            _currentFilters = filters;
          });
          _applyFiltersAndSort();
        },
      ),
    );
  }

  void _onSortChanged(String sortType) {
    setState(() {
      _currentSort = sortType;
    });
    _applyFiltersAndSort();
  }

  void _toggleProjectSelection(int projectId) {
    setState(() {
      if (_selectedProjects.contains(projectId)) {
        _selectedProjects.remove(projectId);
      } else {
        _selectedProjects.add(projectId);
      }

      if (_selectedProjects.isEmpty) {
        _isMultiSelectMode = false;
      } else if (!_isMultiSelectMode) {
        _isMultiSelectMode = true;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedProjects.clear();
      _isMultiSelectMode = false;
    });
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate refresh
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
      _isOffline = false;
    });

    Fluttertoast.showToast(
      msg: "Projects refreshed successfully",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Project'),
        content: Text(
            'Are you sure you want to delete "${project['title']}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProject(project['id'] as int);
            },
            child: Text('Delete'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.lightTheme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  void _deleteProject(int projectId) {
    setState(() {
      _allProjects.removeWhere((project) => project['id'] == projectId);
    });
    _applyFiltersAndSort();

    Fluttertoast.showToast(
      msg: "Project deleted successfully",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _bulkDeleteProjects() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Selected Projects'),
        content: Text(
            'Are you sure you want to delete ${_selectedProjects.length} selected projects? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _allProjects.removeWhere(
                    (project) => _selectedProjects.contains(project['id']));
                _selectedProjects.clear();
                _isMultiSelectMode = false;
              });
              _applyFiltersAndSort();

              Fluttertoast.showToast(
                msg: "Selected projects deleted successfully",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
              );
            },
            child: Text('Delete'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.lightTheme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  void _bulkArchiveProjects() {
    Fluttertoast.showToast(
      msg: "${_selectedProjects.length} projects archived successfully",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
    _clearSelection();
  }

  void _bulkExportProjects() {
    Fluttertoast.showToast(
      msg: "${_selectedProjects.length} projects exported successfully",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
    _clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Projects'),
        actions: [
          SortOptionsWidget(
            currentSort: _currentSort,
            onSortChanged: _onSortChanged,
          ),
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, '/notification-center-screen'),
            icon: CustomIconWidget(
              iconName: 'notifications',
              size: 24,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Projects'),
            Tab(text: 'Drafts'),
            Tab(text: 'Archived'),
          ],
        ),
      ),
      body: Column(
        children: [
          OfflineIndicatorWidget(
            isOffline: _isOffline,
            lastSyncTime: _isOffline ? '2 hours ago' : null,
          ),
          SearchBarWidget(
            onSearchChanged: _onSearchChanged,
            onFilterTap: _showFilterBottomSheet,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProjectsList(),
                _buildEmptyTab('No drafts available'),
                _buildEmptyTab('No archived projects'),
              ],
            ),
          ),
          if (_isMultiSelectMode)
            BulkActionToolbarWidget(
              selectedCount: _selectedProjects.length,
              onDeleteSelected: _bulkDeleteProjects,
              onArchiveSelected: _bulkArchiveProjects,
              onExportSelected: _bulkExportProjects,
              onClearSelection: _clearSelection,
            ),
        ],
      ),
      floatingActionButton: _isMultiSelectMode
          ? null
          : FloatingActionButton.extended(
              onPressed: () =>
                  Navigator.pushNamed(context, '/project-submission-screen'),
              icon: CustomIconWidget(
                iconName: 'add',
                size: 24,
                color: AppTheme.lightTheme.colorScheme.onPrimary,
              ),
              label: Text('New Project'),
            ),
    );
  }

  Widget _buildProjectsList() {
    if (_isLoading) {
      return _buildSkeletonLoader();
    }

    if (_filteredProjects.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 70.h,
            child: EmptyStateWidget(
              onCreateProject: () =>
                  Navigator.pushNamed(context, '/project-submission-screen'),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _filteredProjects.length,
        itemBuilder: (context, index) {
          final project = _filteredProjects[index];
          final projectId = project['id'] as int;

          return ProjectCardWidget(
            project: project,
            isSelected: _selectedProjects.contains(projectId),
            isMultiSelectMode: _isMultiSelectMode,
            onTap: () => Navigator.pushNamed(context, '/project-detail-screen'),
            onSelectionChanged: (selected) =>
                _toggleProjectSelection(projectId),
            onEdit: () {
              Fluttertoast.showToast(
                msg: "Edit project: ${project['title']}",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
              );
            },
            onDuplicate: () {
              Fluttertoast.showToast(
                msg: "Project duplicated: ${project['title']}",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
              );
            },
            onShare: () {
              Fluttertoast.showToast(
                msg: "Sharing project: ${project['title']}",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
              );
            },
            onArchive: () {
              Fluttertoast.showToast(
                msg: "Project archived: ${project['title']}",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
              );
            },
            onDelete: () => _showDeleteConfirmation(project),
          );
        },
      ),
    );
  }

  Widget _buildEmptyTab(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'folder_open',
            size: 64,
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 2.h),
          Text(
            message,
            style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          child: Card(
            child: Container(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  Container(
                    width: 15.w,
                    height: 15.w,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 16,
                          width: 60.w,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Container(
                          height: 12,
                          width: 40.w,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Container(
                          height: 12,
                          width: 30.w,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 24,
                    width: 20.w,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
