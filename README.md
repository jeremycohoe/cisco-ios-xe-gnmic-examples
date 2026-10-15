# Cisco IOS XE gNMIc examples

A hands-on cookbook of gNMIc commands for Cisco Catalyst 9300 running IOS XE.
Every command here was run against a lab switch, and each example shows the
sanitized response it produced. Copy a command, change only the highlighted
fields, and compare your output to ours.

## What's covered

Pick an **operation**, then a **model/xpath**, and click through to the recipe
with its command and real observed response. ✅ = verified live · ❌ = device
limitation (not shown as a recipe).

Each operation folder also has a README index: [get/](get/README.md),
[set/](set/README.md), [subscribe/](subscribe/README.md). Every recipe follows
the same shape: **Goal → Command → Observed response → Change these fields →
Verify → Rollback** (writes only).

### Get

| Model | XPath | Recipe |
|---|---|---|
| `Cisco-IOS-XE-native` | `native/hostname` | ✅ [hostname](get/cisco.md#cisco-hostname) |
| `Cisco-IOS-XE-native` | `native/interface/<Type>[name=<id>]/description` | ✅ [interface description](get/cisco.md#cisco-interface-description) |
| `Cisco-IOS-XE-native` | `native/vlan/.../vlan-list[id=<n>]` | ✅ [VLAN configuration](get/cisco.md#cisco-vlan-configuration) |
| `Cisco-IOS-XE-vlan-oper` | `vlans/vlan[id=<n>]` and `/ports` | ✅ [VLAN operational state](get/cisco.md#cisco-vlan-operational-state) |
| `Cisco-IOS-XE-interfaces-oper` | `interfaces/interface[name=<if>]/oper-status` | ✅ [interface status](get/cisco.md#cisco-interface-operational-status) |
| `Cisco-IOS-XE-interfaces-oper` | `interfaces/interface[name=<if>]/statistics` | ✅ [interface counters](get/cisco.md#cisco-interface-counters) |
| `Cisco-IOS-XE-gnmi-cfg` | `gnmi-cfg-data/config/secure-port` | ✅ [secure gNMI port](get/cisco.md#cisco-gnmi-secure-port) |
| `Cisco-IOS-XE-process-cpu-oper` | `cpu-usage/cpu-utilization/five-seconds` | ✅ [CPU utilization](get/cisco.md#cisco-cpu-utilization) |
| `Cisco-IOS-XE-memory-oper` | `memory-statistics` | ✅ [memory pools](get/cisco.md#cisco-memory-pools) |
| `Cisco-IOS-XE-environment-oper` | `environment-sensors` | ✅ [environment sensors](get/cisco.md#cisco-environment-sensors) |
| `Cisco-IOS-XE-ntp-oper` | `ntp-oper-data/ntp-status-info` | ✅ [NTP status](get/cisco.md#cisco-ntp-status) |
| `Cisco-IOS-XE-mdt-cfg` | `mdt-config-data/mdt-subscription[...]/base/stream` | ✅ [MDT config stream leaf](get/cisco.md#cisco-mdt-config-stream-leaf) |
| `Cisco-IOS-XE-mdt-capabilities-oper` | `mdt-capabilities-oper-data` | ✅ [on-change capabilities](subscribe/README.md#on-change-support) |
| `openconfig-interfaces` | `interfaces/interface[name=<if>]/state/oper-status` | ✅ [interface status](get/openconfig.md#openconfig-interface-operational-status) |
| `ietf-interfaces` | `interfaces-state/interface[name=<if>]/oper-status` | ✅ [interface status](get/ietf.md#ietf-interface-operational-status) |

### Set (all verified live and restored)

| Model | XPath | Ops | Recipe |
|---|---|---|---|
| `Cisco-IOS-XE-native` | `native/hostname` | Update, Replace | ✅ [hostname](set/cisco.md#cisco-hostname-updatereplace) |
| `Cisco-IOS-XE-native` | `native/vlan/.../vlan-list[id=<n>]/name` | Update, Replace | ✅ [VLAN name](set/cisco.md#cisco-vlan-name) |
| `Cisco-IOS-XE-native` | `native/interface/<Type>[name=<id>]/description` | Update, Replace, Delete | ✅ [interface description](set/cisco.md#cisco-interface-description) |
| `openconfig-interfaces` | `interfaces/interface[name=<if>]/config/enabled` | Update | ✅ [interface enable](set/openconfig.md#openconfig-interface-enable) |
| `openconfig-interfaces` | `interfaces/interface[name=<if>]/config/description` | Update, Replace, Delete | ✅ [interface description](set/openconfig.md#openconfig-interface-description) |
| `ietf-interfaces` | `interfaces/interface[name=<if>]/description` | Update, Replace, Delete | ✅ [interface description](set/ietf.md#ietf-interface-description) |

### Subscribe

| Model | XPath | Mode | Recipe |
|---|---|---|---|
| `openconfig-interfaces` | `interfaces/interface[name=<if>]/state/oper-status` | SAMPLE | ✅ [periodic sample](subscribe/openconfig.md#openconfig-interface-periodic-sample) |
| `ietf-interfaces` | `interfaces-state/interface[name=<if>]/oper-status` | SAMPLE | ✅ [periodic sample](subscribe/ietf.md#ietf-interface-periodic-sample) |
| `Cisco-IOS-XE-interfaces-oper` | `interfaces/interface[name=<if>]/admin-status` | ONCE | ✅ [snapshot](subscribe/cisco.md#cisco-interface-once-snapshot) |
| `Cisco-IOS-XE-interfaces-oper` | `interfaces/interface[name=<if>]/admin-status` | ON_CHANGE | ✅ [shut/no-shut events](subscribe/cisco.md#cisco-interface-on-change-shutno-shut) |
| `openconfig-interfaces` | `interfaces/interface[name=<if>]/state/cpu` | POLL | ✅ [CPU flag poll](subscribe/cisco.md#cisco-interface-cpu-flag-poll) |
| `Cisco-IOS-XE-vlan-oper` | `vlans/vlan[id=<n>]/name` | ON_CHANGE | ✅ [VLAN name change](subscribe/cisco.md#cisco-vlan-name-on-change) |
| `Cisco-IOS-XE-memory-oper` | `memory-statistics` | SAMPLE | ✅ [memory statistics](subscribe/cisco.md#cisco-memory-statistics-sample) |

### Techniques (across models)

| Technique | What it does | Recipe |
|---|---|---|
| Multi-path Get | Several leaves from different models in one Get | ✅ [get/cisco.md](get/cisco.md#multi-path-get) |
| Multi-path Subscribe | Several leaves streamed in one subscription | ✅ [subscribe/cisco.md](subscribe/cisco.md#multi-path-subscribe) |
| Encodings (`json_ietf` / `json` / `proto`) | Request a different wire encoding on Get or Subscribe | ✅ [recipe](get/cisco.md#encodings-proto-and-json) · [support matrix](docs/model-inventory.md#verified-operation--encoding-support) |

Placeholders: `<Type>` = native interface type (e.g. `TwoGigabitEthernet`);
`<if>` = full interface name/key; `<n>` = VLAN ID; `<id>` = list key. All
XPaths use the `rfc7951:` / `openconfig:` origin shown in each recipe.

## Reference material

- [docs/model-inventory.md](docs/model-inventory.md) — advertised models and
  which ones this guide uses.
- [docs/limitations.md](docs/limitations.md) — what did not work, timeouts, and
  gotchas.
- [docs/coverage.md](docs/coverage.md) — the full verification matrix.
- [docs/tls-and-credentials.md](docs/tls-and-credentials.md) — TLS, certificate
  handling, and credential hygiene.

## Device profile

Most examples were collected from one device. Treat the responses as reference
output, not a promise for every release or state.

- **Platform:** Catalyst 9300 stack
- **Software:** IOS XE 26.02.1
- **gNMI:** version `0.7.0`; encodings `JSON`, `JSON_IETF`, `PROTO`
- **Transport:** secure gNMI on port `9339`, username/password auth, self-signed
  `gnxi secure-init` certificate
- **Also verified on:** Catalyst 9300-24UX, IOS XE 26.1 — the memory
  subscription, multi-path Get/Subscribe, and PROTO-encoding examples (labeled
  in their recipes). Streaming behavior can differ by release.

## Connect and authenticate

Install [gNMIc](https://gnmic.openconfig.net/install/). Set your target and
username, enter the password at the prompt (so it stays out of shell history),
and define the `gnmi()` helper used by every recipe:

```bash
export GNMIC_ADDRESS="REPLACE_WITH_SWITCH_IP:9339"
export GNMIC_USERNAME="REPLACE_WITH_USERNAME"
read -rsp "gNMI password: " GNMIC_PASSWORD
printf '\n'
export GNMIC_PASSWORD

# Run once per Bash session, in the same terminal as the examples.
gnmi() {
  command gnmic \
    --address "$GNMIC_ADDRESS" \
    --username "$GNMIC_USERNAME" \
    --password "$GNMIC_PASSWORD" \
    --skip-verify \
    "$@"
}
```

- Replace the address and username. Keep port `9339` only if your device uses
  it.
- `--skip-verify` matches the self-signed `gnxi secure-init` lab setup. It
  encrypts the connection but does **not** verify the server identity, so use it
  only on a trusted lab network. To validate the certificate instead, see
  [docs/tls-and-credentials.md](docs/tls-and-credentials.md).
- Clear the password when finished: `unset GNMIC_PASSWORD`.

Check the connection and advertised models:

```bash
gnmi capabilities
```

## How to validate a response

The responses in this repo are sanitized captures from one C9300. When comparing
your output, ignore the source address, timestamps, subscription name, and any
`<REDACTED_*>` value. Check the **requested path**, the **value type**, and the
**state** instead.

| Command | What to check |
|---|---|
| `capabilities` | Your target answers and advertises the model and encoding the path needs. |
| `get` | The response contains the requested path; compare value type and state, not timestamps. |
| `set` | `results[].operation` and `results[].path` match the request — then Get to confirm the value. |
| `subscribe --mode once` | The initial state returns and the command exits. |
| `subscribe --stream-mode sample` | Initial update and sync arrive, then updates recur near the interval. |
| `subscribe --stream-mode on_change` | Initial state arrives, then an update only after the leaf changes. Check MDT capabilities first. |
| `subscribe --mode poll` | Initial state and sync arrive; each manual poll returns the current value. |

## Lab changes and safety

- Writes in this guide were limited to the device hostname (changed and
  restored) and one lab VLAN (`899`). Interface description and enable/disable
  Sets were exercised on an approved lab port and restored.
- The gNMI service port and TLS/authentication settings were **not** changed.
- **After any Set timeout, Get the path before retrying.** A timeout does not
  tell you whether the change applied. See
  [docs/limitations.md](docs/limitations.md).
- Do not copy a Set value blindly. Use an approved test object and verify the
  rollback path before any live change.

## References

- [Cisco IOS XE YANG Model Innovations](https://github.com/jeremycohoe/cisco-ios-xe-yang-model-innovations/)
  — background and examples for IOS XE programmability and YANG models.
- [Cisco IOS XE OpenAPI / Swagger model browser](https://ciscodevnet.github.io/cisco-ios-xe-openapi-swagger/)
  — browse the IOS XE models and their structure.
- [Device Data — sample payloads](https://ciscodevnet.github.io/cisco-ios-xe-openapi-swagger/device-data.html)
  — real captured payloads across multiple Catalyst platforms and access
  methods (MDT, RESTCONF, NETCONF, gNMI Get/Subscribe). Select an access method
  (e.g. **gNMI Sub**), a device (e.g. **C9300-STACK8-WAN**), and a flavor to see
  the paths that returned data, with a cross-device coverage matrix. Useful for
  discovering which paths and models are available before building a request.
- [gNMIc documentation](https://gnmic.openconfig.net/)
- [Cisco IOS XE 26.x gNMI Protocol guide](https://www.cisco.com/c/en/us/td/docs/ios-xml/ios/prog/configuration/26x/26x-programmability-cg/gnmi.html)

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE).
