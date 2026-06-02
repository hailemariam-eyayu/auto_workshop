import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../l10n/locale_provider.dart';

class AboutScreen extends StatelessWidget {
  final LocaleProvider locale;
  const AboutScreen({super.key, required this.locale});

  @override
  Widget build(BuildContext context) {
    final s = locale.s;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(s.about,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── App identity ──────────────────────────────────────────
          Center(
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.build_rounded,
                      size: 44, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(s.appName,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(s.managementSystem,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textMuted)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(s.versionFull,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Developed by ──────────────────────────────────────────
          _SectionLabel(s.developedBy),
          const SizedBox(height: 12),

          _DeveloperCard(
            name: 'Hailemariam Eyayu',
            email: 'hailemariameyayu@gmail.com',
            phone: '0938 169 557',
            avatarColor: AppColors.primary,
          ),
          const SizedBox(height: 12),

          _DeveloperCard(
            name: 'Mehari Nigus',
            email: 'meharinigus47@gmail.com',
            phone: '0947 010 877',
            avatarColor: AppColors.accent,
          ),
          const SizedBox(height: 32),

          // ── App info ──────────────────────────────────────────────
          _SectionLabel(s.appInfo),
          const SizedBox(height: 12),
          _InfoCard(children: [
            _InfoTile(
                icon: Icons.code_rounded,
                label: s.builtWith,
                value: 'Flutter'),
            const Divider(height: 1),
            _InfoTile(
                icon: Icons.storage_rounded,
                label: s.database,
                value: 'SQLite (sqflite)'),
            const Divider(height: 1),
            _InfoTile(
                icon: Icons.language_rounded,
                label: s.languages,
                value: 'English · አማርኛ'),
            const Divider(height: 1),
            _InfoTile(
                icon: Icons.android_rounded,
                label: s.platform,
                value: 'Android'),
          ]),
          const SizedBox(height: 40),

          // ── Footer ────────────────────────────────────────────────
          Center(
            child: Text(
              '© ${DateTime.now().year} ${s.appName}. ${s.allRightsReserved}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 1.2),
      );
}

class _DeveloperCard extends StatelessWidget {
  final String name, email, phone;
  final Color avatarColor;

  const _DeveloperCard({
    required this.name,
    required this.email,
    required this.phone,
    required this.avatarColor,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: avatarColor.withValues(alpha: 0.12),
            child: Text(initials,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: avatarColor)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
                const SizedBox(height: 6),
                _ContactRow(
                    icon: Icons.email_outlined,
                    text: email,
                    color: avatarColor),
                const SizedBox(height: 4),
                _ContactRow(
                    icon: Icons.phone_outlined,
                    text: phone,
                    color: avatarColor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _ContactRow(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 13, color: color.withValues(alpha: 0.7)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted)),
          ),
        ],
      );
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 2))
          ],
        ),
        child: Column(children: children),
      );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textMuted)),
            const Spacer(),
            Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark)),
          ],
        ),
      );
}
