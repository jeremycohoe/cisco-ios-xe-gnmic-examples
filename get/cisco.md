# Get: Cisco models

Recipes for `Cisco-IOS-XE-*` models. Run the
[connection setup](../README.md#connect-and-authenticate) first. Every response
below is a sanitized capture from the lab Catalyst 9300, IOS XE 26.02.1, secure
gNMI on port 9339. Compare the path and value type, not timestamps or
site-specific values.

---

## Cisco hostname

**Goal:** Read the device hostname.

```bash
gnmi get \
  --path 'rfc7951:/Cisco-IOS-XE-native:native/hostname' \
  --encoding json_ietf
```

**Observed response** (source and hostname redacted):

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

**Change these fields:** none. This path is fixed for any IOS XE device.

**Verify:** the response contains one update at
`.../native/hostname` with a string value.

**Status:** Verified on C9300 / IOS XE 26.02.1 / 2026-10-13.

---

## Cisco interface description

**Goal:** Read the configured description of one physical interface.

```bash
IFACE='1/0/1'
gnmi get \
  --path "rfc7951:/Cisco-IOS-XE-native:native/interface/GigabitEthernet[name=${IFACE}]/description" \
  --encoding json_ietf
```

**Observed response** (interface redacted; this port had no description, so the
value is empty):

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

**Change these fields:**
- `IFACE` — the member/port number, e.g. `1/0/1`.
- `GigabitEthernet` — the interface type as named in the native model (for
  example `TwoGigabitEthernet`, `TenGigE`). Confirm the exact type on your
  device.

**Verify:** the returned `Path` names the interface and leaf you requested.

**Status:** Verified on C9300 / IOS XE 26.02.1 / 2026-10-13.

---

## Cisco VLAN configuration

**Goal:** Read a single VLAN configuration list entry.

```bash
VLAN_ID='899'
gnmi get \
  --path "rfc7951:/Cisco-IOS-XE-native:native/vlan/Cisco-IOS-XE-vlan:vlan-list[id=${VLAN_ID}]" \
  --encoding json_ietf
```

**Observed response** (VLAN 899 was created as `GNMI-LAB` for this example):

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

**Change these fields:**
- `VLAN_ID` — the VLAN you want to read.

**Verify:** the returned `id` matches your request; `name` is the configured
VLAN name.

**Status:** Verified on C9300 / IOS XE 26.02.1 / 2026-10-13.

---

## Cisco VLAN operational state

**Goal:** Confirm whether a VLAN is active and read its port membership.

```bash
VLAN_ID='899'
gnmi get \
  --path "rfc7951:/Cisco-IOS-XE-vlan-oper:vlans/vlan[id=${VLAN_ID}]" \
  --encoding json_ietf
```

**Observed response:**

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

Read the port list separately:

```bash
VLAN_ID='899'
gnmi get \
  --path "rfc7951:/Cisco-IOS-XE-vlan-oper:vlans/vlan[id=${VLAN_ID}]/ports" \
  --encoding json_ietf
```

**Observed response** (empty list; no ports assigned):

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

**Change these fields:**
- `VLAN_ID` — the VLAN you want to inspect.

**Verify:** `status` is `active`; `ports` lists assigned members (empty here).

**Status:** Verified on C9300 / IOS XE 26.02.1 / 2026-10-13.

---

## Cisco interface operational status

**Goal:** Read the operational status of an interface (an SVI in this example).

```bash
VLAN_ID='899'
gnmi get \
  --path "rfc7951:/Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=Vlan${VLAN_ID}]/oper-status" \
  --encoding json_ietf
```

**Observed response** (SVI name redacted):

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

**Change these fields:**
- `Vlan${VLAN_ID}` — the full interface name. For a physical port use the key
  directly, e.g. `name=TwoGigabitEthernet4/0/1`.

**Verify:** the `oper-status` leaf returns a Cisco `if-oper-state-*` value.

**Status:** Verified on C9300 / IOS XE 26.02.1 / 2026-10-13.

---

## Cisco interface counters

**Goal:** Read packet and octet counters for one interface.

```bash
IFACE='TwoGigabitEthernet4/0/1'
gnmi get \
  --path "rfc7951:/Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=${IFACE}]/statistics" \
  --encoding json_ietf
```

**Observed response** (counters are point-in-time and will differ on your
device). Full capture:
[captures/interface-statistics-get.ndjson](../captures/interface-statistics-get.ndjson).

```json
[
  {
    "source": "<DEVICE_ADDRESS>:9339",
    "timestamp": 1792013813674940256,
    "time": "2026-10-14T14:36:53.674940256-07:00",
    "updates": [
      {
        "Path": "rfc7951:Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=TwoGigabitEthernet4/0/1]/statistics",
        "values": {
          "Cisco-IOS-XE-interfaces-oper:interfaces/interface/statistics": {
            "discontinuity-time": "2026-10-14T17:45:41.63+00:00",
            "in-octets": "0",
            "in-unicast-pkts": "0",
            "num-flaps": "1",
            "out-octets": 682769,
            "out-unicast-pkts": "8927",
            "rx-kbps": "0",
            "tx-kbps": "0"
          }
        }
      }
    ]
  }
]
```

> The response above is trimmed to the common counters; the full capture
> includes every leaf (errors, discards, broadcast/multicast, rates).

**Change these fields:**
- `IFACE` — the interface to read.

**Verify:** `statistics` returns octet and packet counters for the interface.

**Status:** Verified on C9300 / IOS XE 26.02.1 / 2026-10-14.

---

## Cisco gNMI secure port

**Goal:** Confirm the secure gNMI listener port without changing the service.

```bash
gnmi get \
  --path 'rfc7951:/Cisco-IOS-XE-gnmi-cfg:gnmi-cfg-data/config/secure-port' \
  --encoding json_ietf
```

**Observed response:**

```json
[
  {
    "source": "<DEVICE_ADDRESS>:9339",
    "timestamp": 1791953806580286544,
    "time": "2026-10-13T21:56:46.580286544-07:00",
    "updates": [
      {
        "Path": "rfc7951:Cisco-IOS-XE-gnmi-cfg:gnmi-cfg-data/config/secure-port",
        "values": {
          "Cisco-IOS-XE-gnmi-cfg:gnmi-cfg-data/config/secure-port": 9339
        }
      }
    ]
  }
]
```

**Change these fields:** none. Do not Set this or other service/TLS leaves over
the same session without a planned recovery path; a change can lock you out.

**Verify:** `secure-port` matches the port you connected on.

**Status:** Verified on C9300 / IOS XE 26.02.1 / 2026-10-13.

---

## Cisco CPU utilization

**Goal:** Read one five-second CPU utilization leaf instead of the full process
table.

```bash
gnmi get \
  --path 'rfc7951:/Cisco-IOS-XE-process-cpu-oper:cpu-usage/cpu-utilization/five-seconds' \
  --encoding json_ietf
```

**Observed response** (`5s` utilization was 4%):

```json
[
  {
    "source": "<DEVICE_ADDRESS>:9339",
    "timestamp": 1791953814816488622,
    "time": "2026-10-13T21:56:54.816488622-07:00",
    "updates": [
      {
        "Path": "rfc7951:Cisco-IOS-XE-process-cpu-oper:cpu-usage/cpu-utilization/five-seconds",
        "values": {
          "Cisco-IOS-XE-process-cpu-oper:cpu-usage/cpu-utilization/five-seconds": 4
        }
      }
    ]
  }
]
```

**Change these fields:** optionally swap `five-seconds` for `one-minute` or
`five-minutes`.

**Verify:** the leaf returns an integer percentage.

**Status:** Verified on C9300 / IOS XE 26.02.1 / 2026-10-13.

---

## Cisco memory pools

**Goal:** Read memory pool statistics.

```bash
gnmi get \
  --path 'rfc7951:/Cisco-IOS-XE-memory-oper:memory-statistics' \
  --encoding json_ietf
```

**Observed:** three pools (`Processor`, `reserve Processor`, `lsmpi_io`). Values
are bytes and change over time. Full sanitized response:
[captures/cisco-memory-oper-get.json](../captures/cisco-memory-oper-get.json).

<details>
<summary>Expand full response</summary>

```json
[
  {
    "source": "<DEVICE_ADDRESS>:9339",
    "timestamp": 1792000744103157166,
    "time": "2026-10-14T10:59:04.103157166-07:00",
    "updates": [
      {
        "Path": "rfc7951:Cisco-IOS-XE-memory-oper:memory-statistics",
        "values": {
          "Cisco-IOS-XE-memory-oper:memory-statistics": {
            "memory-statistic": [
              {
                "free-memory": "946637716",
                "highest-usage": "944947744",
                "lowest-usage": "943638332",
                "name": "Processor",
                "total-memory": "1326519612",
                "used-memory": "379881896"
              },
              {
                "free-memory": "102312",
                "highest-usage": "102312",
                "lowest-usage": "102312",
                "name": "reserve Processor",
                "total-memory": "102404",
                "used-memory": "92"
              },
              {
                "free-memory": "824",
                "highest-usage": "412",
                "lowest-usage": "824",
                "name": "lsmpi_io",
                "total-memory": "6295128",
                "used-memory": "6294304"
              }
            ]
          }
        }
      }
    ]
  }
]
```

</details>

**Change these fields:** none. Narrow to one pool by appending a list key if
your release supports it.

**Verify:** `memory-statistic` lists pools with byte counters.

**Status:** Verified on C9300 / IOS XE 26.02.1 / 2026-10-14 (post-reload).

---

## Cisco environment sensors

**Goal:** Read chassis environment sensors (temperature, power supply state).

```bash
gnmi get \
  --path 'rfc7951:/Cisco-IOS-XE-environment-oper:environment-sensors' \
  --encoding json_ietf
```

**Observed:** 64 sensor entries across the stack; temperature sensors reported
normal, absent power supplies appear as `NotExist`. This is a large response.
Full sanitized payload:
[captures/cisco-environment-oper-get.json](../captures/cisco-environment-oper-get.json).

<details>
<summary>Expand first sensor entries</summary>

```json
[
  {
    "source": "<DEVICE_ADDRESS>:9339",
    "timestamp": 1792000745188409544,
    "time": "2026-10-14T10:59:05.188409544-07:00",
    "updates": [
      {
        "Path": "rfc7951:Cisco-IOS-XE-environment-oper:environment-sensors",
        "values": {
          "Cisco-IOS-XE-environment-oper:environment-sensors": {
            "env-stat": {
              "cancl-snsrs": 0,
              "crit-alrm": 0,
              "major-alrm": 0,
              "minor-alrm": 0,
              "null-st-snsrs": 0
            },
            "environment-sensor": [
              {
                "current-reading": 32,
                "hi-major-thrsld": 56,
                "hi-minor-thrsld": 56,
                "high-critical-threshold": 56,
                "high-normal-threshold": 46,
                "location": "Switch 1",
                "low-critical-threshold": -10,
                "low-normal-threshold": 0,
                "name": "Inlet Temp Sensor",
                "reading": 32,
                "sensor-name": "temperature",
                "sensor-units": "celsius",
                "state": "Norm"
              }
            ]
          }
        }
      }
    ]
  }
]
```

</details>

**Change these fields:** none. The full tree is large; consider a narrower leaf
path if you only need one sensor.

**Verify:** `environment-sensor` lists entries with `reading` and `state`.

**Status:** Verified on C9300 / IOS XE 26.02.1 / 2026-10-14 (post-reload).

---

## Cisco NTP status

**Goal:** Read NTP synchronization status and peer summary.

```bash
gnmi get \
  --path 'rfc7951:/Cisco-IOS-XE-ntp-oper:ntp-oper-data/ntp-status-info' \
  --encoding json_ietf
```

**Observed:** no upstream sync (stratum 16); two associations rejected. Peer IP
addresses are redacted. Full sanitized response:
[captures/cisco-ntp-oper-get.json](../captures/cisco-ntp-oper-get.json).

**Change these fields:** none.

**Verify:** `ntp-status-info` returns status fields; peer entries appear under
the NTP oper data.

**Status:** Verified on C9300 / IOS XE 26.02.1 / 2026-10-14 (post-reload).

---

## Cisco MDT config stream leaf

**Goal:** Read one configured telemetry subscription leaf without exposing the
full telemetry configuration.

```bash
SUBSCRIPTION_ID='REPLACE_WITH_SUBSCRIPTION_ID'
gnmi get \
  --path "rfc7951:/Cisco-IOS-XE-mdt-cfg:mdt-config-data/mdt-subscription[subscription-id=${SUBSCRIPTION_ID}]/base/stream" \
  --encoding json_ietf
```

**Observed value:** `yang-push`. Subscription ID and address redacted. Full
sanitized response:
[captures/mdt-cfg-get-stream.json](../captures/mdt-cfg-get-stream.json).

```json
[
  {
    "source": "<DEVICE_ADDRESS>:9339",
    "timestamp": 1791999530894600204,
    "time": "2026-10-14T10:38:50.894600204-07:00",
    "updates": [
      {
        "Path": "rfc7951:Cisco-IOS-XE-mdt-cfg:mdt-config-data/mdt-subscription[subscription-id=<REDACTED_ID>]/base/stream",
        "values": {
          "Cisco-IOS-XE-mdt-cfg:mdt-config-data/mdt-subscription/base/stream": "yang-push"
        }
      }
    ]
  }
]
```

**Change these fields:**
- `SUBSCRIPTION_ID` — a configured subscription ID on your device. List them
  from the device CLI or a narrow Get before using this path.

**Caution:** a full-tree Get of `Cisco-IOS-XE-mdt-cfg` exposes collector
addresses and telemetry filters. Read only a specific leaf and redact it before
sharing.

**Verify:** the `stream` leaf returns the subscription's stream type.

**Status:** Verified on C9300 / IOS XE 26.02.1 / 2026-10-14.
