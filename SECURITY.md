# Security Policy

ServerDr handles SSH credentials and can run commands on remote servers, so security reports are taken seriously.

## Supported versions

| Version | Supported |
|---|---|
| 0.1.x (Android beta) | Yes |

## Reporting a vulnerability

Please **do not** open a public issue for security vulnerabilities.

Use GitHub's private reporting instead:
**Security tab → "Report a vulnerability"** on this repository.

Include:
- A description of the issue and its impact
- Steps to reproduce
- The app version and Android version
- Any suggested fix, if you have one

You can expect an initial response within a reasonable time, though this is a solo-maintained beta project and timing may vary.

## Scope

In scope: credential storage, host-key verification, command execution safeguards, anything that could leak secrets or run unconfirmed commands on a server.

Out of scope: vulnerabilities in the remote servers you connect to, or in third-party packages (please report those upstream).

## Your own safety

- Only connect to servers you are authorized to administer.
- Review host-key fingerprints before trusting a new host.
- Treat the security audit as an aid, not a guarantee. It is not antivirus, EDR or a vulnerability scanner.