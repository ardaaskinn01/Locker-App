import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/localization/translations.dart';
import '../../models/user_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/jeton_reset_service.dart';
import '../../features/home/home_providers.dart';
import '../onboarding/onboarding_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _appVersion = '1.0.0';
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${info.version} (${info.buildNumber})';
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final translations = ref.watch(translationProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: userAsync.when(
            data: (user) {
              if (user == null) {
                return const Center(child: Text('Kullanıcı bulunamadı', style: TextStyle(color: Colors.white)));
              }
              if (!_isEditingName && _nameController.text.isEmpty) {
                _nameController.text = user.name;
              }

              final initials = user.name.isNotEmpty
                  ? user.name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
                  : '?';

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // --- PREMIUM HEADER ---
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF3B82F6), Color(0xFF2DD4BF)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF3B82F6).withOpacity(0.35),
                                      blurRadius: 25,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1E293B),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF2DD4BF),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _isEditingName
                                  ? SizedBox(
                                      width: 200,
                                      child: TextField(
                                        controller: _nameController,
                                        autofocus: true,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                        decoration: const InputDecoration(border: InputBorder.none),
                                        onSubmitted: (val) {
                                          setState(() => _isEditingName = false);
                                          ref.read(onboardingProvider.notifier).updateName(val);
                                        },
                                      ),
                                    )
                                  : Text(
                                      user.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => setState(() => _isEditingName = !_isEditingName),
                                child: Icon(
                                  _isEditingName ? Icons.check_circle_outline_rounded : Icons.edit_note_rounded,
                                  color: Colors.white.withOpacity(0.4),
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          // Stats row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildStatItem(translations.get('jetons'), user.jetons.toString(), Icons.monetization_on_rounded, const Color(0xFFFFD740)),
                              const SizedBox(width: 32),
                              _buildStatItem(translations.get('level'), 'A1', Icons.auto_awesome_rounded, const Color(0xFF2DD4BF)),
                              const SizedBox(width: 32),
                              _buildStatItem(translations.get('streak'), '0', Icons.local_fire_department_rounded, const Color(0xFFFF5722)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- SETTINGS GROUPS ---
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildSectionHeader(translations.get('accountProfile')),
                        _buildSettingsGroup([
                          _SettingsItem(
                            icon: Icons.access_time_filled_rounded,
                            color: const Color(0xFFFF9100),
                            title: translations.get('resetTime'),
                            trailing: Text(
                              '${user.resetHour.toString().padLeft(2, '0')}:00',
                              style: const TextStyle(color: Color(0xFFFFD740), fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            onTap: () => _pickResetHour(user.uid, user.resetHour),
                          ),
                          _SettingsItem(
                            icon: Icons.language_rounded,
                            color: const Color(0xFF3B82F6),
                            title: translations.get('appLanguage'),
                            trailing: Text(
                              ref.watch(languageProvider) == 'tr' ? translations.get('turkish') : translations.get('english'),
                              style: const TextStyle(color: Colors.white54, fontSize: 14),
                            ),
                            onTap: () => _showLanguagePicker(context, ref),
                          ),
                        ]),
                        
                        const SizedBox(height: 24),
                        _buildSectionHeader(translations.get('appManagement')),
                        _buildSettingsGroup([
                          _AppManagementWidget(user: user),
                        ]),

                        const SizedBox(height: 24),
                        _buildSectionHeader(translations.get('supportInfo')),
                        _buildSettingsGroup([
                          _SettingsItem(
                            icon: Icons.security_rounded,
                            color: const Color(0xFF10B981),
                            title: translations.get('privacyPolicy'),
                            onTap: () => _launchURL('https://example.com/privacy'),
                          ),
                        ]),
                      ]),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Hata: $err', style: const TextStyle(color: Colors.white))),
          ),
        ),
      ),
    );
  }

  // --- UI BUILDER METHODS ---

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.8,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(children: items),
      ),
    );
  }

  Future<void> _pickResetHour(String uid, int currentHour) async {
    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: 0),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFF3B82F6), onSurface: Colors.white),
        ),
        child: child!,
      ),
    );
    if (newTime != null && context.mounted) {
      await jetonResetServiceProvider.updateResetHour(uid, newTime.hour);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(translationProvider).get('resetTimeUpdated')),
          backgroundColor: const Color(0xFF3B82F6),
        ),
      );
    }
  }

  Future<void> _launchURL(String urlStr) async {
    final url = Uri.parse(urlStr);
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    final translations = ref.read(translationProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              translations.get('languageSelection'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 24),
            _buildLanguageOption(context, ref, 'tr', translations.get('turkish'), '🇹🇷'),
            _buildLanguageOption(context, ref, 'en', translations.get('english'), '🇺🇸'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, WidgetRef ref, String code, String label, String flag) {
    final current = ref.read(languageProvider);
    final isSelected = current == code;

    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF3B82F6)) : null,
      onTap: () async {
        ref.read(languageProvider.notifier).state = code;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('appLanguage', code);
        if (context.mounted) Navigator.pop(context);
      },
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.color,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              if (trailing != null) trailing!,
              if (onTap != null && trailing == null)
                Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.1), size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppManagementWidget extends ConsumerWidget {
  final UserModel user;
  const _AppManagementWidget({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = ref.watch(translationProvider);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF9B51E0).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.apps_rounded, color: Color(0xFF9B51E0), size: 22),
              ),
              const SizedBox(width: 16),
              Text(
                translations.get('frequentApps'),
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                translations.tr('appsCount', {'count': user.selectedApps.length.toString()}),
                style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (user.selectedApps.isEmpty)
            Text(translations.get('noAppsSelected'), style: const TextStyle(color: Colors.white24, fontSize: 13))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: user.selectedApps.map((app) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(app, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                ref.read(onboardingProvider.notifier).setSelectedApps(user.selectedApps);
                context.push('/edit-apps');
              },
              icon: const Icon(Icons.add_task_rounded, size: 20),
              label: Text(translations.get('editList')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
