import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/error_state_view.dart';
import '../../connections/models/connection_profile.dart';
import '../../connections/services/connection_repository.dart';
import '../../ssh/widgets/host_key_verification_dialog.dart';
import '../models/security_check_result.dart';
import '../services/security_service.dart';

/// Security Center. Per the brief this is explicitly NOT antivirus, EDR,
/// or a guaranteed vulnerability scanner — it's a lightweight
/// investigation tool that surfaces evidence for a human to review. See
/// `SecurityService`'s doc for exactly which checks are real right now.
class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  SecurityScanResult? _result;
  AppFailure? _failure;
  bool _scanning = false;

  Future<void> _runScan() async {
    final active = context.read<ConnectionRepository>().activeConnection;
    if (active == null) return;
    setState(() {
      _scanning = true;
      _failure = null;
    });
    try {
      final result = await context.read<SecurityService>().runScan(
            active,
            onHostKeyVerification: (request) => showHostKeyVerificationDialog(context, request),
          );
      if (!mounted) return;
      setState(() {
        _result = result;
        _scanning = false;
      });
    } on AppFailure catch (f) {
      if (!mounted) return;
      setState(() {
        _failure = f;
        _scanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = context.watch<ConnectionRepository>().activeConnection;
    return Scaffold(
      appBar: AppTopBar(
        sectionLabel: 'Security Center',
        activeConnection: active,
        onTapConnectionPill: () => context.push('/connections'),
        onTapConnections: () => context.push('/connections'),
        onTapProfile: () => context.push('/settings'),
        onTapTransfers: () => context.push('/transfers'),
      ),
      body: _buildBody(active),
    );
  }

  Widget _buildBody(ConnectionProfile? active) {
    if (active == null) {
      return const EmptyStateView(icon: Icons.dns_outlined, title: 'No server selected');
    }
    if (_failure != null) {
      return ErrorStateView(failure: _failure!, actions: [RecoveryAction(label: 'Retry', isPrimary: true, onPressed: _runScan)]);
    }

    final result = _result;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.tertiaryContainer.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.tertiary.withOpacity(0.4)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.tertiary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ServerDr performs non-invasive inspection using standard POSIX utilities '
                  '(cat, ss, find, journalctl). This is not antivirus, EDR, or a guaranteed '
                  'vulnerability scanner — findings need human review.',
                  style: TextStyle(fontFamily: 'Geist', fontSize: 11, color: AppColors.onSurface),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (result != null) _summaryRow(result),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _scanning ? null : _runScan,
          icon: _scanning
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.play_arrow, size: 18),
          label: Text(_scanning ? 'Running checks...' : 'Run Security Check'),
        ),
        if (result != null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _exportResult(result),
            icon: const Icon(Icons.ios_share, size: 16),
            label: const Text('Export Results'),
          ),
        ],
        const SizedBox(height: 16),
        if (result == null && !_scanning)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('No scan run yet', style: TextStyle(fontFamily: 'Geist', fontSize: 13, color: AppColors.onSurfaceVariant)),
            ),
          )
        else if (result != null) ...[
          const Text('Inspection Findings', style: TextStyle(fontFamily: 'Geist', fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final finding in result.findings) _findingCard(finding),
        ],
      ],
    );
  }

  Widget _summaryRow(SecurityScanResult result) {
    Widget stat(String label, int count, Color color) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(6)),
          child: Column(
            children: [
              Text('$count', style: TextStyle(fontFamily: 'Geist', fontSize: 18, fontWeight: FontWeight.w700, color: color)),
              Text(label, style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 9, color: AppColors.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        stat('PASS', result.passCount, AppColors.secondary),
        const SizedBox(width: 6),
        stat('REVIEW', result.reviewCount, AppColors.tertiary),
        const SizedBox(width: 6),
        stat('WARNING', result.warningCount, AppColors.error),
        const SizedBox(width: 6),
        stat('FINDINGS', result.findings.length, AppColors.primary),
      ],
    );
  }

  Future<void> _exportResult(SecurityScanResult result) async {
    final json = const JsonEncoder.withIndent('  ').convert(result.toJson());
    await SharePlus.instance.share(ShareParams(text: json, subject: 'ServerDr security report — ${result.serverName}'));
  }

  void _showFindingDetail(SecurityCheckResult finding) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(finding.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Status', finding.severity.label),
              _detailRow('Category', finding.category.label),
              _detailRow('Timestamp', finding.timestamp.toLocal().toString().split('.').first),
              const SizedBox(height: 8),
              const Text('Why it matters', style: TextStyle(fontFamily: 'Geist', fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(finding.description, style: const TextStyle(fontFamily: 'Geist', fontSize: 12, color: AppColors.onSurfaceVariant)),
              if (finding.evidence.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Evidence', style: TextStyle(fontFamily: 'Geist', fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(4)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: finding.evidence
                        .map((e) => Text(e, style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11)))
                        .toList(),
                  ),
                ),
              ],
              if (finding.command != null) ...[
                const SizedBox(height: 8),
                const Text('Related command', style: TextStyle(fontFamily: 'Geist', fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                SelectableText(finding.command!, style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, color: AppColors.primary)),
              ],
              if (finding.recommendedAction != null) ...[
                const SizedBox(height: 8),
                const Text('Recommended action', style: TextStyle(fontFamily: 'Geist', fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(finding.recommendedAction!, style: const TextStyle(fontFamily: 'Geist', fontSize: 12, color: AppColors.tertiary)),
              ],
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            SizedBox(width: 90, child: Text(label, style: const TextStyle(fontFamily: 'Geist', fontSize: 11, color: AppColors.onSurfaceVariant))),
            Expanded(child: Text(value, style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12))),
          ],
        ),
      );

  Widget _findingCard(SecurityCheckResult finding) {
    final color = switch (finding.severity) {
      SecuritySeverity.pass => AppColors.secondary,
      SecuritySeverity.info => AppColors.onSurfaceVariant,
      SecuritySeverity.review => AppColors.tertiary,
      SecuritySeverity.warning => AppColors.error,
      SecuritySeverity.critical => AppColors.error,
    };
    return InkWell(
      onTap: () => _showFindingDetail(finding),
      child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(6),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(finding.title, style: const TextStyle(fontFamily: 'Geist', fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(3)),
                child: Text(
                  finding.severity.label,
                  style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 9, fontWeight: FontWeight.w700, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(finding.description, style: const TextStyle(fontFamily: 'Geist', fontSize: 12, color: AppColors.onSurfaceVariant)),
          if (finding.evidence.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(4)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: finding.evidence
                    .take(5)
                    .map((e) => Text(e,
                        style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10, color: AppColors.onSurface)))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    ),
    );
  }
}
