import 'dart:convert';
import 'dart:typed_data';

/// Formats a raw SHA-256 host-key digest (as handed to
/// `SSHHostkeyVerifyHandler` by dartssh2) into the standard OpenSSH
/// display format: `SHA256:<base64, no padding>` — the same string
/// `ssh-keygen -lf` prints, so it's directly comparable to what the user
/// sees from the command line.
String formatSshFingerprint(Uint8List rawSha256Digest) {
  final b64 = base64.encode(rawSha256Digest);
  final noPadding = b64.replaceAll('=', '');
  return 'SHA256:$noPadding';
}
