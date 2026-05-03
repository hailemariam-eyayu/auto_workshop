import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'tools/tools_screen.dart';
import 'vehicles/vehicles_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: Column(
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.build_rounded, size: 36, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text('Auto Workshop',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                          color: Colors.white, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  const Text('Management System',
                      style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
                ],
              ),
            ),

            // ── Module cards ─────────────────────────────────────────────────
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SELECT MODULE',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                            color: AppColors.textMuted, letterSpacing: 1.2)),
                    const SizedBox(height: 16),
                    _ModuleCard(
                      icon: Icons.hardware_rounded,
                      iconBg: const Color(0xFFFEE2E2),
                      iconColor: AppColors.accent,
                      borderColor: AppColors.accent,
                      title: 'Tool Inventory',
                      description: 'Track borrowed & returned tools by mechanics',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ToolsScreen())),
                    ),
                    const SizedBox(height: 12),
                    _ModuleCard(
                      icon: Icons.directions_car_rounded,
                      iconBg: const Color(0xFFDBEAFE),
                      iconColor: AppColors.primary,
                      borderColor: AppColors.primary,
                      title: 'Service & Billing',
                      description: 'Manage vehicle repairs and customer invoices',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const VehiclesScreen())),
                    ),
                  ],
                ),
              ),
            ),

            Container(
              color: AppColors.bg,
              padding: const EdgeInsets.only(bottom: 16),
              child: const Center(
                child: Text('Auto Workshop v1.0',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor, borderColor;
  final String title, description;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.icon, required this.iconBg, required this.iconColor,
    required this.borderColor, required this.title, required this.description,
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
            border: Border(left: BorderSide(color: borderColor, width: 4)),
          ),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, size: 28, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                            color: AppColors.textDark)),
                    const SizedBox(height: 2),
                    Text(description,
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
