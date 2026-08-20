# Remove Hidden Devices

A single self-contained PowerShell script (`remove-hidden-devices.ps1`) that enumerates non-present
devices - the ghost entries left behind by unplugged USB sticks, headsets, dongles and old GPUs - and
removes them from Device Manager. Part of a family of six single-script Windows tuning tools that share
this layout: one `.ps1`, `Run.bat`, `PSScriptAnalyzerSettings.psd1`, and the same three workflows.

**This tool has no undo file, and that is not an oversight.** Removing a ghost device only drops a
registration for hardware that is not present; plugging the device back in makes Windows re-enumerate it.
Do not add a `.reg` snapshot mechanism here by analogy with the sibling tools - there is no prior state
worth restoring.

**A piped run saves the script into the user profile with no BOM.** `[Text.UTF8Encoding]::new($false)` is
load-bearing: a BOM in the saved copy breaks running that copy through `irm | iex` later, because the
parser chokes on the leading U+FEFF. This shipped as a bug once already.

## Version numbers went backwards once

The tags read `v1.1.0` (2026-07-18) -> `v1.0.1` (2026-07-19) -> `v1.1.1` (2026-07-20): 1.0.1 is a
DESCENDANT of 1.1.0. `CHANGELOG.md` is therefore ordered by release, not by version, and says so. Do not
"fix" the ordering into semver order - it would misstate what actually shipped when. The next tag has to be
above 1.1.1.

## The two CI gates

- **`ascii-check.yml` - the .ps1 must be pure ASCII with no BOM.** Both halves are load-bearing: a BOM
  makes `irm | iex` choke on a leading U+FEFF, and non-ASCII in a BOM-less file turns into mojibake when
  Windows PowerShell 5.1 runs it with `-File`. Write `\uXXXX` regex escapes rather than literals; em-dashes
  and typographic quotes are the usual way this reds. Only the `.ps1` is checked - Markdown is free.
- **`lint.yml` - PSScriptAnalyzer over the whole repo, Error + Warning, any finding fails.** Suppressions
  live in `PSScriptAnalyzerSettings.psd1` with the reason written next to each rule. Extend that file with
  a justification instead of adding an inline suppression attribute.

## Release - the tag is the only source of truth

`git tag vX.Y.Z && git push origin vX.Y.Z` runs `release.yml`, which stamps the tag into `.VERSION`, hashes
the script, attests build provenance, creates the GitHub Release and publishes to the PowerShell Gallery.
Nothing ships from a push to `main`.

**Before tagging, move the `## [Unreleased]` bullets in `CHANGELOG.md` into a `## [X.Y.Z] - YYYY-MM-DD`
section and add the compare link at the bottom.** The release job copies exactly that section into the
release body and **fails the release when the tag's section is missing**. This is a gate on purpose, not a
fallback: notes are hand-written because GitHub's `--generate-notes` lists merged PRs, and this repo lands
nearly everything as direct commits to `main`, so it published releases whose whole body was a compare
link.

Write the entries for someone who runs the tool, not for someone reading the diff: what changed on their
machine and why it matters. A fix says what was broken and what it cost them.

Do NOT bump `.VERSION` in the `.ps1` by hand - it is a placeholder the workflow overwrites, and a
hand-edited value that disagrees with the tag would only mislead whoever reads the committed file.
