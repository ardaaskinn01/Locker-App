import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/app_lock_service.dart';
import '../../core/services/firebase_service.dart';
import 'onboarding_provider.dart';

class SelectAppsScreen extends ConsumerStatefulWidget {
  const SelectAppsScreen({super.key});

  @override
  ConsumerState<SelectAppsScreen> createState() => _SelectAppsScreenState();
}

class _SelectAppsScreenState extends ConsumerState<SelectAppsScreen> {
  final List<Map<String, dynamic>> _apps = [
    {'name': 'Instagram', 'logo': 'assets/images/instagram.png'},
    {'name': 'TikTok', 'logo': 'assets/images/tiktok.png'},
    {'name': 'Twitter/X', 'logo': 'assets/images/twitter.png'},
    {'name': 'YouTube', 'logo': 'assets/images/youtube.png'},
    {'name': 'Snapchat', 'logo': 'assets/images/snapchat.png'},
    {'name': 'Facebook', 'logo': 'assets/images/facebook.png'},
    {'name': 'Pinterest', 'logo': 'assets/images/pinterest.png'},
  ];

  bool _logosPrecached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_logosPrecached) {
      _precacheLogos();
      _logosPrecached = true;
    }
  }

  void _precacheLogos() {
    for (final app in _apps) {
      precacheImage(AssetImage(app['logo'] as String), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final l10n = AppLocalizations.of(context)!;
    final isButtonEnabled = state.selectedApps.isNotEmpty;

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
                        l10n.selectAppsTitle,
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
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _apps.length,
                  itemBuilder: (context, index) {
                    final app = _apps[index];
                    final isSelected = state.selectedApps.contains(app['name']);
                    
                    return _AppCard(
                      name: app['name'],
                      logoUrl: app['logo'],
                      isSelected: isSelected,
                      onTap: () {
                        List<String> currentSelected = List.from(state.selectedApps);
                        if (isSelected) {
                          currentSelected.remove(app['name']);
                        } else {
                          currentSelected.add(app['name']);
                        }
                        ref.read(onboardingProvider.notifier).setSelectedApps(currentSelected);
                      },
                    );
                  },
                ),
              ),

              // Bottom Area
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isButtonEnabled
                            ? () async {
                                await _showPermissionDialog(context, l10n);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryBlue,
                          disabledBackgroundColor: Colors.white.withOpacity(0.3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(l10n.next, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (GoRouterState.of(context).matchedLocation.contains('onboarding'))
                      _StepIndicator(currentStep: 3),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPermissionDialog(BuildContext context, AppLocalizations l10n) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _PermissionRequestDialog(l10n: l10n);
      },
    );
    
                    if (context.mounted && context.canPop() && !GoRouterState.of(context).matchedLocation.contains('onboarding')) {
                      final uid = ref.read(firebaseServiceProvider).currentUserId;
                      if (uid != null) {
                        await ref.read(firebaseServiceProvider).updateUserField(
                          uid, 
                          'selectedApps', 
                          ref.read(onboardingProvider).selectedApps,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Uygulama listeniz güncellendi!')),
                          );
                        }
                      }
                      context.pop();
                    } else if (context.mounted) {
                      context.push('/onboarding/limit');
                    }
                  }
}

class _AppCard extends StatelessWidget {
  final String name;
  final String logoUrl;
  final bool isSelected;
  final VoidCallback onTap;

  const _AppCard({
    required this.name,
    required this.logoUrl,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white.withOpacity(0.5) : Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: Image.asset(
                    logoUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.apps, color: Colors.white, size: 48),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(Icons.check_circle_rounded, color: Colors.white.withOpacity(0.9), size: 18),
              ),
          ],
        ),
      ),
    );
  }
}

class _PermissionRequestDialog extends StatelessWidget {
  final AppLocalizations l10n;

  const _PermissionRequestDialog({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.permissionsNeeded,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            
            if (Platform.isAndroid) ...[
              _PermissionItem(
                icon: '📊',
                title: l10n.usageAccess,
                description: l10n.usageAccessDesc,
                onRequest: () => appLockServiceProvider.requestUsageStatsPermission(),
              ),
              const SizedBox(height: 20),
              _PermissionItem(
                icon: '♿',
                title: l10n.accessibilityService,
                description: l10n.accessibilityServiceDesc,
                onRequest: () => appLockServiceProvider.requestAccessibilityPermission(),
              ),
            ],
            
            if (Platform.isIOS) ...[
              _PermissionItem(
                icon: '📱',
                title: l10n.screenTimePermission,
                description: l10n.screenTimePermissionDesc,
                onRequest: () => appLockServiceProvider.requestScreenTimePermission(),
              ),
            ],

            const SizedBox(height: 20),
            _PermissionItem(
              icon: '🔔',
              title: l10n.notificationPermission,
              description: l10n.notificationPermissionDesc,
              buttonLabel: l10n.enableNotifications,
              onRequest: () => appLockServiceProvider.requestNotificationPermission(),
            ),

            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      l10n.skip,
                      style: TextStyle(color: Colors.white.withOpacity(0.5)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      minimumSize: const Size(0, 56),
                    ),
                    child: Text(l10n.continueText, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _PermissionItem extends StatelessWidget {
  final String icon;
  final String title;
  final String description;
  final String? buttonLabel;
  final Future<bool> Function() onRequest;

  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.description,
    this.buttonLabel,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(icon, style: const TextStyle(fontSize: 20)),
        ),
        const SizedBox(width: 16),
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
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  await onRequest();
                },
                child: Text(
                  buttonLabel ?? l10n.goToSettings,
                  style: const TextStyle(
                    color: Color(0xFF39D2C0),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              )
            ],
          ),
        ),
      ],
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
      children: List.generate(5, (index) {
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
