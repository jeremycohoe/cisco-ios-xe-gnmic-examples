# Advertised model inventory

The lab Catalyst 9300 (IOS XE 26.02.1) advertised **486 YANG modules** over
gNMI version `0.7.0`, with encodings `JSON`, `JSON_IETF`, and `PROTO`. Most of
those modules are shared types, deviations, or event models rather than
independent data trees.

The complete sanitized list of every advertised module and revision is kept as
machine-readable JSON, not duplicated here:

- [captures/capabilities-model-inventory.json](../captures/capabilities-model-inventory.json)

Read the live inventory from your own device with:

```bash
gnmi capabilities
```

Filter it down to the models used in this guide:

```bash
gnmi capabilities --format json |
  rg -A 1 '"name": "Cisco-IOS-XE-(gnmi-cfg|process-cpu-oper|mdt-cfg|mdt-capabilities-oper|memory-oper|environment-oper|ntp-oper)"'
```

Model revisions change between IOS XE releases. Always confirm the model and
encoding you need against your device's live Capabilities before relying on a
path below.

## Encodings

The lab devices advertised three encodings in Capabilities: **`JSON`**,
**`JSON_IETF`**, and **`PROTO`**.

- Every example in this guide uses **`--encoding json_ietf`** (RFC 7951). It is
  the most portable and human-readable choice for IOS XE and the one Cisco's
  gNMI guide documents for Get/Set.
- **`JSON`** is also accepted; the main difference is namespace qualification of
  keys (RFC 7951 prefixes).
- **`PROTO`** uses gNMI `TypedValue` scalars instead of a JSON blob. It is
  supported for Subscribe and is more compact on the wire; `gnmic` can request
  it with `--encoding proto`. PROTO and JSON examples are planned as a follow-up
  and are not yet captured here.

Confirm which encodings your device advertises with `gnmi capabilities`.

## Models used in this guide

| Model | Used for | Example |
|---|---|---|
| `Cisco-IOS-XE-native` | Hostname, interface description, VLAN configuration | [Get](../get/cisco.md), [Set](../set/cisco.md) |
| `Cisco-IOS-XE-interfaces-oper` | Interface operational status | [Get](../get/cisco.md), [Subscribe](../subscribe/cisco.md) |
| `Cisco-IOS-XE-vlan-oper` | VLAN status and port membership | [Get](../get/cisco.md), [Subscribe](../subscribe/cisco.md) |
| `Cisco-IOS-XE-gnmi-cfg` | gNMI server configuration (secure port) | [Get](../get/cisco.md) |
| `Cisco-IOS-XE-process-cpu-oper` | Five-second CPU utilization | [Get](../get/cisco.md) |
| `Cisco-IOS-XE-memory-oper` | Memory pools | [Get](../get/cisco.md) |
| `Cisco-IOS-XE-environment-oper` | Chassis temperature sensors | [Get](../get/cisco.md) |
| `Cisco-IOS-XE-ntp-oper` | NTP status and peers | [Get](../get/cisco.md) |
| `Cisco-IOS-XE-mdt-cfg` | Configured telemetry stream leaf | [Get](../get/cisco.md) |
| `Cisco-IOS-XE-mdt-capabilities-oper` | Which paths support on-change | [Subscribe](../subscribe/README.md#on-change-support) |
| `openconfig-interfaces` | Interface state, enable/disable, description | [Get](../get/openconfig.md), [Set](../set/openconfig.md), [Subscribe](../subscribe/openconfig.md) |
| `ietf-interfaces` | Interface state (`interfaces-state`), description | [Get](../get/ietf.md), [Set](../set/ietf.md), [Subscribe](../subscribe/ietf.md) |

## Notes and cautions

- The device advertises 11 Cisco modules ending in `-cfg`. Advertised does not
  mean a module is a safe or useful write target.
- `Cisco-IOS-XE-mdt-cfg` can expose collector addresses and subscription
  filters. Read only a specific leaf and redact it before sharing.
- `Cisco-IOS-XE-yang-interfaces-cfg` controls deprecated-model exposure and
  YANG AAA. It is **not** an alternate interface-description model.
- Cisco's IOS XE 26.x guide describes support for protocol version `0.4.0`,
  while this device reported `0.7.0`. Operations added to the gNMI spec after
  `0.7.0` (such as `union_replace`, added in `0.10.0`) are not available here.

## Discovering models and sample data

- [Cisco IOS XE OpenAPI / Swagger model browser](https://ciscodevnet.github.io/cisco-ios-xe-openapi-swagger/)
  — browse IOS XE models and their structure.
- [Device Data — sample payloads](https://ciscodevnet.github.io/cisco-ios-xe-openapi-swagger/device-data.html)
  — real captured payloads across multiple Catalyst platforms and access methods
  (MDT, RESTCONF, NETCONF, gNMI Get/Subscribe). Select **gNMI Sub** (or Get),
  pick a device such as **C9300-STACK8-WAN**, and browse the paths that returned
  data, with a cross-device coverage matrix. Use it to confirm a path and model
  are available on a platform before building a request.
- [Cisco IOS XE YANG Model Innovations](https://github.com/jeremycohoe/cisco-ios-xe-yang-model-innovations/)
  — background and examples for IOS XE programmability and YANG models.
