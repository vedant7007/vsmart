import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../localization/app_localizations.dart';
import '../../main.dart';
import './widgets/language_picker_widget.dart';
import './widgets/login_form_widget.dart';
import './widgets/role_selection_widget.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({Key? key}) : super(key: key);

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  String _selectedRole = 'ngo';
  String _selectedLanguage = 'en';
  bool _isLoading = false;
  String? _errorMessage;

  // Mock credentials for validation
  final Map<String, Map<String, String>> _validCredentials = {
    'ngo': {'email': 'ngo@vsmart.com', 'password': 'ngo123'},
    'admin': {'email': 'admin@vsmart.com', 'password': 'admin123'},
    'company': {'email': 'company@vsmart.com', 'password': 'company123'},
  };

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('app_locale') ?? 'en';
    setState(() {
      _selectedLanguage = savedLanguage;
    });
  }

  void _onRoleChanged(String role) {
    setState(() {
      _selectedRole = role;
      _errorMessage = null;
    });
  }

  Future<void> _onLanguageChanged(String language) async {
    setState(() {
      _selectedLanguage = language;
    });

    // Update app locale through main app state and save to storage
    final newLocale = Locale(language);
    MyApp.setLocale(context, newLocale);

    // Also save to SharedPreferences for persistence
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_locale', language);
  }

  Future<void> _onLogin(String email, String password) async {
    final localizations = AppLocalizations.of(context);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Validate credentials
    final validCredentials = _validCredentials[_selectedRole];
    if (validCredentials != null &&
        validCredentials['email'] == email &&
        validCredentials['password'] == password) {
      // Save user role to SharedPreferences for notifications filtering
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', _selectedRole);

      // Success - provide haptic feedback
      HapticFeedback.lightImpact();

      // Navigate to appropriate home screen based on role
      String route;
      switch (_selectedRole) {
        case 'ngo':
          route = AppRoutes.ngoHome;
          break;
        case 'admin':
          route = AppRoutes.adminDashboard;
          break;
        case 'company':
          route = AppRoutes.carbonCreditMarketplace;
          break;
        default:
          route = AppRoutes.ngoHome;
      }

      Navigator.pushReplacementNamed(context, route);
    } else {
      // Invalid credentials
      setState(() {
        _errorMessage =
            localizations?.invalidCredentials ??
            'Invalid credentials. Please check your email and password.';
      });
      HapticFeedback.heavyImpact();
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _onDemoLogin(String role) {
    final credentials = _validCredentials[role];
    if (credentials != null) {
      _onLogin(credentials['email']!, credentials['password']!);
    }
  }

  void _onForgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Forgot password feature will be available soon'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Language Picker
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    LanguagePickerWidget(
                      selectedLanguage: _selectedLanguage,
                      onLanguageChanged: _onLanguageChanged,
                    ),
                  ],
                ),
                SizedBox(height: 4.h),

                // App Logo
                Container(
                  width: 25.w,
                  height: 25.w,
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.primary.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'eco',
                          color: AppTheme.lightTheme.colorScheme.primary,
                          size: 10.w,
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          localizations?.appName ?? 'Vsmart',
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                                color: AppTheme.lightTheme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 4.h),

                // Welcome Text
                Text(
                  localizations?.welcomeBack ?? 'Welcome Back',
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  localizations?.signInToContinue ??
                      'Sign in to continue to your environmental projects',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4.h),

                // Role Selection
                RoleSelectionWidget(
                  selectedRole: _selectedRole,
                  onRoleChanged: _onRoleChanged,
                ),
                SizedBox(height: 4.h),

                // Error Message
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.error.withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.lightTheme.colorScheme.error.withValues(
                          alpha: 0.3,
                        ),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'error',
                          color: AppTheme.lightTheme.colorScheme.error,
                          size: 5.w,
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                                  color: AppTheme.lightTheme.colorScheme.error,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 3.h),
                ],

                // Login Form
                LoginFormWidget(
                  selectedRole: _selectedRole,
                  onLogin: _onLogin,
                  onDemoLogin: _onDemoLogin,
                  onForgotPassword: _onForgotPassword,
                  isLoading: _isLoading,
                ),
                SizedBox(height: 4.h),

                // Footer
                Text(
                  'By signing in, you agree to our Terms of Service and Privacy Policy',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
