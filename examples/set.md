# Set configuration

These commands demonstrate gNMI `SetRequest` updates and replacements. The
hostname Update and Replace were sent to the lab device and then rolled back;
the full sanitized responses are recorded below. VLAN 899 was created as
`GNMI-LAB` and remains unassigned. An initial VLAN request timed out, then IOS
XE reported a database lock; after the lock cleared, a retry succeeded. The
interface description remains a dry-run template.

For dry runs, gNMIc prints the request it would send; that does not validate
the target's YANG schema or prove that IOS XE accepts the path.

Set examples in this file use the Cisco native model because it was advertised
by the lab device. Set the target variables as described in the README, then
use a test device and save the current value before sending a real request.

## Change hostname with Update

`Update` writes the supplied leaf value. It is suitable for changing a
hostname:

```bash
NEW_HOSTNAME='gnmi-lab-switch'
HOSTNAME_PATH='rfc7951:/Cisco-IOS-XE-native:native/hostname'
gnmic set --dry-run \
  --update "${HOSTNAME_PATH}:::string:::${NEW_HOSTNAME}"
```

Local dry-run output:

```json
{
  "update": [
    {
      "path": "rfc7951:Cisco-IOS-XE-native:native/hostname",
      "val": "string_val:\"gnmi-lab-switch\""
    }
  ]
}
```

Before a live change, record the original hostname and a rollback command. A
hostname change can affect CLI prompts, monitoring, and inventory systems.

## Change hostname with Replace

`Replace` replaces the value at the specified leaf. At a single leaf it looks
similar to Update, but can have different effects when the path points to a
container or list. Keep replacements narrowly scoped:

```bash
gnmic set --dry-run \
  --replace "${HOSTNAME_PATH}:::string:::${NEW_HOSTNAME}"
```

Local dry-run output:

```json
{
  "replace": [
    {
      "path": "rfc7951:Cisco-IOS-XE-native:native/hostname",
      "val": "string_val:\"gnmi-lab-switch\""
    }
  ]
}
```

## Update or replace an interface description

Choose an interface that is safe for a lab change. First Get and save the
current description. This is a command template; validate the exact path and
interface name on the target:

```bash
IFACE='MEMBER/PORT'
NEW_DESCRIPTION='gnmi-lab-test'
DESC_PATH="rfc7951:/Cisco-IOS-XE-native:native/interface/GigabitEthernet[name=${IFACE}]/description"

gnmic set --dry-run \
  --update "${DESC_PATH}:::string:::${NEW_DESCRIPTION}"
gnmic set --dry-run \
  --replace "${DESC_PATH}:::string:::${NEW_DESCRIPTION}"
```

Local dry-run output (interface identifier redacted):

```json
{
  "update": [
    {
      "path": "rfc7951:Cisco-IOS-XE-native:native/interface/GigabitEthernet[name=<REDACTED_INTERFACE>]/description",
      "val": "string_val:\"gnmi-lab-test\""
    }
  ]
}
```

For an actual change, remove `--dry-run` only after reviewing the generated
request, saving the old value, and confirming the interface and rollback.
Restore the prior text with an Update to the same leaf. If the prior value was
absent, use a narrowly scoped Delete only after verifying IOS XE's behavior.

## Set a VLAN name

The lab Get exposed the `Cisco-IOS-XE-vlan:vlan-list` augmentation under
`native/vlan`. VLAN 899 was created with this leaf Update and verified by Get.
The command below uses an example VLAN ID for adaptation. Confirm that the ID
is unused and that the list key matches the target's model revision. Creating
a VLAN or changing its name may affect production traffic:

```bash
VLAN_ID='3999'
VLAN_NAME='GNMI-LAB'
VLAN_NAME_PATH="rfc7951:/Cisco-IOS-XE-native:native/vlan/Cisco-IOS-XE-vlan:vlan-list[id=${VLAN_ID}]/name"
gnmic set --dry-run \
  --update "${VLAN_NAME_PATH}:::string:::${VLAN_NAME}"
```

Local dry-run output (request rendering only; not a schema or device
acceptance check):

```json
{
  "update": [
    {
      "path": "rfc7951:Cisco-IOS-XE-native:native/vlan/Cisco-IOS-XE-vlan:vlan-list[id=3999]/name",
      "val": "string_val:\"GNMI-LAB\""
    }
  ]
}
```

For a beginner, start with one leaf update on a disposable lab object. VLAN
creation/deletion should be added only after the target's YANG path, current
state, and rollback have been confirmed.

## Verified live VLAN Update

Command:

```bash
gnmic set --timeout 45s --update \
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

VLAN 899 is left in configuration and has no ports assigned. Confirm local
change-management requirements before using this pattern outside a lab.

## Verified live hostname Update and Replace

The device's original hostname was read first and saved for rollback. The
following temporary values were used, then the original hostname was restored
and verified. No TLS or device security settings were changed. The device
address and original hostname are redacted in these full gNMIc response
envelopes; timestamps and response structure are retained.

### Update to `GNMIC-LAB`

Command:

```bash
gnmic set --update \
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
gnmic set --replace \
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
gnmic set --update \
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
