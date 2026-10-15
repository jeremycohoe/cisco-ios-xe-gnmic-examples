# Set: Cisco native configuration

Recipes for `Cisco-IOS-XE-native`. Run the
[connection setup](../README.md#connect-and-authenticate) first, then follow the
[pre-change checklist](README.md#before-you-change-anything). Responses are
sanitized captures from the lab Catalyst 9300, IOS XE 26.02.1. The device
address and original hostname are redacted; timestamps and structure are kept.

---

## Cisco hostname (Update/Replace)

**Goal:** Change the device hostname, then restore the original.

**Record the current value first:**

```bash
HOSTNAME_PATH='rfc7951:/Cisco-IOS-XE-native:native/hostname'
ORIGINAL_HOSTNAME="$(gnmi get --path "$HOSTNAME_PATH" --encoding json_ietf)"
# Inspect $ORIGINAL_HOSTNAME and note the current hostname before changing it.
```

**Command — Update to a new hostname:**

```bash
gnmi set --update \
  'rfc7951:/Cisco-IOS-XE-native:native/hostname:::string:::GNMIC-LAB'
```

**Observed response:**

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

**Command — Replace to a different hostname:**

```bash
gnmi set --replace \
  'rfc7951:/Cisco-IOS-XE-native:native/hostname:::string:::GNMIC-REPLACE-DEMO'
```

**Observed response:**

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

**Change these fields:**
- `GNMIC-LAB` / `GNMIC-REPLACE-DEMO` — your chosen hostname values.

**Verify:**

```bash
gnmi get --path 'rfc7951:/Cisco-IOS-XE-native:native/hostname' --encoding json_ietf
```

The verification Get after the Replace returned `GNMIC-REPLACE-DEMO`:

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

**Rollback** — restore the value saved before the first Set:

```bash
gnmi set --update \
  "${HOSTNAME_PATH}:::string:::${ORIGINAL_HOSTNAME}"
```

The rollback SetResponse reported `UPDATE`, and the final Get confirmed the
original hostname (shown redacted here):

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

> `ORIGINAL_HOSTNAME` above holds the full Get JSON. In practice, extract just
> the hostname string (for example with `jq`) before using it as the rollback
> value.

**Status:** Verified live and rolled back on C9300 / IOS XE 26.02.1 /
2026-10-13. Hostname is a mandatory leaf, so Delete is not appropriate.

---

## Cisco VLAN name

**Goal:** Create or name a VLAN, then exercise Replace with the same value.

> Writes here target lab VLAN **899** only. Pick a VLAN in your approved lab
> range; do not reuse a production VLAN ID.

**Command — Update the VLAN name:**

```bash
VLAN_ID='899'
gnmi set --timeout 45s --update \
  "rfc7951:/Cisco-IOS-XE-native:native/vlan/Cisco-IOS-XE-vlan:vlan-list[id=${VLAN_ID}]/name:::string:::GNMI-LAB"
```

**Observed response:**

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

**Change these fields:**
- `VLAN_ID` — your approved lab VLAN.
- `GNMI-LAB` — the VLAN name.

**Verify:**

```bash
VLAN_ID='899'
gnmi get \
  --path "rfc7951:/Cisco-IOS-XE-native:native/vlan/Cisco-IOS-XE-vlan:vlan-list[id=${VLAN_ID}]" \
  --encoding json_ietf
```

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

**Replace** (same value, to exercise the operation without changing the VLAN):

```bash
VLAN_ID='899'
gnmi set --replace \
  "rfc7951:/Cisco-IOS-XE-native:native/vlan/Cisco-IOS-XE-vlan:vlan-list[id=${VLAN_ID}]/name:::string:::GNMI-LAB"
```

The SetResponse reported `REPLACE` and an immediate Get returned `GNMI-LAB`.
Full pair: [captures/vlan-name-replace.ndjson](../captures/vlan-name-replace.ndjson).

**Rollback / cleanup:** this example *creates* a lab VLAN. To remove a lab VLAN
you created, see [Cisco VLAN Delete](#cisco-vlan-delete) below. Do **not** delete
VLAN 899 if other examples depend on it.

> The first live Update attempt timed out and a retry hit an IOS XE config-DB
> lock before the write finally applied. See
> [limitations](../docs/limitations.md#set-operations) for the full timeout and
> lock handling guidance.

A later Get confirmed the name persisted as `GNMI-LAB`:
[captures/vlan-name-final-get.ndjson](../captures/vlan-name-final-get.ndjson).

**Status:** Verified live on C9300 / IOS XE 26.02.1 / 2026-10-13. VLAN 899 is
active and portless.

---

## Cisco VLAN Delete

**Goal:** Delete a VLAN. Shown on a throwaway lab VLAN (`898`) so the documented
VLAN 899 is untouched.

> Deleting a VLAN removes it and any configuration under it. Only delete a lab
> VLAN you created and that nothing else depends on.

**Create a throwaway VLAN, then confirm it exists:**

```bash
VLAN_ID='898'
gnmi set --timeout 90s --update \
  "rfc7951:/Cisco-IOS-XE-native:native/vlan/Cisco-IOS-XE-vlan:vlan-list[id=${VLAN_ID}]/name:::string:::GNMI-DELETE-DEMO"
gnmi get --path "rfc7951:/Cisco-IOS-XE-native:native/vlan/Cisco-IOS-XE-vlan:vlan-list[id=${VLAN_ID}]" --encoding json_ietf
```

The Get confirmed the entry:

```json
{"source":"<DEVICE_ADDRESS>:9339","updates":[{"Path":"rfc7951:Cisco-IOS-XE-native:native/vlan/Cisco-IOS-XE-vlan:vlan-list[id=898]","values":{"Cisco-IOS-XE-native:native/vlan/Cisco-IOS-XE-vlan:vlan-list":{"id":898,"name":"GNMI-DELETE-DEMO"}}}]}
```

**Command — Delete the VLAN list entry:**

```bash
VLAN_ID='898'
gnmi set --timeout 90s --delete \
  "rfc7951:/Cisco-IOS-XE-native:native/vlan/Cisco-IOS-XE-vlan:vlan-list[id=${VLAN_ID}]"
```

**Verify it is gone** (the list entry returns empty):

```json
{"source":"<DEVICE_ADDRESS>:9339","updates":[{"Path":"rfc7951:Cisco-IOS-XE-native:native/vlan/Cisco-IOS-XE-vlan:vlan-list[id=898]","values":{"Cisco-IOS-XE-native:native/vlan/Cisco-IOS-XE-vlan:vlan-list":{}}}]}
```

Full lifecycle capture:
[captures/vlan-delete.ndjson](../captures/vlan-delete.ndjson).

**Change these fields:**
- `VLAN_ID` — the lab VLAN to delete.

> Like other native writes on this device, the Delete returned a client
> `DeadlineExceeded` and a retry hit a config-DB lock, but the Delete applied
> once the lock cleared — a later Get showed the entry empty. **Get the path to
> confirm** rather than trusting the timeout. See
> [limitations](../docs/limitations.md#set-operations).

**Status:** Verified live on C9300 / IOS XE 26.02.1 / 2026-10-14 (lab VLAN 898
created and deleted; VLAN 899 untouched).

---

## Cisco interface description

**Goal:** Set, replace, and clear a Cisco-native interface description, then
restore the original value.

The lab port `TwoGigabitEthernet4/0/1` is shown because the owner approved it;
substitute your own approved lab port. Note the interface type in the path
(`TwoGigabitEthernet`) must match your port.

**Record the current value first:**

```bash
IFACE='4/0/1'
DESC_PATH="rfc7951:/Cisco-IOS-XE-native:native/interface/TwoGigabitEthernet[name=${IFACE}]/description"
gnmi get --path "$DESC_PATH" --encoding json_ietf
```

On the lab port the initial description was empty.

**Command — Update, Replace, then Delete:**

```bash
IFACE='4/0/1'
TEST_DESCRIPTION='GNMI-LAB-TEST'
DESC_PATH="rfc7951:/Cisco-IOS-XE-native:native/interface/TwoGigabitEthernet[name=${IFACE}]/description"

gnmi set --update "${DESC_PATH}:::string:::${TEST_DESCRIPTION}"
gnmi set --replace "${DESC_PATH}:::string:::${TEST_DESCRIPTION}"
gnmi set --delete "${DESC_PATH}"
```

**Observed:** each operation returned a clean SetResponse (`UPDATE`, `REPLACE`,
`DELETE`) and each verification Get confirmed the value. Unlike the VLAN-name
write, these description writes applied without a timeout. Full sequence:
[captures/native-interface-description-set.ndjson](../captures/native-interface-description-set.ndjson).

```json
{"source":"<DEVICE_ADDRESS>:9339","time":"2026-10-14T14:33:29.035662123-07:00","results":[{"operation":"UPDATE","path":"rfc7951:Cisco-IOS-XE-native:native/interface/TwoGigabitEthernet[name=4/0/1]/description"}]}
{"source":"<DEVICE_ADDRESS>:9339","time":"2026-10-14T14:33:31.850199689-07:00","updates":[{"Path":"rfc7951:Cisco-IOS-XE-native:native/interface/TwoGigabitEthernet[name=4/0/1]/description","values":{"Cisco-IOS-XE-native:native/interface/TwoGigabitEthernet/description":"GNMI-LAB-TEST"}}]}
```

**Change these fields:**
- `IFACE` — your approved lab port number.
- `TwoGigabitEthernet` — the interface type as named in the native model.
- `TEST_DESCRIPTION` — the description text.

**Verify:** run the Get after each operation. Update and Replace show
`GNMI-LAB-TEST`; Delete returns the description to empty.

**Rollback:** the `Delete` restores the original empty value. If the port had a
description before you started, re-apply it with `--update` instead of `--delete`.

**Status:** Verified live and restored on C9300 / IOS XE 26.02.1 / 2026-10-14
(port 4/0/1).
