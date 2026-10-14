# Repository working instructions

This repository contains practical gNMIc examples for Cisco IOS XE. Keep examples
portable, safe to adapt, and honest about what was verified.

## Before adding an example

- Check the target's live `Capabilities` for model names, revisions, encodings,
  and gNMI version. Cisco IOS XE releases can differ.
- Prefer a narrow leaf path. Do not collect or publish broad configuration,
  inventory, or state trees that may expose addresses, serial numbers, MAC
  addresses, topology, credentials, or customer names.
- Use environment variables or interactive prompts for address and credentials.
  Never add real passwords, tokens, private keys, client certificates, or
  reusable device addresses to tracked files.
- Use placeholders for hostnames, interface IDs, VLAN IDs, descriptions, and
  values unless the owner has explicitly approved that exact output for release.

## Record commands and results

- Pair each example command with its observed response or a clearly labeled
  representative response.
- Mark each example `verified`, `dry-run`, `template`, or `not observed`.
- Preserve the actual gNMI response shape when sanitizing; replace sensitive
  values with explicit tokens such as `<REDACTED_HOSTNAME>` and say what changed.
- Record the device family, software release, model, encoding, and date when
  useful. Never imply that a result applies to every IOS XE release.
- For subscriptions, record the mode, interval, initial response, and whether
  later updates were actually observed.

## Configuration changes

- A documentation request does not by itself authorize a live Set operation.
- The user explicitly authorized real hostname changes and creation of one lab
  VLAN in the range 800-899 for this workflow. Keep those writes narrow, record
  the prior state, and provide a rollback. Do not require a dry run for these
  explicitly authorized live changes.
- That authorization does not extend to interface descriptions, AAA, telemetry,
  gNMI service/TLS settings, or other configuration models. Use templates or
  local dry-run rendering for those until the specific target and value are
  authorized.
- After a Set timeout, Get the target path before retrying; a timeout does not
  show whether the device applied the request. If IOS XE reports a configuration
  database lock, check state and wait for the lock to clear before retrying.
- Avoid destructive `replace` or `delete` examples unless their scope and
  rollback are explicit.

## TLS and publication

- Prefer CA validation with a server certificate that has a valid DNS or IP SAN.
- Document `--skip-verify` as a lab-only diagnostic. It bypasses server identity
  validation and must not be presented as secure certificate verification.
- A certificate fingerprint check is a first-contact identity check, not a
  replacement for gNMIc's TLS hostname validation. Confirm a fingerprint over
  an independent trusted channel before accepting it.
- Never commit a captured private key or a live credential. Keep captured
  certificates out of the repository unless the owner explicitly approves
  publication; certificate metadata and fingerprints can identify a device.
- Do not push or publish changes unless the user says the repository is ready.

## Repository quality

- Keep commands copyable in Bash and explain required flags and assumptions.
- Link Cisco/gNMIc claims to upstream documentation.
- Do not claim a command or response was tested unless the recorded result
  supports that claim.
