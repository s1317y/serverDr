import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/security/host_key_store.dart';
import '../../../core/widgets/error_state_view.dart';

/// "Known SSH Hosts" — the on-device equivalent of `~/.ssh/known_hosts`.
/// Lets the user intentionally remove a trust record (the ONLY sanctioned
/// way to clear a host-key mismatch — never a silent auto-accept from the
/// connect flow itself).
class KnownHostsScreen extends StatefulWidget {
  const KnownHostsScreen({super.key});

  @override
  State<KnownHostsScreen> createState() => _KnownHostsScreenState();
}

class _KnownHostsScreenState extends State<KnownHostsScreen> {
  List<TrustedHostKey>? _hosts;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final store = context.read<HostKeyStore>();
    final hosts = await store.listAll();
    hosts.sort((a, b) => b.firstSeenAt.compareTo(a.firstSeenAt));
    if (mounted) setState(() => _hosts = hosts);
  }

  Future<void> _removeTrust(TrustedHostKey host) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove trust?'),
        content: Text(
          'The next connection to ${host.hostPortLabel} will require host-key '
          'verification again.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.errorContainer, foregroundColor: AppColors.onErrorContainer),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove Trust'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await context.read<HostKeyStore>().removeTrust(host.host, host.port);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Known SSH Hosts')),
      body: _hosts == null
          ? const Center(child: CircularProgressIndicator())
          : _hosts!.isEmpty
              ? const EmptyStateView(
                  icon: Icons.vpn_key_off_outlined,
                  title: 'No trusted hosts yet',
                  subtitle: 'Hosts you trust during SSH/SFTP connect will appear here.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _hosts!.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final host = _hosts![index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  host.hostPortLabel,
                                  style: const TextStyle(fontFamily: 'Geist', fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  host.keyType,
                                  style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10, color: AppColors.onSurfaceVariant),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            host.fingerprint,
                            style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: AppColors.primary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Trusted since ${host.firstSeenAt.toLocal()}'.split('.').first,
                            style: const TextStyle(fontFamily: 'Geist', fontSize: 10, color: AppColors.outline),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => _removeTrust(host),
                              icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                              label: const Text('Remove Trust', style: TextStyle(color: AppColors.error)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
