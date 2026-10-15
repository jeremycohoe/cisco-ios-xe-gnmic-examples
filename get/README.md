# Get examples

`get` sends one request and returns a point-in-time snapshot. Pick a recipe by
model, copy the command, change only the highlighted fields, and compare your
response to the observed one.

Run the [connection setup](../README.md#connect-and-authenticate) in the same
terminal first so the `gnmi()` helper, address, and credentials are defined.

When comparing responses, ignore the source address, timestamps, and
site-specific values. Check the requested path, the value type, and the state.

## Recipes by model

### Cisco (`Cisco-IOS-XE-*`) — [cisco.md](cisco.md)

| Goal | Path root |
|---|---|
| [Read the hostname](cisco.md#cisco-hostname) | `Cisco-IOS-XE-native:native/hostname` |
| [Read an interface description](cisco.md#cisco-interface-description) | `Cisco-IOS-XE-native:native/interface` |
| [Read a VLAN configuration entry](cisco.md#cisco-vlan-configuration) | `Cisco-IOS-XE-native:native/vlan` |
| [Check VLAN operational state and ports](cisco.md#cisco-vlan-operational-state) | `Cisco-IOS-XE-vlan-oper:vlans` |
| [Read interface operational status](cisco.md#cisco-interface-operational-status) | `Cisco-IOS-XE-interfaces-oper:interfaces` |
| [Read interface counters](cisco.md#cisco-interface-counters) | `Cisco-IOS-XE-interfaces-oper:interfaces` |
| [Confirm the secure gNMI port](cisco.md#cisco-gnmi-secure-port) | `Cisco-IOS-XE-gnmi-cfg:gnmi-cfg-data` |
| [Sample CPU utilization](cisco.md#cisco-cpu-utilization) | `Cisco-IOS-XE-process-cpu-oper:cpu-usage` |
| [Read memory pools](cisco.md#cisco-memory-pools) | `Cisco-IOS-XE-memory-oper:memory-statistics` |
| [Read environment sensors](cisco.md#cisco-environment-sensors) | `Cisco-IOS-XE-environment-oper:environment-sensors` |
| [Read NTP status](cisco.md#cisco-ntp-status) | `Cisco-IOS-XE-ntp-oper:ntp-oper-data` |
| [Read one configured telemetry stream leaf](cisco.md#cisco-mdt-config-stream-leaf) | `Cisco-IOS-XE-mdt-cfg:mdt-config-data` |
| [Get several paths at once](cisco.md#multi-path-get) | multiple models |
| [Request PROTO / JSON encoding](cisco.md#encodings-proto-and-json) | any |

### OpenConfig — [openconfig.md](openconfig.md)

| Goal | Path root |
|---|---|
| [Read interface operational status](openconfig.md#openconfig-interface-operational-status) | `openconfig:/interfaces/interface/state` |

### IETF — [ietf.md](ietf.md)

| Goal | Path root |
|---|---|
| [Read interface operational status](ietf.md#ietf-interface-operational-status) | `ietf-interfaces:interfaces-state` |

All three interface models return the same operational status for the same
interface in different encodings; compare them side by side when porting a
workflow between models.
