# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Each released section below IS the GitHub Release body for that tag: `release.yml` copies the section
verbatim into the release and fails the release if the tag has no section here.

Sections are in release order, newest first. Note that 1.0.1 was tagged *after* 1.1.0: the version number
went backwards once early on, so release order and version order disagree in this repository's history.

## [Unreleased]

## [1.1.1] - 2026-07-20

### Fixed

- The copy a piped `irm ... | iex` run saves into your user profile was written with a UTF-8 BOM, which
  then broke running that saved copy through `irm | iex` again - the parser chokes on the leading byte
  order mark. It is now written without one.

## [1.0.1] - 2026-07-19

### Added

- The tool runs from a one-line `irm ... | iex` command: it saves itself into your user profile and reruns
  from there, which is what gives the run a real file to elevate. An existing copy that differs is kept as
  `.bak` rather than overwritten.
- Published to the PowerShell Gallery: `Install-Script remove-hidden-devices`.
- Every tagged release ships a `SHA256SUMS.txt` alongside the script plus a signed build-provenance
  attestation, so you can verify the file you downloaded is the one the workflow built from this source.

### Fixed

- The script carried a UTF-8 BOM and non-ASCII characters in its output. Both broke real launch paths: the
  BOM made `irm | iex` choke on the leading byte order mark, and the non-ASCII characters turned into
  mojibake when Windows PowerShell 5.1 ran the file with `-File`. The file is pure ASCII with no BOM
  now - reversing the BOM 1.1.0 had added to fix a different parse failure - and a CI check keeps it that
  way.
- A failed elevation now prints the actual reason and keeps the window open. Elevation can fail for reasons
  other than a refused UAC prompt - a disabled UAC service, for one - and the old message assumed a
  refusal.

## [1.1.0] - 2026-07-18

### Added

- First release. Enumerates the devices whose driver is still registered but that are not currently
  present - the ghost entries left behind by unplugged USB sticks, headsets, dongles and old GPUs - and
  removes them, so Device Manager shows only hardware that is actually connected.
- Self-elevates through UAC: start it from an ordinary session and confirm the prompt, so there is
  no need to open an admin console yourself first. Zero external dependencies.
- `Run.bat` makes it a double-click, the same launcher pattern the rest of the series uses.

### Changed

- The README was rewritten in the format the rest of the series uses: Quick Start, The Problem:
  Ghost Devices, How It Works, Verify, Full Cleanup (Driver Store Explorer), FAQ, and Related.

### Fixed

- The script failed to parse under Windows PowerShell 5.1, which is the version that ships with
  Windows, the one `Run.bat` and a plain `powershell.exe` both use, and therefore the one most
  people were running it with. The file was saved as UTF-8 with no BOM, so 5.1 read it as ANSI and
  the multi-byte check mark and arrow characters in its output broke string parsing - one of their
  bytes, `0x93`, was taken for a smart quote. The file is saved as UTF-8 with a BOM now.

[Unreleased]: https://github.com/vadyaravadim/remove-hidden-devices/compare/v1.1.1...HEAD
[1.1.1]: https://github.com/vadyaravadim/remove-hidden-devices/compare/v1.0.1...v1.1.1
[1.0.1]: https://github.com/vadyaravadim/remove-hidden-devices/compare/v1.1.0...v1.0.1
[1.1.0]: https://github.com/vadyaravadim/remove-hidden-devices/releases/tag/v1.1.0
