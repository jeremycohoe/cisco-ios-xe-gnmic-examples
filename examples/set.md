# Set configuration

Run the `gnmi()` connection setup in the [primary README](../README.md#connect-to-the-switch)
in the same terminal before using these commands. Get and record the current
value first. Compare the SetResponse operation and path, then run Get to
confirm the resulting value. Response timestamps and device values will vary.

This page records live Set requests. The hostname and VLAN-name Update/Replace,
OpenConfig interface description Update/Replace/Delete, IETF interface
description Update/Replace/Delete, and OpenConfig `config/enabled` Update were
sent to the lab C9300 and verified with Get. Full response envelopes are linked
below. The interface description tests restored the original empty values.

The VLAN rename/restore commands timed out, but a later Get confirmed the
authorized restore eventually completed and the name is `GNMI-LAB`. Do not
retry a Set timeout blindly; Get the path and wait for any configuration lock
to clear. The gNMI listener and port were not changed.

The target advertises gNMI 0.7.0. Core Set operations are Update, Replace, and
Delete. `UnionReplace` was added to the gNMI specification in 0.10.0 and is not
available on this target. This page avoids request-rendering-only Set examples.

## Operation and model coverage

| Model/path | Update | Replace | Delete | Live evidence or limitation |
|---|---|---|---|---|
| Cisco native hostname | Verified live | Verified live | Not appropriate: mandatory leaf | Temporary changes and rollback verified; see [hostname responses](../README.md#set-examples-and-full-responses) |
| Cisco native VLAN name | Verified live and restored | Verified live | Not collected | VLAN 899 is `GNMI-LAB`, active and portless; timeout/restore and same-value Replace are recorded below |
| Cisco native interface description | Not collected | Not collected | Not collected | No live request; not included in the verified set examples |
| OpenConfig interface `config/enabled` | Verified live and restored | Not collected | Not collected | Lab port state change captured in the primary README |
| OpenConfig interface `config/description` | Verified live and restored | Verified live and restored | Verified live and restored | Each Set followed by Get; original empty value restored |
| IETF interface `description` | Verified live and restored | Verified live and restored | Verified live and restored | Each Set followed by Get; original empty value restored |
| `*-oper`, `interfaces-state`, CPU, memory, environment, NTP state | N/A | N/A | N/A | Operational data is read-only |
| gNMI cfg secure-port | Not changed | Not changed | Not changed | Explicitly excluded; listener port remains unchanged |
| MDT cfg, NTP config, YANG interface config, other advertised config models | Not collected | Not collected | Not collected | Need an exact approved path/value before live Set collection |

## OpenConfig interface description

The initial Get returned an empty description. The following live sequence set
the temporary value, exercised Replace, then deleted the optional leaf to
restore the empty state. Get was run after each Set.

```bash
IFACE='TwoGigabitEthernet4/0/1'
TEST_DESCRIPTION='GNMI-LAB-TEST'
DESC_PATH="openconfig:/interfaces/interface[name=${IFACE}]/config/description"

gnmi set --update "${DESC_PATH}:::string:::${TEST_DESCRIPTION}"
gnmi set --replace "${DESC_PATH}:::string:::${TEST_DESCRIPTION}"
gnmi set --delete "${DESC_PATH}"
```

## IETF interface description

The IETF config tree had the same initial empty description. Update and Replace
set the temporary value; Delete restored the empty value. Get followed each
operation.

```bash
IFACE='TwoGigabitEthernet4/0/1'
TEST_DESCRIPTION='GNMI-LAB-TEST'
DESC_PATH="rfc7951:/ietf-interfaces:interfaces/interface[name=${IFACE}]/description"

gnmi set --update "${DESC_PATH}:::string:::${TEST_DESCRIPTION}"
gnmi set --replace "${DESC_PATH}:::string:::${TEST_DESCRIPTION}"
gnmi set --delete "${DESC_PATH}"
```

The complete sanitized SetResponse and verification Get sequence is in
[interface-descriptions-set.ndjson](../captures/interface-descriptions-set.ndjson).
Both model paths ended with an empty description. The selected test port is
retained because the owner approved it for this example.

## Verified live VLAN Update

Command:

```bash
gnmi set --timeout 45s --update \
  'rfc7951:/Cisco-IOS-XE-native:native/vlan/Cisco-IOS-XE-vlan:vlan-list[id=899]/name:::string:::GNMI-LAB'
```

The first attempt timed out. A retry while the device still held the config
database lock returned a lock error. After the lock cleared, this retry
succeeded:

First-attempt stderr (source redacted):

```text
target "<DEVICE_ADDRESS>:9339" set request failed: target "<DEVICE_ADDRESS>:9339" SetRequest failed: rpc error: code = DeadlineExceeded desc = context deadline exceeded
Error: one or more requests failed
```

The immediate Get showed the VLAN list entry was still empty. The next Set
reported this sanitized lock detail:

```text
rpc error: code = Unavailable desc = Database is locked for writing. Please retry: the configuration database is locked by session <SESSION> <USER> tcp (gnmi from <CLIENT_ADDRESS>) on since 2026-10-13 21:21:24
IOS-XE YANG Infrastructure. Additional info: locked
```

After waiting for the gNMI session lock to clear, the same Set succeeded. If a
Set times out, Get the target path before retrying; do not assume the request
failed or succeeded from the timeout alone.

```json
{
  "source": "<DEVICE_ADDRESS>:9339",
  "timestamp": 1791952157458173250,
  "time": "2026-10-13T21:29:17.45817325-07:00",
  "results": [
    {
      "operation": "UPDATE",
      "path": "rfc7951:Cisco-IOS-XE-native:native/vlan/Cisco-IOS-XE-vlan:vlan-list[id=899]/name"
    }
  ]
}
```

Verification Get:

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

Immediately after the Set, Gets showed VLAN 899 active with no ports assigned.
Post-reload Gets confirmed it persisted with the name `GNMI-LAB`. On
2026-10-14 a temporary rename request timed out; later Get returned
`GNMI-LAB-EVENT`. The restore request also timed out and its immediate Get
still showed that temporary value. A later Get at 12:55 confirmed that the
restore eventually applied and the name was again `GNMI-LAB`. If a Set times
out, Get the path before retrying; a delayed application is possible.

### VLAN Replace and Delete

Replace was sent on the existing VLAN-name leaf with the current value
`GNMI-LAB`. The SetResponse reported `REPLACE`, and an immediate Get returned
`GNMI-LAB`. This exercised the operation without changing the VLAN. See the
[sanitized response pair](../captures/vlan-name-replace.ndjson). Delete was
not sent because it would remove VLAN 899.

For this device, `UnionReplace` is not a usable demonstrated operation. The
device advertises gNMI 0.7.0; the gNMI specification added `union_replace` in
version 0.10.0. Do not count gNMIc's presence of a similarly named local flag
as server support.

## Verified live hostname Update and Replace

The device's original hostname was read first and saved for rollback. The
following temporary values were used, then the original hostname was restored
and verified. No TLS or device security settings were changed. The device
address and original hostname are redacted in these full gNMIc response
envelopes; timestamps and response structure are retained.

### Update to `GNMIC-LAB`

Command:

```bash
gnmi set --update \
  'rfc7951:/Cisco-IOS-XE-native:native/hostname:::string:::GNMIC-LAB'
```

Response:

```json
{
  "source": "<DEVICE_ADDRESS>:9339",
  "timestamp": 1791951608381362064,
  "time": "2026-10-13T21:20:08.381362064-07:00",
  "results": [
    {
      "operation": "UPDATE",
      "path": "rfc7951:Cisco-IOS-XE-native:native/hostname"
    }
  ]
}
```

Verification Get returned `GNMIC-LAB`:

```json
[
  {
    "source": "<DEVICE_ADDRESS>:9339",
    "timestamp": 1791951625365063926,
    "time": "2026-10-13T21:20:25.365063926-07:00",
    "updates": [
      {
        "Path": "rfc7951:Cisco-IOS-XE-native:native/hostname",
        "values": {
          "Cisco-IOS-XE-native:native/hostname": "GNMIC-LAB"
        }
      }
    ]
  }
]
```

### Replace to `GNMIC-REPLACE-DEMO`

Command:

```bash
gnmi set --replace \
  'rfc7951:/Cisco-IOS-XE-native:native/hostname:::string:::GNMIC-REPLACE-DEMO'
```

Response:

```json
{
  "source": "<DEVICE_ADDRESS>:9339",
  "timestamp": 1791951642765311780,
  "time": "2026-10-13T21:20:42.765311780-07:00",
  "results": [
    {
      "operation": "REPLACE",
      "path": "rfc7951:Cisco-IOS-XE-native:native/hostname"
    }
  ]
}
```

Verification Get returned `GNMIC-REPLACE-DEMO`:

```json
[
  {
    "source": "<DEVICE_ADDRESS>:9339",
    "timestamp": 1791951644497529790,
    "time": "2026-10-13T21:20:44.497529790-07:00",
    "updates": [
      {
        "Path": "rfc7951:Cisco-IOS-XE-native:native/hostname",
        "values": {
          "Cisco-IOS-XE-native:native/hostname": "GNMIC-REPLACE-DEMO"
        }
      }
    ]
  }
]
```

The final Update restored the original hostname. Its Get response confirmed
the original value; that response is represented as `<REDACTED_HOSTNAME>`
rather than publishing the site-specific hostname. Both rollback operations
succeeded.

Rollback command, using the value saved before the first Set:

```bash
gnmi set --update \
  "${HOSTNAME_PATH}:::string:::${ORIGINAL_HOSTNAME}"
```

Rollback SetResponse:

```json
{
  "source": "<DEVICE_ADDRESS>:9339",
  "timestamp": 1791951661491447751,
  "time": "2026-10-13T21:21:01.491447751-07:00",
  "results": [
    {
      "operation": "UPDATE",
      "path": "rfc7951:Cisco-IOS-XE-native:native/hostname"
    }
  ]
}
```

Final verification Get:

```json
[
  {
    "source": "<DEVICE_ADDRESS>:9339",
    "timestamp": 1791951663319945482,
    "time": "2026-10-13T21:21:03.319945482-07:00",
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
