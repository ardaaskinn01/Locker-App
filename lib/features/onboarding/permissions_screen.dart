import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/translations.dart';
import '../../core/services/app_lock_service.dart';
import 'onboarding_provider.dart';

class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> with WidgetsBindingObserver {
  bool _usageGranted = false;
  bool _accessibilityGranted = false;
  bool _notificationsGranted = false;
  bool _screenTimeGranted = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAllPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAllPermissions();
    }
  }

  Future<void> _checkAllPermissions() async {
    setState(() => _checking = true);
    try {
      final notificationStatus = await Permission.notification.status;
      if (Platform.isAndroid) {
        final usage = await AppLockService.checkUsageAccess();
        final accessibility = await AppLockService.checkAccessibilityAccess();
        if (mounted) {
          setState(() {
            _usageGranted = usage;
            _accessibilityGranted = accessibility;
            _notificationsGranted = notificationStatus.isGranted;
            _checking = false;
          });
        }
      } else if (Platform.isIOS) {
        final screenTime = await AppLockService.checkUsageAccess();
        if (mounted) {
          setState(() {
            _screenTimeGranted = screenTime;
            _notificationsGranted = notificationStatus.isGranted;
            _checking = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _checking = false);
      }
    }
  }

  Future<void> _handleContinue(Translations translations) async {
    if (Platform.isAndroid && (!_usageGranted || !_accessibilityGranted)) {
      final bool? proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E2841),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  translations.get('permissionAlertTitle'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            translations.get('permissionAlertMessage'),
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                translations.get('permissionAlertNo'),
                style: const TextStyle(color: Color(0xFF39D2C0), fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white10,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(translations.get('permissionAlertYes')),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    } else if (Platform.isIOS && !_screenTimeGranted) {
      final bool? proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E2841),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  translations.get('permissionAlertTitle'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            translations.get('permissionAlertMessageIOS'),
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                translations.get('permissionAlertNo'),
                style: const TextStyle(color: Color(0xFF39D2C0), fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white10,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(translations.get('permissionAlertYes')),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    if (mounted) {
      context.push('/onboarding/limit');
    }
  }

  @override
  Widget build(BuildContext context) {
    final translations = ref.watch(translationProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        translations.get('permissionsScreenTitle'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        translations.get('permissionsScreenSubtitle'),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Permissions checklist
                      if (Platform.isAndroid) ...[
                        _PermissionCard(
                          icon: '📊',
                          title: translations.get('usageAccess'),
                          description: translations.get('usageAccessDesc'),
                          isGranted: _usageGranted,
                          onAction: () async {
                            await appLockServiceProvider.requestUsageStatsPermission();
                          },
                          translations: translations,
                        ),
                        const SizedBox(height: 16),

                        _PermissionCard(
                          icon: '♿',
                          title: translations.get('accessibilityService'),
                          description: translations.get('accessibilityServiceDesc'),
                          isGranted: _accessibilityGranted,
                          onAction: () async {
                            await appLockServiceProvider.requestAccessibilityPermission();
                          },
                          translations: translations,
                        ),
                        const SizedBox(height: 16),
                      ] else if (Platform.isIOS) ...[
                        _PermissionCard(
                          icon: '📱',
                          title: translations.get('screenTimePermission'),
                          description: translations.get('screenTimePermissionDesc'),
                          isGranted: _screenTimeGranted,
                          onAction: () async {
                            final granted = await appLockServiceProvider.requestScreenTimePermission();
                            if (mounted) {
                              setState(() => _screenTimeGranted = granted);
                              if (!granted) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: const Color(0xFF1E2841),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    title: Text(
                                      translations.get('screenTimeDeniedTitle'),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                    content: Text(
                                      translations.get('screenTimeDeniedMessage'),
                                      style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: Text(
                                          translations.get('close'),
                                          style: const TextStyle(color: Color(0xFF39D2C0), fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            }
                          },
                          translations: translations,
                        ),
                        const SizedBox(height: 16),
                      ],

                      _PermissionCard(
                        icon: '🔔',
                        title: translations.get('notificationPermission'),
                        description: translations.get('notificationPermissionDesc'),
                        isGranted: _notificationsGranted,
                        onAction: () async {
                          final granted = await appLockServiceProvider.requestNotificationPermission();
                          setState(() => _notificationsGranted = granted);
                        },
                        translations: translations,
                      ),
                      const SizedBox(height: 24),

                      // Xiaomi / POCO specific instructions
                      if (Platform.isAndroid) ...[
                        _XiaomiGuidanceCard(
                          translations: translations,
                          onOpenSettings: () => appLockServiceProvider.openAppSettings(),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom Button & Steps
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _checking ? null : () => _handleContinue(translations),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryBlue,
                          disabledBackgroundColor: Colors.white.withOpacity(0.3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _checking
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primaryBlue),
                              )
                            : Text(
                                translations.get('continueText'),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _StepIndicator(currentStep: 5),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final String icon;
  final String title;
  final String description;
  final bool isGranted;
  final VoidCallback onAction;
  final Translations translations;

  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isGranted,
    required this.onAction,
    required this.translations,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isGranted ? const Color(0xFF39D2C0).withOpacity(0.3) : Colors.white.withOpacity(0.05),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Emoji Icon Container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isGranted ? const Color(0xFF39D2C0).withOpacity(0.1) : Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Text(icon, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Status action button/checkmark
          GestureDetector(
            onTap: isGranted ? null : onAction,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isGranted ? 12 : 14,
                vertical: isGranted ? 8 : 10,
              ),
              decoration: BoxDecoration(
                color: isGranted ? const Color(0xFF39D2C0).withOpacity(0.15) : Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: isGranted
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, color: Color(0xFF39D2C0), size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Aktif',
                          style: TextStyle(
                            color: Color(0xFF39D2C0),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      translations.get('goToSettings'),
                      style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _XiaomiGuidanceCard extends StatelessWidget {
  final Translations translations;
  final VoidCallback onOpenSettings;

  const _XiaomiGuidanceCard({
    required this.translations,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withOpacity(0.08),
            Colors.orange.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.amber.withOpacity(0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.12),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
            child: Row(
              children: [
                const Text('⚙️', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    translations.get('xiaomiTitle'),
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step 1: Pop-up windows
                Text(
                  translations.get('xiaomiPopupTitle'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                _buildStepItem('1', translations.get('xiaomiPopupStep1')),
                _buildStepItem('2', translations.get('xiaomiPopupStep2')),
                _buildStepItem('3', translations.get('xiaomiPopupStep3')),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(color: Colors.white10),
                ),

                // Step 2: Battery optimizations
                Text(
                  translations.get('xiaomiBatteryTitle'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                _buildStepItem('1', translations.get('xiaomiBatteryStep1')),
                _buildStepItem('2', translations.get('xiaomiBatteryStep2')),

                const SizedBox(height: 20),

                // Open App Settings button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: onOpenSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.withOpacity(0.15),
                      foregroundColor: Colors.amber,
                      elevation: 0,
                      side: BorderSide(color: Colors.amber.withOpacity(0.3), width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.settings_outlined, size: 18),
                    label: Text(
                      translations.get('goToSettings'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(8, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: index == currentStep ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: index == currentStep ? Colors.white : Colors.white.withOpacity(0.2),
          ),
        );
      }),
    );
  }
}
