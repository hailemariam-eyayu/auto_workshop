import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../l10n/locale_provider.dart';
import '../services/drive_backup_service.dart';
import 'employees/employees_screen.dart';
import 'borrow/borrow_screen.dart';
import 'analysis/analysis_screen.dart';
import 'materials/materials_screen.dart';
import 'vehicles/vehicles_screen.dart';
import 'about_screen.dart';
import 'backup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocaleProvider _locale = LocaleProvider();
  final _backup = DriveBackupService.instance;

  @override
  void initState() {
    super.initState();
    // Silently sign in and auto-backup on every launch if already signed in
    _autoBackup();
  }

  Future<void> _autoBackup() async {
    final user = await _backup.signInSilently();
    if (user != null) {
      await _backup.backup();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _locale,
      builder: (context, _) {
        final s = _locale.s;
        return Scaffold(
          backgroundColor: AppColors.primary,
          body: SafeArea(
            child: Column(
              children: [
                // ── Header ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Language selector
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<Locale>(
                                dropdownColor: Colors.white,
                                value: _locale.locale,
                                icon: const Icon(Icons.language,
                                    size: 14, color: Colors.white),
                                items: [
                                  DropdownMenuItem(
                                    value: const Locale('en'),
                                    child: Text(s.english,
                                        style: const TextStyle(
                                            color: Colors.black)),
                                  ),
                                  DropdownMenuItem(
                                    value: const Locale('am'),
                                    child: Text(s.amharic,
                                        style: const TextStyle(
                                            color: Colors.black)),
                                  ),
                                  DropdownMenuItem(
                                    value: const Locale('pt'),
                                    child: Text(s.portuguese,
                                        style: const TextStyle(
                                            color: Colors.black)),
                                  ),
                                ],
                                onChanged: (locale) {
                                  if (locale != null) {
                                    _locale.setLocale(locale);
                                  }
                                },
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.build_rounded,
                            size: 36, color: Colors.white),
                      ),
                      const SizedBox(height: 14),
                      Text(s.appName,
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text(s.managementSystem,
                          style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF94A3B8))),
                    ],
                  ),
                ),

                // ── Module cards ─────────────────────────────────────────
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.bg,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    padding:
                        const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.selectModule,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted,
                                  letterSpacing: 1.2)),
                          const SizedBox(height: 14),

                          _ModuleCard(
                            icon: Icons.people_rounded,
                            iconBg: const Color(0xFFDBEAFE),
                            iconColor: AppColors.primary,
                            borderColor: AppColors.primary,
                            title: s.employees,
                            description: s.registerEmployee,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => EmployeesScreen(
                                        locale: _locale))),
                          ),
                          const SizedBox(height: 10),

                          _ModuleCard(
                            icon: Icons.hardware_rounded,
                            iconBg: const Color(0xFFFEE2E2),
                            iconColor: AppColors.accent,
                            borderColor: AppColors.accent,
                            title: s.equipmentBorrow,
                            description: s.toolInventoryDesc,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => BorrowScreen(
                                        locale: _locale))),
                          ),
                          const SizedBox(height: 10),

                          _ModuleCard(
                            icon: Icons.bar_chart_rounded,
                            iconBg: const Color(0xFFD1FAE5),
                            iconColor: AppColors.success,
                            borderColor: AppColors.success,
                            title: s.analysis,
                            description: s.borrowHistory,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => AnalysisScreen(
                                        locale: _locale))),
                          ),
                          const SizedBox(height: 10),

                          _ModuleCard(
                            icon: Icons.inventory_2_rounded,
                            iconBg: const Color(0xFFFEF08A),
                            iconColor: const Color(0xFFCA8A04),
                            borderColor: const Color(0xFFCA8A04),
                            title: s.materials,
                            description: s.materialsManagement,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => MaterialsScreen(
                                        locale: _locale))),
                          ),
                          const SizedBox(height: 10),

                          _ModuleCard(
                            icon: Icons.directions_car_rounded,
                            iconBg: const Color(0xFFF3E8FF),
                            iconColor: const Color(0xFF7C3AED),
                            borderColor: const Color(0xFF7C3AED),
                            title: s.serviceBilling,
                            description: s.serviceBillingDesc,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => VehiclesScreen(
                                        locale: _locale))),
                          ),
                          const SizedBox(height: 10),

                          _ModuleCard(
                            icon: Icons.cloud_sync_rounded,
                            iconBg: const Color(0xFFE0F2FE),
                            iconColor: const Color(0xFF0284C7),
                            borderColor: const Color(0xFF0284C7),
                            title: 'Backup & Sync',
                            description: 'Back up data to Google Drive & restore',
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => BackupScreen(
                                        locale: _locale))),
                          ),
                          const SizedBox(height: 10),

                          // About
                          _ModuleCard(
                            icon: Icons.info_outline_rounded,
                            iconBg: const Color(0xFFF0FDF4),
                            iconColor: AppColors.success,
                            borderColor: AppColors.success,
                            title: s.about,
                            description: s.aboutDesc,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        AboutScreen(locale: _locale))),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Container(
                  color: AppColors.bg,
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Center(
                    child: Text(s.version,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor, borderColor;
  final String title, description;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.borderColor,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border:
                Border(left: BorderSide(color: borderColor, width: 4)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, size: 28, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark)),
                    const SizedBox(height: 2),
                    Text(description,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
