# Security Policy

## Reporting a Vulnerability

Please report security issues **privately** via
[GitHub Security Advisories](https://github.com/vadyaravadim/remove-hidden-devices/security/advisories/new)
— not through a public issue.

Expect a first response within 7 days. If a fix is warranted, it ships as a new
tagged release and the advisory is published once the fix is available.

## Supported Versions

Only the latest release receives fixes. Older tags are left as-is — update to the
newest version before reporting.

## Scope

This script runs **with administrator rights** and removes device entries with
`Unknown` status (hardware that is not present) via `pnputil /remove-device`.
That is its intended purpose, not a vulnerability.

In scope:

- The self-elevation path (`irm | iex` saving to `%USERPROFILE%` and re-running
  from there) — e.g. a way to make it execute attacker-controlled content
- The saved-copy / `.bak` handling — e.g. a path that overwrites an unrelated file
- The device selection — e.g. a way to make it remove a device that is present
  and working, or one it did not list before the confirmation
- The release pipeline — checksums, provenance, or the PowerShell Gallery package
  not matching the tagged source

Out of scope:

- Requiring admin rights, or the UAC prompt
- Removal being permanent with no undo file — documented in the
  [Disclaimer](README.md#disclaimer); reconnecting the hardware makes Windows
  reinstall it, per the
  [FAQ](README.md#what-happens-if-i-remove-a-device-i-still-use-sometimes)
- Needing a restart for the removal to fully apply — documented in the
  [FAQ](README.md#why-does-it-ask-for-a-restart)
- Driver packages left in the DriverStore — documented in
  [Full Cleanup](README.md#full-cleanup-leftover-drivers)

## Verifying a Release

Each release publishes `SHA256SUMS.txt` and Sigstore build provenance. Verify a
download before running it:

```powershell
Get-FileHash .\remove-hidden-devices.ps1 -Algorithm SHA256
```

Compare the hash against the one in the corresponding
[release](https://github.com/vadyaravadim/remove-hidden-devices/releases).

The hash only proves the file matches the release page. The provenance proves the
file was built by this repository's `release.yml` from the tagged commit - check it
with the [GitHub CLI](https://cli.github.com/):

```powershell
gh attestation verify .\remove-hidden-devices.ps1 -R vadyaravadim/remove-hidden-devices
```
