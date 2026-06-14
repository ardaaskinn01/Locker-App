import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
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

              return ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                children: [
                  // ─── Avatar Header ───────────────────────────────────────
                  const SizedBox(height: 32),
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryBlue, Colors.teal],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      user.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ─── Profil ──────────────────────────────────────────────
                  _buildSectionTitle('Profil'),
                  _buildGlassCard(
                    child: ListTile(
                      leading: _gradientIconBox(Icons.person_rounded, [AppColors.primaryBlue, const Color(0xFF39D2C0)]),
                      title: _isEditingName
                          ? TextField(
                              controller: _nameController,
                              autofocus: true,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'İsminiz',
                                hintStyle: TextStyle(color: Colors.white38),
                              ),
                              onSubmitted: (val) {
                                setState(() => _isEditingName = false);
                                ref.read(onboardingProvider.notifier).updateName(val);
                              },
                            )
                          : Text(
                              _nameController.text,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                      trailing: IconButton(
                        icon: Icon(
                          _isEditingName ? Icons.check_rounded : Icons.edit_outlined,
                          color: AppColors.primaryBlue,
                        ),
                        onPressed: () {
                          setState(() => _isEditingName = !_isEditingName);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ─── Sıfırlama Saati ─────────────────────────────────────
                  _buildSectionTitle('Sıfırlama Saati'),
                  _buildResetHourSection(user.uid, user.resetHour, user.pendingResetHour),
                  const SizedBox(height: 28),

                  // ─── Uygulama Yönetimi ───────────────────────────────────
                  _buildSectionTitle('Uygulama Yönetimi'),
                  _buildAppManagementSection(user),
                  const SizedBox(height: 28),

                  // ─── Hakkında ─────────────────────────────────────────────
                  _buildSectionTitle('Hakkında'),
                  _buildAboutSection(),
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

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.white38,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: Colors.white10),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }

  Widget _gradientIconBox(IconData icon, List<Color> colors) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }

  Widget _buildResetHourSection(String uid, int currentHour, int? pendingHour) {
    final displayHour = currentHour.toString().padLeft(2, '0');
    final pendingDisplay = pendingHour?.toString().padLeft(2, '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGlassCard(
          child: ListTile(
            leading: _gradientIconBox(Icons.access_time_rounded, [const Color(0xFFFF9100), const Color(0xFFFF3D00)]),
            title: const Text('Günlük Sıfırlama Saati', style: TextStyle(color: Colors.white)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$displayHour:00',
                  style: const TextStyle(
                    color: AppColors.accentGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Colors.white38),
              ],
            ),
            onTap: () async {
              final TimeOfDay? newTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: currentHour, minute: 0),
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(primary: AppColors.primaryBlue),
                  ),
                  child: child!,
                ),
              );
              if (newTime != null && context.mounted) {
                await jetonResetServiceProvider.updateResetHour(uid, newTime.hour);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Değişiklik yarınki sıfırlamadan itibaren geçerli olacak!')),
                );
              }
            },
          ),
        ),
        if (pendingHour != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Text(
              'Yarın $pendingDisplay:00 itibarıyla güncellenecek.',
              style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildAppManagementSection(UserModel user) {
    final selectedApps = user.selectedApps;
    return _buildGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _gradientIconBox(Icons.phone_android_rounded, [const Color(0xFF9B51E0), const Color(0xFFE040FB)]),
                const SizedBox(width: 12),
                const Text('Çok kullanılan uygulamalar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            selectedApps.isEmpty
                ? Text(
                    'Henüz uygulama eklenmedi.',
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedApps.map((app) {
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primaryBlue.withOpacity(0.5)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(app, style: const TextStyle(color: Colors.white, fontSize: 13)),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () {
                                // Remove app logic placeholder
                              },
                              child: const Icon(Icons.close, color: Colors.white38, size: 14),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(onboardingProvider.notifier).setSelectedApps(user.selectedApps);
                  context.push('/edit-apps');
                },
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Listeyi Düzenle'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  side: BorderSide(color: AppColors.primaryBlue.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return _buildGlassCard(
      child: Column(
        children: [
          // App logo area
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryBlue, Color(0xFF39D2C0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: AppColors.primaryBlue.withOpacity(0.3), blurRadius: 12),
                    ],
                  ),
                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 8),
                Text(
                  'LockApp',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          ListTile(
            leading: _gradientIconBox(Icons.privacy_tip_rounded, [const Color(0xFF4A90E2), const Color(0xFF39D2C0)]),
            title: const Text('Gizlilik Politikası', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.chevron_right, color: Colors.white38),
            onTap: () async {
              final url = Uri.parse('https://example.com/privacy');
              if (await canLaunchUrl(url)) await launchUrl(url);
            },
          ),
        ],
      ),
    );
  }
}
