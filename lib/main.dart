import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/security/host_key_store.dart';
import 'core/storage/secure_credential_store.dart';
import 'features/browser/services/web_view_service.dart';
import 'features/connections/services/connection_repository.dart';
import 'features/sftp/services/real_sftp_service.dart';
import 'features/sftp/services/sftp_service.dart';
import 'features/ssh/services/real_ssh_service.dart';
import 'features/ssh/services/ssh_service.dart';
import 'features/transfers/services/transfer_manager.dart';

/// Composition root.
///
/// Every feature screen depends only on an interface (`SshService`,
/// `SftpService`, `ConnectionRepository`, `TransferManager`,
/// `WebViewService`, `HostKeyStore`, `SecureCredentialStore`). This is the
/// ONLY file that decides which concrete implementation backs each one.
///
/// `RealSshService`/`RealSftpService` (dartssh2) are wired in as the
/// default now that this phase moves off mocks. `MockSshService` was
/// removed (its structured-entries shape couldn't represent a real
/// interactive shell — see `SshSession`'s doc); `MockSftpService` is
/// still in the tree and conforms to the same interface as the real one,
/// so a debug/demo build flavor could swap it back in here without
/// touching any screen.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Modern Android draws edge-to-edge by default; this plus the AppBar-
  // based top bar and NavigationBar's own bottom-inset handling is the
  // full status-bar-overlap fix — no screen adds a manual padding number.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final prefs = await SharedPreferences.getInstance();
  final hostKeyStore = SecureHostKeyStore();
  final credentialStore = SecureCredentialStoreImpl();

  runApp(
    MultiProvider(
      providers: [
        Provider<HostKeyStore>.value(value: hostKeyStore),
        Provider<SecureCredentialStore>.value(value: credentialStore),
        ChangeNotifierProvider<ConnectionRepository>(
          create: (_) => PersistentConnectionRepository(prefs: prefs),
        ),
        Provider<SshService>(
          create: (_) => RealSshService(hostKeyStore: hostKeyStore, credentialStore: credentialStore),
        ),
        Provider<SftpService>(
          create: (_) => RealSftpService(hostKeyStore: hostKeyStore, credentialStore: credentialStore),
        ),
        ChangeNotifierProvider<TransferManager>(create: (_) => MockTransferManager()),
        ChangeNotifierProvider<WebViewService>(create: (_) => StubWebViewService()),
      ],
      child: const ServerKitApp(),
    ),
  );
}
