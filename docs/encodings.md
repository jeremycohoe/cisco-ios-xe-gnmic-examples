# Encoding command grid (every xpath × json_ietf / json / proto)

This page lists each example command in all three advertised encodings so you
can copy the exact `operation + xpath + encoding` combination you need.

**Verification is representative (not per-cell).** `--encoding` is a flag that is
independent of the path. It was verified live on a representative Get and
Subscribe path in all three encodings — see the
[support matrix](model-inventory.md#verified-operation--encoding-support). gNMIc
decodes every encoding to the same value, so responses are not re-captured per
encoding:

- **Get:** `json_ietf`, `json`, and `proto` return the same decoded value; the
  difference is only on the wire. To see the raw proto message (a scalar
  `TypedValue` such as `uint_val`/`string_val`), add `--format prototext` —
  captured in
  [captures/proto-get-prototext.txt](../captures/proto-get-prototext.txt).
- **Subscribe:** `json_ietf`/`json` look the same; **`proto`** returns a `prefix`
  plus a relative leaf path (see
  [captures/proto-subscribe.ndjson](../captures/proto-subscribe.ndjson)).
- **Set:** the value encoding is the typed `:::type:::` marker (e.g. `string`,
  `bool`), not `--encoding`. Only the typed (json_ietf-equivalent) form was
  exercised; `--encoding json|proto` is not applicable to these typed Sets.

All commands use the `gnmi()` helper from the
[README setup](../README.md#connect-and-authenticate). Keep the full
`rfc7951:/...` or `openconfig:/...` path prefix with `proto`. Change the example
interface names, VLAN IDs, and values for your device.

---

## GET

### Cisco hostname
```bash
gnmi get --path 'rfc7951:/Cisco-IOS-XE-native:native/hostname' --encoding json_ietf
gnmi get --path 'rfc7951:/Cisco-IOS-XE-native:native/hostname' --encoding json
gnmi get --path 'rfc7951:/Cisco-IOS-XE-native:native/hostname' --encoding proto
```

### Cisco interface description (native)
```bash
gnmi get --path 'rfc7951:/Cisco-IOS-XE-native:native/interface/GigabitEthernet[name=1/0/1]/description' --encoding json_ietf
gnmi get --path 'rfc7951:/Cisco-IOS-XE-native:native/interface/GigabitEthernet[name=1/0/1]/description' --encoding json
gnmi get --path 'rfc7951:/Cisco-IOS-XE-native:native/interface/GigabitEthernet[name=1/0/1]/description' --encoding proto
```

### Cisco VLAN configuration entry
```bash
gnmi get --path 'rfc7951:/Cisco-IOS-XE-native:native/vlan/Cisco-IOS-XE-vlan:vlan-list[id=899]' --encoding json_ietf
gnmi get --path 'rfc7951:/Cisco-IOS-XE-native:native/vlan/Cisco-IOS-XE-vlan:vlan-list[id=899]' --encoding json
gnmi get --path 'rfc7951:/Cisco-IOS-XE-native:native/vlan/Cisco-IOS-XE-vlan:vlan-list[id=899]' --encoding proto
```

### Cisco VLAN operational state
```bash
gnmi get --path 'rfc7951:/Cisco-IOS-XE-vlan-oper:vlans/vlan[id=899]' --encoding json_ietf
gnmi get --path 'rfc7951:/Cisco-IOS-XE-vlan-oper:vlans/vlan[id=899]' --encoding json
gnmi get --path 'rfc7951:/Cisco-IOS-XE-vlan-oper:vlans/vlan[id=899]' --encoding proto
```

### Cisco VLAN ports
```bash
gnmi get --path 'rfc7951:/Cisco-IOS-XE-vlan-oper:vlans/vlan[id=899]/ports' --encoding json_ietf
gnmi get --path 'rfc7951:/Cisco-IOS-XE-vlan-oper:vlans/vlan[id=899]/ports' --encoding json
gnmi get --path 'rfc7951:/Cisco-IOS-XE-vlan-oper:vlans/vlan[id=899]/ports' --encoding proto
```

### Cisco interface operational status
```bash
gnmi get --path 'rfc7951:/Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=Vlan899]/oper-status' --encoding json_ietf
gnmi get --path 'rfc7951:/Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=Vlan899]/oper-status' --encoding json
gnmi get --path 'rfc7951:/Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=Vlan899]/oper-status' --encoding proto
```

### Cisco interface counters
```bash
gnmi get --path 'rfc7951:/Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=TenGigabitEthernet1/0/1]/statistics' --encoding json_ietf
gnmi get --path 'rfc7951:/Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=TenGigabitEthernet1/0/1]/statistics' --encoding json
gnmi get --path 'rfc7951:/Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=TenGigabitEthernet1/0/1]/statistics' --encoding proto
```

### Cisco secure gNMI port
```bash
gnmi get --path 'rfc7951:/Cisco-IOS-XE-gnmi-cfg:gnmi-cfg-data/config/secure-port' --encoding json_ietf
gnmi get --path 'rfc7951:/Cisco-IOS-XE-gnmi-cfg:gnmi-cfg-data/config/secure-port' --encoding json
gnmi get --path 'rfc7951:/Cisco-IOS-XE-gnmi-cfg:gnmi-cfg-data/config/secure-port' --encoding proto
```

### Cisco CPU 5-second utilization
```bash
gnmi get --path 'rfc7951:/Cisco-IOS-XE-process-cpu-oper:cpu-usage/cpu-utilization/five-seconds' --encoding json_ietf
gnmi get --path 'rfc7951:/Cisco-IOS-XE-process-cpu-oper:cpu-usage/cpu-utilization/five-seconds' --encoding json
gnmi get --path 'rfc7951:/Cisco-IOS-XE-process-cpu-oper:cpu-usage/cpu-utilization/five-seconds' --encoding proto
```

### Cisco memory pools
```bash
gnmi get --path 'rfc7951:/Cisco-IOS-XE-memory-oper:memory-statistics' --encoding json_ietf
gnmi get --path 'rfc7951:/Cisco-IOS-XE-memory-oper:memory-statistics' --encoding json
gnmi get --path 'rfc7951:/Cisco-IOS-XE-memory-oper:memory-statistics' --encoding proto
```

### Cisco environment sensors
```bash
gnmi get --path 'rfc7951:/Cisco-IOS-XE-environment-oper:environment-sensors' --encoding json_ietf
gnmi get --path 'rfc7951:/Cisco-IOS-XE-environment-oper:environment-sensors' --encoding json
gnmi get --path 'rfc7951:/Cisco-IOS-XE-environment-oper:environment-sensors' --encoding proto
```

### Cisco NTP status
```bash
gnmi get --path 'rfc7951:/Cisco-IOS-XE-ntp-oper:ntp-oper-data/ntp-status-info' --encoding json_ietf
gnmi get --path 'rfc7951:/Cisco-IOS-XE-ntp-oper:ntp-oper-data/ntp-status-info' --encoding json
gnmi get --path 'rfc7951:/Cisco-IOS-XE-ntp-oper:ntp-oper-data/ntp-status-info' --encoding proto
```

### Cisco MDT config stream leaf
```bash
gnmi get --path 'rfc7951:/Cisco-IOS-XE-mdt-cfg:mdt-config-data/mdt-subscription[subscription-id=REPLACE_WITH_SUBSCRIPTION_ID]/base/stream' --encoding json_ietf
gnmi get --path 'rfc7951:/Cisco-IOS-XE-mdt-cfg:mdt-config-data/mdt-subscription[subscription-id=REPLACE_WITH_SUBSCRIPTION_ID]/base/stream' --encoding json
gnmi get --path 'rfc7951:/Cisco-IOS-XE-mdt-cfg:mdt-config-data/mdt-subscription[subscription-id=REPLACE_WITH_SUBSCRIPTION_ID]/base/stream' --encoding proto
```

### Cisco MDT on-change capabilities
```bash
gnmi get --path 'rfc7951:/Cisco-IOS-XE-mdt-capabilities-oper:mdt-capabilities-oper-data' --encoding json_ietf
gnmi get --path 'rfc7951:/Cisco-IOS-XE-mdt-capabilities-oper:mdt-capabilities-oper-data' --encoding json
gnmi get --path 'rfc7951:/Cisco-IOS-XE-mdt-capabilities-oper:mdt-capabilities-oper-data' --encoding proto
```

### OpenConfig interface operational status
```bash
gnmi get --path 'openconfig:/interfaces/interface[name=Vlan899]/state/oper-status' --encoding json_ietf
gnmi get --path 'openconfig:/interfaces/interface[name=Vlan899]/state/oper-status' --encoding json
gnmi get --path 'openconfig:/interfaces/interface[name=Vlan899]/state/oper-status' --encoding proto
```

### IETF interface operational status
```bash
gnmi get --path 'rfc7951:/ietf-interfaces:interfaces-state/interface[name=Vlan899]/oper-status' --encoding json_ietf
gnmi get --path 'rfc7951:/ietf-interfaces:interfaces-state/interface[name=Vlan899]/oper-status' --encoding json
gnmi get --path 'rfc7951:/ietf-interfaces:interfaces-state/interface[name=Vlan899]/oper-status' --encoding proto
```

---

## SUBSCRIBE

Stop streams with `Ctrl+C`. With `proto`, updates arrive as a `prefix` plus a
relative leaf path.

### OpenConfig interface oper-status (sample)
```bash
gnmi subscribe --path 'openconfig:/interfaces/interface[name=TenGigabitEthernet1/0/1]/state/oper-status' --mode stream --stream-mode sample --sample-interval 5s --encoding json_ietf
gnmi subscribe --path 'openconfig:/interfaces/interface[name=TenGigabitEthernet1/0/1]/state/oper-status' --mode stream --stream-mode sample --sample-interval 5s --encoding json
gnmi subscribe --path 'openconfig:/interfaces/interface[name=TenGigabitEthernet1/0/1]/state/oper-status' --mode stream --stream-mode sample --sample-interval 5s --encoding proto
```

### IETF interface oper-status (sample)
```bash
gnmi subscribe --path 'rfc7951:/ietf-interfaces:interfaces-state/interface[name=TenGigabitEthernet1/0/1]/oper-status' --mode stream --stream-mode sample --sample-interval 3s --encoding json_ietf
gnmi subscribe --path 'rfc7951:/ietf-interfaces:interfaces-state/interface[name=TenGigabitEthernet1/0/1]/oper-status' --mode stream --stream-mode sample --sample-interval 3s --encoding json
gnmi subscribe --path 'rfc7951:/ietf-interfaces:interfaces-state/interface[name=TenGigabitEthernet1/0/1]/oper-status' --mode stream --stream-mode sample --sample-interval 3s --encoding proto
```

### Cisco interface admin-status (ONCE)
```bash
gnmi subscribe --path 'rfc7951:/Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=TenGigabitEthernet1/0/1]/admin-status' --mode once --encoding json_ietf
gnmi subscribe --path 'rfc7951:/Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=TenGigabitEthernet1/0/1]/admin-status' --mode once --encoding json
gnmi subscribe --path 'rfc7951:/Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=TenGigabitEthernet1/0/1]/admin-status' --mode once --encoding proto
```

### Cisco interface admin-status (on-change)
```bash
gnmi subscribe --path 'rfc7951:/Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=TenGigabitEthernet1/0/1]/admin-status' --mode stream --stream-mode on_change --encoding json_ietf
gnmi subscribe --path 'rfc7951:/Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=TenGigabitEthernet1/0/1]/admin-status' --mode stream --stream-mode on_change --encoding json
gnmi subscribe --path 'rfc7951:/Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=TenGigabitEthernet1/0/1]/admin-status' --mode stream --stream-mode on_change --encoding proto
```

### Cisco VLAN name (on-change)
```bash
gnmi subscribe --path 'rfc7951:/Cisco-IOS-XE-vlan-oper:vlans/vlan[id=899]/name' --mode stream --stream-mode on_change --encoding json_ietf
gnmi subscribe --path 'rfc7951:/Cisco-IOS-XE-vlan-oper:vlans/vlan[id=899]/name' --mode stream --stream-mode on_change --encoding json
gnmi subscribe --path 'rfc7951:/Cisco-IOS-XE-vlan-oper:vlans/vlan[id=899]/name' --mode stream --stream-mode on_change --encoding proto
```

### OpenConfig interface CPU flag (POLL, interactive)
```bash
gnmi subscribe --path '/interfaces/interface[name=TenGigabitEthernet1/0/1]/state/cpu' --mode poll --encoding json_ietf
gnmi subscribe --path '/interfaces/interface[name=TenGigabitEthernet1/0/1]/state/cpu' --mode poll --encoding json
gnmi subscribe --path '/interfaces/interface[name=TenGigabitEthernet1/0/1]/state/cpu' --mode poll --encoding proto
```

### Cisco memory statistics (sample)
```bash
gnmi subscribe --path 'rfc7951:/Cisco-IOS-XE-memory-oper:memory-statistics' --mode stream --stream-mode sample --sample-interval 5s --encoding json_ietf
gnmi subscribe --path 'rfc7951:/Cisco-IOS-XE-memory-oper:memory-statistics' --mode stream --stream-mode sample --sample-interval 5s --encoding json
gnmi subscribe --path 'rfc7951:/Cisco-IOS-XE-memory-oper:memory-statistics' --mode stream --stream-mode sample --sample-interval 5s --encoding proto
```

---

## SET

For Set, the value encoding is the typed `:::type:::` marker, **not** `--encoding`.
Only the typed (json_ietf-equivalent) form was exercised; `json`/`proto` were not
separately run for these typed Sets. Always Get first, verify after, and keep the
rollback value. See [limitations.md](limitations.md) for Set-timeout handling.

### Cisco hostname (Update / Replace / rollback)
```bash
gnmi set --update  'rfc7951:/Cisco-IOS-XE-native:native/hostname:::string:::GNMIC-LAB'
gnmi set --replace 'rfc7951:/Cisco-IOS-XE-native:native/hostname:::string:::GNMIC-REPLACE-DEMO'
gnmi set --update  'rfc7951:/Cisco-IOS-XE-native:native/hostname:::string:::ORIGINAL_HOSTNAME'
```

### Cisco VLAN name (Update / Replace)
```bash
gnmi set --timeout 45s --update 'rfc7951:/Cisco-IOS-XE-native:native/vlan/Cisco-IOS-XE-vlan:vlan-list[id=899]/name:::string:::GNMI-LAB'
gnmi set --replace             'rfc7951:/Cisco-IOS-XE-native:native/vlan/Cisco-IOS-XE-vlan:vlan-list[id=899]/name:::string:::GNMI-LAB'
```

### Cisco native interface description (Update / Replace / Delete)
```bash
gnmi set --update  'rfc7951:/Cisco-IOS-XE-native:native/interface/TwoGigabitEthernet[name=4/0/1]/description:::string:::GNMI-LAB-TEST'
gnmi set --replace 'rfc7951:/Cisco-IOS-XE-native:native/interface/TwoGigabitEthernet[name=4/0/1]/description:::string:::GNMI-LAB-TEST'
gnmi set --delete  'rfc7951:/Cisco-IOS-XE-native:native/interface/TwoGigabitEthernet[name=4/0/1]/description'
```

### OpenConfig interface enable (shut / no-shut)
```bash
gnmi set --encoding json_ietf --update 'openconfig:/interfaces/interface[name=TwoGigabitEthernet4/0/1]/config/enabled:::bool:::false'
gnmi set --encoding json_ietf --update 'openconfig:/interfaces/interface[name=TwoGigabitEthernet4/0/1]/config/enabled:::bool:::true'
```

### OpenConfig interface description (Update / Replace / Delete)
```bash
gnmi set --update  'openconfig:/interfaces/interface[name=TwoGigabitEthernet4/0/1]/config/description:::string:::GNMI-LAB-TEST'
gnmi set --replace 'openconfig:/interfaces/interface[name=TwoGigabitEthernet4/0/1]/config/description:::string:::GNMI-LAB-TEST'
gnmi set --delete  'openconfig:/interfaces/interface[name=TwoGigabitEthernet4/0/1]/config/description'
```

### IETF interface description (Update / Replace / Delete)
```bash
gnmi set --update  'rfc7951:/ietf-interfaces:interfaces/interface[name=TwoGigabitEthernet4/0/1]/description:::string:::GNMI-LAB-TEST'
gnmi set --replace 'rfc7951:/ietf-interfaces:interfaces/interface[name=TwoGigabitEthernet4/0/1]/description:::string:::GNMI-LAB-TEST'
gnmi set --delete  'rfc7951:/ietf-interfaces:interfaces/interface[name=TwoGigabitEthernet4/0/1]/description'
```
