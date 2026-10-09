import 'package:flutter/foundation.dart';

/// Severity vocabulary the brief mandates — deliberately NOT "vulnerable/
/// safe" binary language. `Critical` requires strong evidence; most
/// findings should land on `Review` (needs a human look) rather than a
/// confident-sounding label the evidence doesn't support.
enum SecuritySeverity { info, pass, review, warning, critical }

extension SecuritySeverityLabel on SecuritySeverity {
  String get label => switch (this) {
        SecuritySeverity.info => 'INFO',
        SecuritySeverity.pass => 'PASS',
        SecuritySeverity.review => 'REVIEW',
        SecuritySeverity.warning => 'WARNING',
        SecuritySeverity.critical => 'POTENTIALLY SUSPICIOUS',
      };
}

enum SecurityCategory {
  authentication,
  filesystem,
  network,
  users,
  persistence,
  processes,
  ssh,
  web,
  system,
  docker,
}

extension SecurityCategoryLabel on SecurityCategory {
  String get label => switch (this) {
        SecurityCategory.authentication => 'Authentication',
        SecurityCategory.filesystem => 'Filesystem',
        SecurityCategory.network => 'Network',
        SecurityCategory.users => 'Users',
        SecurityCategory.persistence => 'Persistence',
        SecurityCategory.processes => 'Processes',
        SecurityCategory.ssh => 'SSH',
        SecurityCategory.web => 'Web',
        SecurityCategory.system => 'System',
        SecurityCategory.docker => 'Docker',
      };
}

/// One structured finding from a security check. The UI renders this —
/// it never parses shell output itself.
///
/// IMPORTANT: [severity] must reflect what [evidence] actually supports.
/// A check finding "PermitRootLogin yes" is [SecuritySeverity.review],
/// not [SecuritySeverity.critical] — it's a config fact the admin should
/// look at, not a confirmed compromise. See each check implementation's
/// doc for how it decides.
@immutable
class SecurityCheckResult {
  const SecurityCheckResult({
    required this.id,
    required this.title,
    required this.category,
    required this.severity,
    required this.description,
    required this.evidence,
    required this.timestamp,
    this.metadata = const {},
    this.command,
    this.recommendedAction,
  });

  final String id;
  final String title;
  final SecurityCategory category;
  final SecuritySeverity severity;

  /// Plain-language explanation of what this means — never an alarmist
  /// claim beyond what [evidence] shows.
  final String description;

  /// Raw supporting evidence (a config line, a log excerpt, a count) —
  /// shown verbatim so the admin can judge for themselves.
  final List<String> evidence;

  final DateTime timestamp;
  final Map<String, String> metadata;

  /// The read-only command that produced this finding, shown in the
  /// detail drill-down so the admin can re-run it themselves. Optional —
  /// not every check maps cleanly to one command.
  final String? command;

  /// A suggested next step — deliberately advisory ("Consider..."), never
  /// an instruction ServerDr would execute itself.
  final String? recommendedAction;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category.label,
        'severity': severity.label,
        'description': description,
        'evidence': evidence,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
        if (command != null) 'command': command,
        if (recommendedAction != null) 'recommendedAction': recommendedAction,
      };
}

/// The result of running a full (or category-filtered) scan — what the
/// Security Overview screen renders.
@immutable
class SecurityScanResult {
  const SecurityScanResult({required this.findings, required this.completedAt, required this.serverName});

  final List<SecurityCheckResult> findings;
  final DateTime completedAt;
  final String serverName;

  int get passCount => findings.where((f) => f.severity == SecuritySeverity.pass).length;
  int get reviewCount => findings.where((f) => f.severity == SecuritySeverity.review).length;
  int get warningCount => findings.where((f) => f.severity == SecuritySeverity.warning).length;
  int get criticalCount => findings.where((f) => f.severity == SecuritySeverity.critical).length;

  Map<String, dynamic> toJson() => {
        'server': serverName,
        'completedAt': completedAt.toIso8601String(),
        'summary': {'pass': passCount, 'review': reviewCount, 'warning': warningCount, 'critical': criticalCount},
        'findings': findings.map((f) => f.toJson()).toList(),
      };
}
