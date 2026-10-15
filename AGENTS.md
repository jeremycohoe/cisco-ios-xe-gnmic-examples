# Repository working instructions

This repository contains practical gNMIc examples for Cisco IOS XE. Keep examples
portable, safe to adapt, and honest about what was verified.

## Current structure and conventions

The repo is a copy-paste cookbook organized **operation-first, then model**:

```
README.md              landing page: matrix + encoding support + "All example commands"
get/   README.md + cisco.md / openconfig.md / ietf.md
set/   README.md + cisco.md / openconfig.md / ietf.md
subscribe/ README.md + cisco.md / openconfig.md / ietf.md
docs/  model-inventory.md · encodings.md · limitations.md · coverage.md · tls-and-credentials.md
captures/  sanitized real device output (one file per example)
scripts/   capture-server-cert.sh · check-server-cert.sh · check-links.sh
```

- **Recipe format** (every example): Goal -> Command -> Observed response
  (inline + capture link) -> Change these fields -> Verify -> Rollback (writes
  only) -> Status line (device / release / date).
- **README front page** carries the full matrix (Get/Set/Subscribe/Techniques),
  the operation x encoding support grid, and an "All example commands" block.
  Every matrix cell links to its recipe; keep this true when adding examples.
- **docs/coverage.md** is the audit trail (verified / not-collected). Update it
  with every change.
- **docs/encodings.md** is the per-xpath `json_ietf`/`json`/`proto` grid.
- Run **`scripts/check-links.sh`** before committing; it validates every local
  markdown link and heading anchor.

## Devices used and quirks

- **Primary:** Catalyst 9300 stack, IOS XE 26.02.1, secure gNMI TLS on `9339`,
  `secure-password-auth`, self-signed `gnxi secure-init` cert (use `--skip-verify`).
- **Second:** Catalyst 9300-24UX, IOS XE 26.1 (memory subscription with values,
  multi-path, encodings). Label second-device results explicitly; streaming
  support differs by release.
- **Native-write timeouts are intermittent, not permanent.** `Cisco-IOS-XE-native`
  hostname/VLAN writes normally complete in ~1s, but under config-DB contention
  (concurrent transactions, just after reload, rapid successive writes) they can
  return `DeadlineExceeded` while still applying, and a retry can hit a config-DB
  lock. Always Get the path to confirm; never retry blindly.
- **gNMI may be plaintext or TLS depending on config.** Secure server = TLS on
  `9339` (`--skip-verify`); insecure server = plaintext gRPC on `50052`
  (`--insecure`). Enabling `secure-server` removes the insecure listener.
- **`secure-client-auth` (mutual TLS)** makes TLS succeed but the gRPC stream
  reset (`error reading server preface: EOF`) if no client cert / trustpoint is
  set. Fix on-device or pass `--tls-ca/--tls-cert/--tls-key`. See
  `docs/tls-and-credentials.md`.

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
- The owner authorized live hostname changes, a lab VLAN in `800-899`, and
  interface description/enable writes on an approved lab port. These are done and
  verified (and rolled back where applicable): hostname Update/Replace, VLAN name
  Update/Replace, VLAN **Delete** (shown on throwaway VLAN `898`; `899` is the
  documented one), Cisco-native/OpenConfig/IETF interface description
  Update/Replace/Delete, and OpenConfig `config/enabled`.
- Authorization does **not** extend to gNMI service/TLS settings, AAA, MDT/NTP
  telemetry config, or other `-cfg` models. Use templates or local dry-run until
  the specific target and value are authorized.
- After a Set timeout, Get the target path before retrying; a timeout does not
  show whether the device applied the request. If IOS XE reports a configuration
  database lock, check state and wait for the lock to clear before retrying.
- For a Delete, use a throwaway lab object and keep the documented objects (e.g.
  VLAN `899`) intact.

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

## Workflow for changes (follow every time)

1. Connect with the shared `gnmi()` helper (env vars; password typed by the
   owner or reused only with explicit owner consent). Never route secrets you
   are not given.
2. Run the example live; capture the sanitized response into `captures/`
   (redact `<DEVICE_ADDRESS>`, `<REDACTED_HOSTNAME>`, peer IPs, subscription IDs,
   serials, MACs). Preserve the real response shape.
3. Add/adjust the recipe (Goal..Status format), the README matrix + command
   list, the relevant index, `docs/coverage.md`, and `docs/encodings.md` if an
   encoding is involved.
4. `scripts/check-links.sh` must pass; grep the tree for any secret, device IP,
   or real hostname before committing.
5. Scrub the password from the shell: `unset GNMIC_PASSWORD ...` and remove it
   from `~/.zsh_history`.
6. Commit (repo is Apache-2.0, git-tracked, remote `origin`) and push only when
   the owner says to publish. The owner has been publishing per-step.

## Backlog (not yet done)

- **gNOI** operations (System.Reboot, File, Cert Management, ping/traceroute) —
  advertised, zero coverage.
- **More Set models** — IP address, SVI, routing, NTP/logging config (need
  approved exact path/value).
- **Other platforms** — only Catalyst 9300 (x2) so far.
