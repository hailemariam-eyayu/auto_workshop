import 'package:flutter/material.dart';
import '../l10n/locale_provider.dart';
import '../services/drive_backup_service.dart';
import '../theme/app_colors.dart';

class BackupScreen extends StatefulWidget {
  final LocaleProvider locale;
  const BackupScreen({super.key, required this.locale});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _svc = DriveBackupService.instance;
  bool _loading = false;
  String? _lastBackupTime;
  String? _statusMessage;
  bool _statusOk = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Try silent sign-in on open
    await _svc.signInSilently();
    if (_svc.isSignedIn) {
      final t = await _svc.getLastBackupTime();
      if (mounted) setState(() => _lastBackupTime = t);
    }
    if (mounted) setState(() {});
  }

  Future<void> _signIn() async {
    setState(() => _loading = true);
    final user = await _svc.signIn();
    if (user != null) {
      final t = await _svc.getLastBackupTime();
      _setStatus(true, 'Signed in as ${user.email}');
      setState(() => _lastBackupTime = t);
    } else {
      _setStatus(false, 'Sign-in cancelled or failed');
    }
    setState(() => _loading = false);
  }

  Future<void> _signOut() async {
    await _svc.signOut();
    setState(() {
      _lastBackupTime = null;
      _statusMessage = null;
    });
  }

  Future<void> _backup() async {
    setState(() => _loading = true);
    final result = await _svc.backup();
    switch (result) {
      case BackupResult.success:
        final t = await _svc.getLastBackupTime();
        setState(() => _lastBackupTime = t);
        _setStatus(true, 'Backup successful ✓');
        break;
      case BackupResult.notSignedIn:
        _setStatus(false, 'Please sign in first');
        break;
      case BackupResult.error:
        _setStatus(false, 'Backup failed. Check your connection.');
        break;
    }
    setState(() => _loading = false);
  }

  Future<void> _restore() async {
    // Confirm before overwriting local data
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restore from Google Drive?'),
        content: const Text(
          'This will REPLACE all local data with the backup from Google Drive.\n\n'
          'Any data not backed up will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Restore', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _loading = true);
    final result = await _svc.restore();
    switch (result) {
      case RestoreResult.success:
        _setStatus(true, 'Restore successful ✓  —  Please restart the app.');
        break;
      case RestoreResult.notSignedIn:
        _setStatus(false, 'Please sign in first');
        break;
      case RestoreResult.noBackupFound:
        _setStatus(false, 'No backup found in Google Drive');
        break;
      case RestoreResult.error:
        _setStatus(false, 'Restore failed. Check your connection.');
        break;
    }
    setState(() => _loading = false);
  }

  void _setStatus(bool ok, String msg) {
    setState(() {
      _statusOk = ok;
      _statusMessage = msg;
    });
  }

  String _formatTime(String? iso) {
    if (iso == null) return 'Never';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.year}-${_p(dt.month)}-${_p(dt.day)}  '
          '${_p(dt.hour)}:${_p(dt.minute)}';
    } catch (_) {
      return iso;
    }
  }

  String _p(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final user = _svc.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Sync'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Info banner ──────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your data is stored privately in your own Google Drive '
                            '(hidden app folder — not visible in Drive UI). '
                            'Sign in to back up or restore when you reset or '
                            'reinstall the app.',
                            style: TextStyle(
                                fontSize: 13, color: Colors.blue.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Account card ─────────────────────────────────────
                  _SectionCard(
                    title: 'Google Account',
                    child: user == null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Not signed in',
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _signIn,
                                icon: const Icon(Icons.login),
                                label: const Text('Sign in with Google'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.primary,
                                child: Text(
                                  (user.displayName ?? user.email)[0]
                                      .toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.displayName ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      user.email,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: _signOut,
                                child: const Text('Sign out',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),

                  // ── Last backup ──────────────────────────────────────
                  _SectionCard(
                    title: 'Last Backup',
                    child: Row(
                      children: [
                        Icon(Icons.cloud_done_outlined,
                            color: _lastBackupTime != null
                                ? Colors.green
                                : Colors.grey,
                            size: 22),
                        const SizedBox(width: 10),
                        Text(
                          _formatTime(_lastBackupTime),
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Actions ──────────────────────────────────────────
                  _SectionCard(
                    title: 'Actions',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Backup now
                        ElevatedButton.icon(
                          onPressed: user != null ? _backup : null,
                          icon: const Icon(Icons.cloud_upload_outlined),
                          label: const Text('Backup Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Restore
                        OutlinedButton.icon(
                          onPressed: user != null ? _restore : null,
                          icon: const Icon(Icons.cloud_download_outlined),
                          label: const Text('Restore from Drive'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(
                                color: AppColors.primary),
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                        if (user == null) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Sign in to enable backup and restore',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ── Status message ───────────────────────────────────
                  if (_statusMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _statusOk
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _statusOk
                              ? Colors.green.shade300
                              : Colors.red.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _statusOk
                                ? Icons.check_circle_outline
                                : Icons.error_outline,
                            color: _statusOk ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _statusMessage!,
                              style: TextStyle(
                                color: _statusOk
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // ── How it works ─────────────────────────────────────
                  _SectionCard(
                    title: 'How it works',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _Step(
                          n: '1',
                          text:
                              'Sign in with your Google account.',
                        ),
                        _Step(
                          n: '2',
                          text:
                              'Tap "Backup Now" to save all employees, '
                              'borrows, history, and vehicles to your '
                              'private Google Drive.',
                        ),
                        _Step(
                          n: '3',
                          text:
                              'If you reset the app or install it on a '
                              'new device, sign in and tap '
                              '"Restore from Drive" to get your data back.',
                        ),
                        _Step(
                          n: '4',
                          text:
                              'The backup file is stored in a hidden app '
                              'folder — only this app can access it.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 1.1)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String n, text;
  const _Step({required this.n, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(n,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
