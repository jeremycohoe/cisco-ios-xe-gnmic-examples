# Set examples

`set` changes configuration. Each recipe here was sent live to the lab Catalyst
9300 and verified with a follow-up Get. Every write recipe includes a
**Rollback** so you can restore the prior state.

Run the [connection setup](../README.md#connect-and-authenticate) in the same
terminal first.

## Before you change anything

1. **Get and record the current value first** so you can roll back.
2. Send the Set and read the `results[].operation` and `results[].path`.
3. **Run Get again to confirm the result.** A SetResponse alone does not prove
   the final state.
4. **If a Set times out, Get the path before retrying.** A timeout does not tell
   you whether the change applied. See
   [limitations](../docs/limitations.md#set-operations).

Core operations on this device are `Update`, `Replace`, and `Delete`. The device
advertises gNMI `0.7.0`, so `union_replace` (added in `0.10.0`) is not available.

## Recipes by model

### Cisco (`Cisco-IOS-XE-native`) — [cisco.md](cisco.md)

| Goal | Operations shown |
|---|---|
| [Change the hostname](cisco.md#cisco-hostname-updatereplace) | Update, Replace, rollback |
| [Create or name a VLAN](cisco.md#cisco-vlan-name) | Update, Replace |
| [Set an interface description](cisco.md#cisco-interface-description) | Update, Replace, Delete |

### OpenConfig — [openconfig.md](openconfig.md)

| Goal | Operations shown |
|---|---|
| [Shut / no-shut an interface](openconfig.md#openconfig-interface-enable) | Update, rollback |
| [Set an interface description](openconfig.md#openconfig-interface-description) | Update, Replace, Delete |

### IETF — [ietf.md](ietf.md)

| Goal | Operations shown |
|---|---|
| [Set an interface description](ietf.md#ietf-interface-description) | Update, Replace, Delete |

Operational models (`*-oper`, `interfaces-state`, CPU, memory, environment, NTP
state) are read-only and have no Set recipe. The full verification matrix is in
[docs/coverage.md](../docs/coverage.md).
