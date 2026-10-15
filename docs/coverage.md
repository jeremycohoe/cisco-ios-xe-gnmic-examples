# Operation and model coverage

This matrix is the audit trail for the lab C9300 (IOS XE 26.02.1). It records
what was verified, what was inconclusive, and what was not collected. The
example pages contain only the verified workflows; this page keeps the full
history, including results that did not work. See
[limitations.md](limitations.md) for the gotchas behind the inconclusive rows.

Live gNMI Capabilities advertised 486 modules; most are shared types,
deviations, or event models rather than independent data trees (see
[model-inventory.md](model-inventory.md)). Set applies only to writable
configuration data; operational-only models have no valid Set example.
Unsupported combinations are labeled as such, never represented by a fabricated
response.

## Verified on this device

| Operation | Model/path | Status | Recipe / evidence |
|---|---|---|---|
| Capabilities | gNMI Capabilities RPC | Verified | gNMI 0.7.0; JSON, JSON_IETF, PROTO; 486 models |
| Get | Cisco native hostname | Verified | [get/cisco.md](../get/cisco.md#cisco-hostname) |
| Get | Cisco native interface description | Verified | [get/cisco.md](../get/cisco.md#cisco-interface-description) |
| Get | Cisco native VLAN 899 entry | Verified and restored | [get/cisco.md](../get/cisco.md#cisco-vlan-configuration); active and portless |
| Get | Cisco VLAN-oper state and ports | Verified | [get/cisco.md](../get/cisco.md#cisco-vlan-operational-state) |
| Get | Cisco gNMI cfg `config/secure-port` | Verified | [get/cisco.md](../get/cisco.md#cisco-gnmi-secure-port); returned 9339 |
| Get | Cisco MDT cfg stream leaf | Verified | [get/cisco.md](../get/cisco.md#cisco-mdt-config-stream-leaf); returned `yang-push` |
| Get | Cisco process CPU `five-seconds` | Verified | [get/cisco.md](../get/cisco.md#cisco-cpu-utilization) |
| Get | Cisco memory operational | Verified post-reload | [get/cisco.md](../get/cisco.md#cisco-memory-pools); `captures/cisco-memory-oper-get.json` |
| Get | Cisco environment sensors | Verified post-reload | [get/cisco.md](../get/cisco.md#cisco-environment-sensors); `captures/cisco-environment-oper-get.json` |
| Get | Cisco NTP operational status | Verified post-reload | [get/cisco.md](../get/cisco.md#cisco-ntp-status); peer IPs redacted |
| Get | Cisco interface counters | Verified | [get/cisco.md](../get/cisco.md#cisco-interface-counters); `captures/interface-statistics-get.ndjson` |
| Get | Cisco/OpenConfig/IETF interface `oper-status` | Verified | [cisco](../get/cisco.md#cisco-interface-operational-status) / [openconfig](../get/openconfig.md) / [ietf](../get/ietf.md); same SVI, lower-layer-down |
| Get | Cisco MDT capabilities | Verified | 53 path entries; `captures/mdt-capabilities-get.json` |
| Set Update | Cisco native hostname | Verified live and rolled back | [set/cisco.md](../set/cisco.md#cisco-hostname-updatereplace) |
| Set Replace | Cisco native hostname | Verified live and rolled back | [set/cisco.md](../set/cisco.md#cisco-hostname-updatereplace) |
| Set Update | Cisco native VLAN name | Verified live and restored | [set/cisco.md](../set/cisco.md#cisco-vlan-name); rename/restore timed out then applied |
| Set Replace | Cisco native VLAN name | Verified live | [set/cisco.md](../set/cisco.md#cisco-vlan-name); `captures/vlan-name-replace.ndjson` |
| Set Update | OpenConfig interface `config/enabled` | Verified live and restored | [set/openconfig.md](../set/openconfig.md#openconfig-interface-enable) |
| Set Update/Replace/Delete | Cisco native interface description | Verified live and restored | [set/cisco.md](../set/cisco.md#cisco-interface-description); port 4/0/1; clean SetResponses; `captures/native-interface-description-set.ndjson` |
| Set Update/Replace/Delete | OpenConfig interface description | Verified live and restored | [set/openconfig.md](../set/openconfig.md#openconfig-interface-description); `captures/interface-descriptions-set.ndjson` |
| Set Delete | Cisco native VLAN (lab 898) | Verified live | [set/cisco.md](../set/cisco.md#cisco-vlan-delete); created+deleted VLAN 898; timed out but applied after lock; `captures/vlan-delete.ndjson` |
| Set Update/Replace/Delete | IETF interface description | Verified live and restored | [set/ietf.md](../set/ietf.md#ietf-interface-description); `captures/interface-descriptions-set.ndjson` |
| Subscribe SAMPLE | OpenConfig interface `oper-status` | Verified | [subscribe/openconfig.md](../subscribe/openconfig.md) |
| Subscribe SAMPLE | IETF `interfaces-state` `oper-status` | Verified | [subscribe/ietf.md](../subscribe/ietf.md); `captures/ietf-interfaces-sample.ndjson` |
| Subscribe ONCE | Cisco interfaces-oper `admin-status` | Verified | [subscribe/cisco.md](../subscribe/cisco.md#cisco-interface-once-snapshot); `captures/interface-oper-once.ndjson` |
| Subscribe ON_CHANGE | Cisco VLAN-oper VLAN 899 name | Verified | [subscribe/cisco.md](../subscribe/cisco.md#cisco-vlan-name-on-change); initial sync + change event; `captures/vlan-onchange-sync.ndjson`, `captures/vlan-onchange-event.ndjson` |
| Subscribe ON_CHANGE | Cisco interfaces-oper `admin-status` | Verified | [subscribe/cisco.md](../subscribe/cisco.md#cisco-interface-on-change-shutno-shut); `captures/interface-onchange-shut-no-shut.ndjson` |
| Subscribe POLL | OpenConfig interface `state/cpu` | Verified | [subscribe/cisco.md](../subscribe/cisco.md#cisco-interface-cpu-flag-poll); `captures/interfaces-oper-poll.ndjson` |
| Subscribe POLL | Cisco / OpenConfig / IETF interface `oper-status` | Verified | [cisco](../subscribe/cisco.md#cisco-interface-oper-status-poll) / [openconfig](../subscribe/openconfig.md#openconfig-interface-poll) / [ietf](../subscribe/ietf.md#ietf-interface-poll); `captures/poll-oper-status.ndjson` |
| Subscribe SAMPLE | Cisco memory-oper `memory-statistics` | Verified (C9300-24UX / 26.1) | [subscribe/cisco.md](../subscribe/cisco.md#cisco-memory-statistics-sample); `captures/memory-oper-sample.ndjson`; returned no values on the primary C9300 / 26.02.1 |
| Get | Multi-path (hostname + CPU + interface) | Verified (C9300-24UX / 26.1) | [get/cisco.md](../get/cisco.md#multi-path-get); `captures/multi-path-get.json` |
| Get | `json_ietf` / `json` / `proto` encodings | Verified (C9300-24UX / 26.1) | [get/cisco.md](../get/cisco.md#encodings-proto-and-json); same value in all three |
| Get | PROTO native form (prototext) | Verified (C9300 / 26.02.1) | [get/cisco.md](../get/cisco.md#encodings-proto-and-json); scalar TypedValue (uint_val/string_val); `captures/proto-get-prototext.txt` |
| Subscribe SAMPLE | PROTO encoding (CPU leaf) | Verified (C9300-24UX / 26.1) | [get/cisco.md](../get/cisco.md#encodings-proto-and-json); `captures/proto-subscribe.ndjson`; prefix + relative leaf |
| Subscribe SAMPLE | Multi-path (interface + CPU) | Verified (C9300-24UX / 26.1) | [subscribe/cisco.md](../subscribe/cisco.md#multi-path-subscribe); `captures/multi-path-subscribe.ndjson` |

## Not collected or inconclusive

These are tracked here but intentionally not shown as examples. See
[limitations.md](limitations.md).

| Operation | Model/path | Status | Reason |
|---|---|---|---|
| Set | gNMI cfg secure-port, MDT cfg, NTP config, other `-cfg` | Not collected | Need an exact approved path/value before any live Set |

## Subscription support from the device's MDT capability model

- The running datastore reports periodic support by default for config and
  state; system-level on-change is disabled by default.
- 48 of 53 per-node entries enable on-change for config and state; five entries
  explicitly disable it.
- The gNMI transport has no transport-specific overrides; effective on-change
  support comes from the ordered per-node list.
- On-change is advertised for the Cisco `yang-interfaces-oper` and
  `interfaces-ios-xe-oper` trees, VLAN operational data, and selected other
  Cisco operational trees. More-specific exceptions include interface
  `lag-aggregate-state` and `diffserv-info`.
- OpenConfig support is path-specific (interface neighbor paths advertised;
  general interface state and counters not). IETF `interfaces` and
  `Cisco-IOS-XE-native` have no on-change override and use the periodic default.
- Cisco IOS XE 26 documents streaming `SAMPLE` and `ON_CHANGE`. This C9300 also
  accepted `POLL` and `ONCE`.

## Device state note

The switch was reloaded during collection. Post-reload Gets succeeded and
confirmed the original hostname and VLAN 899 state. A later VLAN rename and
authorized restore both timed out; an immediate Get still showed the temporary
value, while a later Get confirmed the original `GNMI-LAB` value — the restore
applied without a retry. The gNMI port was not changed. After any Set timeout,
Get the path before deciding whether a retry is safe.
