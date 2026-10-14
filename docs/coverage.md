# Operation and model coverage

This matrix is the working checklist for the lab C9300. Live gNMI Capabilities
advertised 486 model modules, but many are shared types, deviations, or event
models rather than independent data trees. The README will include the complete
advertised-model inventory and examples will be recorded per data-bearing
model/path. Set applies only to writable configuration data; operational-only
models have no valid Set example. Unsupported combinations will be identified
as such rather than represented by a fabricated successful response.

## Verified on this device

| Operation | Model/path | Status | Evidence |
|---|---|---|---|
| Capabilities | gNMI Capabilities RPC | Verified | gNMI 0.7.0; JSON, JSON_IETF, PROTO; 486 models |
| Get | Cisco native hostname | Verified | Sanitized response in README; original value redacted |
| Get | Cisco native interface description | Verified | Narrow leaf response; interface identifier redacted |
| Get | Cisco native VLAN 899 entry | Verified and restored | After delayed timeout handling, final Get returned `GNMI-LAB`; active and portless |
| Get | Cisco VLAN-oper state and ports | Verified | VLAN active, port list empty |
| Get | Cisco gNMI cfg `config/secure-port` | Verified | Returned secure listener port 9339 |
| Get | Cisco MDT cfg `mdt-subscription/.../base/stream` | Verified | Returned `yang-push`; only one leaf collected; receiver details excluded |
| Get | Cisco process CPU `cpu-utilization/five-seconds` | Verified | Narrow operational leaf response in README |
| Get | Cisco memory operational | Verified post-reload | Three memory pools; full sanitized response in README and `captures/cisco-memory-oper-get.json` |
| Get | Cisco environment sensors | Verified post-reload | 64 sensor rows; full sanitized response is collapsed in README and saved as JSON |
| Get | Cisco NTP operational status | Verified post-reload | Two peers; peer IPs redacted in full response |
| Get | Post-reload device status | Verified | Original hostname restored; VLAN 899 persisted as active `GNMI-LAB`; final Get at 12:55 confirmed `GNMI-LAB` after a timed-out rename/restore |
| Get | Cisco, OpenConfig, IETF interface `oper-status` | Verified | Same SVI returned lower-layer-down in each model |
| Get | Cisco MDT capabilities | Verified | 53 running-datastore path entries; sanitized full response in `captures/mdt-capabilities-get.json` |
| Set Update | Cisco native hostname | Verified live and rolled back | SetResponse and Gets recorded in README |
| Set Replace | Cisco native hostname | Verified live and rolled back | SetResponse and Gets recorded in README |
| Set Update | Cisco native VLAN name | Verified live and restored | VLAN 899 created as `GNMI-LAB`; rename and restore timed out, but later Get confirmed `GNMI-LAB` again |
| Set Replace | Cisco native VLAN name | Verified live | Replaced the current name with the same `GNMI-LAB` value; Get confirmed it remained unchanged; transcript in `captures/vlan-name-replace.ndjson` |
| Set Update | OpenConfig interface `config/enabled` | Verified live and restored | No-transceiver port briefly enabled, then restored to `false`; Gets showed `UP` then `DOWN` |
| Set Update/Replace/Delete | OpenConfig interface description | Verified live and restored | Port 4/0/1; each operation followed by Get; original empty value restored; full transcript in `captures/interface-descriptions-set.ndjson` |
| Set Update/Replace/Delete | IETF interface description | Verified live and restored | Port 4/0/1; each operation followed by Get; original empty value restored; full transcript in `captures/interface-descriptions-set.ndjson` |
| Subscribe SAMPLE | OpenConfig interface `oper-status` | Verified | 5-second sample, initial update, sync and repeated samples |
| Subscribe SAMPLE | IETF `interfaces-state/interface/oper-status` | Verified | Keyed port 4/0/1, 3-second sample, initial update, sync, repeated `up`; capture in README |
| Subscribe SAMPLE | Cisco memory-oper | No data values | Timestamp-only notifications and sync; see `captures/memory-oper-sample.ndjson` |
| Subscribe ONCE | Cisco interfaces-oper `admin-status` | Verified | Keyed port 4/0/1 returned initial `if-state-up`, timestamp-only response, then completed; capture in `captures/interface-oper-once.ndjson` |
| Subscribe TARGET_DEFINED | Cisco interfaces-oper `admin-status` | Inconclusive | No values during ~10 seconds; interrupted. Not enough evidence to call unsupported |
| Subscribe ON_CHANGE | Cisco VLAN-oper VLAN 899 name | Initial sync verified | Initial update and sync captured; event Set timed out and hit database lock |
| Subscribe ON_CHANGE | Cisco interfaces-oper `admin-status` | Verified | Connected port 4/0/1 produced initial `if-state-up`, then `if-state-down` and restored `if-state-up` events; final Get verified enabled/admin/oper UP |
| Subscribe POLL | Cisco interfaces-oper `admin-status` | Verified | Initial update and manually requested poll both returned `if-state-down` on a redacted test interface |
| Subscribe POLL | OpenConfig interface `state/cpu` | Verified | User-supplied unkeyed path returned all interface flags; keyed port 4/0/1 returned `false` on initial and manual poll; broad output not retained |

## Subscription support from the device's MDT capability model

- The running datastore reports periodic support by default for config and
  state. System-level on-change is disabled by default.
- 48 of 53 per-node entries enable on-change for config and state; five entries
  explicitly disable it.
- The gNMI transport has no transport-specific overrides. Its effective
  on-change support comes from the ordered per-node list.
- On-change is advertised for the Cisco `yang-interfaces-oper` and
  `interfaces-ios-xe-oper` trees, VLAN operational data, and selected other
  Cisco operational trees. More-specific exceptions include interface
  `lag-aggregate-state` and `diffserv-info`.
- OpenConfig support is path-specific. Interface neighbor paths are advertised;
  general interface state and counters are not. IETF `interfaces` and
  `Cisco-IOS-XE-native` have no on-change path overrides and therefore use the
  periodic default.
- Cisco IOS XE 26 documents streaming `SAMPLE` and `ON_CHANGE`. This C9300
  accepted `POLL` and `ONCE`; target-defined returned no values in a ~10-second
  trial and remains inconclusive.

## Remaining collection checklist

| Model family | Get | Set Update/Replace/Delete | Periodic | On-change |
|---|---|---|---|---|
| Cisco native configuration | Hostname, interface description, and VLAN Gets | Hostname Update/Replace live; VLAN Update/Replace live; native interface description and VLAN Delete not collected | Native config subscription not enabled by MDT; no config-change stream claimed | Capability says no on-change override; not demonstrated |
| Cisco native interfaces and Cisco interfaces-oper | Interface description and status verified | OpenConfig `config/enabled` live Update verified/restored; OpenConfig/IETF description Update/Replace/Delete live and restored; Cisco native description not collected | Cisco admin-status POLL and OpenConfig `state/cpu` POLL verified; IETF operational status periodic verified | Verified on connected port 4/0/1: shut/no-shut produced down/up events; no-transceiver test port emitted no follow-up event |
| Cisco `yang-interfaces-oper` | Collect representative state | Read-only / no Set | Capture periodic | Capability-positive path |
| OpenConfig interfaces | Get and periodic verified | `config/enabled` Update verified and restored; description Update/Replace/Delete verified and restored on port 4/0/1 | Keyed CPU-flag POLL verified; general oper-status periodic verified | Not advertised for general interface state; no example as supported |
| IETF interfaces | Get and keyed periodic verified | Description Update/Replace/Delete verified and restored on port 4/0/1 | Keyed oper-status periodic verified | No path override; document periodic default, no on-change claim |
| Cisco VLAN config / VLAN-oper | Get and Update verified | Update/Replace live; Delete not collected because it would remove the lab VLAN | Capability-supported; not collected in this pass | Initial sync verified; event attempt blocked by IOS XE config DB lock; VLAN name is restored to `GNMI-LAB` |
| Cisco gNMI cfg | Get verified | No live write; service/TLS/authentication changes excluded | MDT capability based; no new stream claimed | MDT capability based; no config subscription claimed |
| Cisco MDT cfg | One narrow leaf Get verified | No live write; changes may alter active telemetry subscriptions | MDT capability based; no new stream claimed | MDT capability based; avoid broad potentially sensitive config |
| Other useful advertised operational models | Memory, environment, NTP, and CPU examples captured | Not applicable for read-only nodes | Memory sample returned no data values; other model samples remain to be tried | Only where the MDT path list enables it |

The switch was reloaded during collection. Post-reload gNMI Gets succeeded and
confirmed the original hostname and VLAN 899 state at that time. A later VLAN
rename and authorized restore request both timed out; an immediate Get still
showed `GNMI-LAB-EVENT`, while a later Get at 12:55 confirmed the original
`GNMI-LAB` value. The restore eventually applied without a retry. The gNMI
port was not changed. Follow the repository instructions: after any Set
timeout, Get the path before deciding whether a retry is safe.
