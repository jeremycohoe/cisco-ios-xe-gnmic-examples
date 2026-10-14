# Get data

`get` sends one request and returns a snapshot. These commands use the
`gnmi()` Bash helper from the repository README. Run its [connection
setup](../README.md#connect-to-the-switch) in the same terminal before copying
these commands. Compare the requested path and value type; source addresses,
timestamps, and actual device values can differ.

The gNMI service configuration, CPU, memory, environment sensor, and NTP
operational Gets are kept in the [primary README](../README.md#additional-cisco-operational-gets),
along with their exact responses. The large environment response is collapsed
in the README and available as a separate sanitized JSON capture.

## Cisco native hostname

```bash
gnmi get \
  --path 'rfc7951:/Cisco-IOS-XE-native:native/hostname' \
  --encoding json_ietf
```

**Verified.** Sanitized full response envelope (source and hostname redacted):

```json
[
  {
    "source": "<DEVICE_ADDRESS>:9339",
    "timestamp": 1791951992025736485,
    "time": "2026-10-13T21:26:32.025736485-07:00",
    "updates": [
      {
        "Path": "rfc7951:Cisco-IOS-XE-native:native/hostname",
        "values": {
          "Cisco-IOS-XE-native:native/hostname": "<REDACTED_HOSTNAME>"
        }
      }
    ]
  }
]
```

## Cisco native interface configuration

The Cisco native model groups physical interface types below `native/interface`.
Replace the interface member and port with the one you intend to inspect.

```bash
IFACE='MEMBER/PORT'
gnmi get \
  --path "rfc7951:/Cisco-IOS-XE-native:native/interface/GigabitEthernet[name=${IFACE}]/description" \
  --encoding json_ietf
```

**Verified.** Sanitized full response envelope. The interface identifier is
redacted; the observed description value was empty.

```json
[
  {
    "source": "<DEVICE_ADDRESS>:9339",
    "timestamp": 1791951992802115522,
    "time": "2026-10-13T21:26:32.802115522-07:00",
    "updates": [
      {
        "Path": "rfc7951:Cisco-IOS-XE-native:native/interface/GigabitEthernet[name=<REDACTED_INTERFACE>]/description",
        "values": {
          "Cisco-IOS-XE-native:native/interface/GigabitEthernet/description": ""
        }
      }
    ]
  }
]
```

## Cisco native VLAN configuration

VLAN 899 was created as `GNMI-LAB` for this example. The request reads only
that list entry:

```bash
VLAN_ID='899'
gnmi get \
  --path "rfc7951:/Cisco-IOS-XE-native:native/vlan/Cisco-IOS-XE-vlan:vlan-list[id=${VLAN_ID}]" \
  --encoding json_ietf
```

Verified full response:

```json
[
  {
    "source": "<DEVICE_ADDRESS>:9339",
    "timestamp": 1791952196248715370,
    "time": "2026-10-13T21:29:56.24871537-07:00",
    "updates": [
      {
        "Path": "rfc7951:Cisco-IOS-XE-native:native/vlan/Cisco-IOS-XE-vlan:vlan-list[id=899]",
        "values": {
          "Cisco-IOS-XE-native:native/vlan/Cisco-IOS-XE-vlan:vlan-list": {
            "id": 899,
            "name": "GNMI-LAB"
          }
        }
      }
    ]
  }
]
```

## Cisco VLAN operational state

The operational model reports whether VLAN 899 is active:

```bash
gnmi get \
  --path 'rfc7951:/Cisco-IOS-XE-vlan-oper:vlans/vlan[id=899]' \
  --encoding json_ietf
```

Verified full response:

```json
[
  {
    "source": "<DEVICE_ADDRESS>:9339",
    "timestamp": 1791952317884553482,
    "time": "2026-10-13T21:31:57.884553482-07:00",
    "updates": [
      {
        "Path": "rfc7951:Cisco-IOS-XE-vlan-oper:vlans/vlan[id=899]",
        "values": {
          "Cisco-IOS-XE-vlan-oper:vlans/vlan": {
            "id": 899,
            "name": "GNMI-LAB",
            "status": "active"
          }
        }
      }
    ]
  }
]
```

The operational VLAN response included `status: active`. Check its port list
separately to verify membership:

```bash
gnmi get \
  --path 'rfc7951:/Cisco-IOS-XE-vlan-oper:vlans/vlan[id=899]/ports' \
  --encoding json_ietf
```

Verified response (empty list; no ports assigned):

```json
[
  {
    "source": "<DEVICE_ADDRESS>:9339",
    "timestamp": 1791952338433699896,
    "time": "2026-10-13T21:32:18.433699896-07:00",
    "updates": [
      {
        "Path": "rfc7951:Cisco-IOS-XE-vlan-oper:vlans/vlan[id=899]/ports",
        "values": {
          "Cisco-IOS-XE-vlan-oper:vlans/vlan/ports": {}
        }
      }
    ]
  }
]
```

## Cisco interface-operational model

```bash
VLAN_ID='REPLACE_WITH_TEST_VLAN'
gnmi get \
  --path "rfc7951:/Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=Vlan${VLAN_ID}]/oper-status" \
  --encoding json_ietf
```

**Verified.** Sanitized full response envelope; the SVI name is redacted.

```json
[
  {
    "source": "<DEVICE_ADDRESS>:9339",
    "timestamp": 1791951993319796124,
    "time": "2026-10-13T21:26:33.319796124-07:00",
    "updates": [
      {
        "Path": "rfc7951:Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=<REDACTED_SVI>]/oper-status",
        "values": {
          "Cisco-IOS-XE-interfaces-oper:interfaces/interface/oper-status": "if-oper-state-lower-layer-down"
        }
      }
    ]
  }
]
```

## OpenConfig interfaces

```bash
VLAN_ID='REPLACE_WITH_TEST_VLAN'
gnmi get \
  --path "openconfig:/interfaces/interface[name=Vlan${VLAN_ID}]/state/oper-status" \
  --encoding json_ietf
```

**Verified.** Sanitized full response envelope; the SVI name is redacted.

```json
[
  {
    "source": "<DEVICE_ADDRESS>:9339",
    "timestamp": 1791951993579492470,
    "time": "2026-10-13T21:26:33.579492470-07:00",
    "updates": [
      {
        "Path": "openconfig:interfaces/interface[name=<REDACTED_SVI>]/state/oper-status",
        "values": {
          "interfaces/interface/state/oper-status": "LOWER_LAYER_DOWN"
        }
      }
    ]
  }
]
```

## IETF interfaces

This device's advertised IETF model uses the operational `interfaces-state`
tree for interface state:

```bash
VLAN_ID='REPLACE_WITH_TEST_VLAN'
gnmi get \
  --path "rfc7951:/ietf-interfaces:interfaces-state/interface[name=Vlan${VLAN_ID}]/oper-status" \
  --encoding json_ietf
```

**Verified.** Sanitized full response envelope; the SVI name is redacted.

```json
[
  {
    "source": "<DEVICE_ADDRESS>:9339",
    "timestamp": 1791951993985375150,
    "time": "2026-10-13T21:26:33.985375150-07:00",
    "updates": [
      {
        "Path": "rfc7951:ietf-interfaces:interfaces-state/interface[name=<REDACTED_SVI>]/oper-status",
        "values": {
          "ietf-interfaces:interfaces-state/interface/oper-status": "lower-layer-down"
        }
      }
    ]
  }
]
```

Redactions in these full response envelopes are limited to the device address,
hostname, physical interface name, and SVI name.
