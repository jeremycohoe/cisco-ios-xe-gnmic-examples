# Subscribe examples

`subscribe` streams or polls telemetry. Run the
[connection setup](../README.md#connect-and-authenticate) in the same terminal
first. Stop streaming commands with `Ctrl+C`.

## Subscription modes shown here

| Mode | Flag | Behavior |
|---|---|---|
| Periodic sample | `--mode stream --stream-mode sample --sample-interval <n>s` | Initial update, sync response, then repeats near the interval |
| On-change | `--mode stream --stream-mode on_change` | Initial state, then an update only when the leaf changes |
| ONCE | `--mode once` | Returns the initial snapshot, then closes |
| POLL | `--mode poll` | Returns the current value on each manual poll (interactive) |

## Recipes by model

### Cisco (`Cisco-IOS-XE-*`) — [cisco.md](cisco.md)

| Goal | Mode |
|---|---|
| [Stream interface up/down events](cisco.md#cisco-interface-on-change-shutno-shut) | on-change |
| [Watch a VLAN name for changes](cisco.md#cisco-vlan-name-on-change) | on-change |
| [Snapshot interface admin status](cisco.md#cisco-interface-once-snapshot) | ONCE |
| [Poll an interface CPU flag](cisco.md#cisco-interface-cpu-flag-poll) | POLL |

### OpenConfig — [openconfig.md](openconfig.md)

| Goal | Mode |
|---|---|
| [Periodically sample interface status](openconfig.md#openconfig-interface-periodic-sample) | sample |

### IETF — [ietf.md](ietf.md)

| Goal | Mode |
|---|---|
| [Periodically sample interface status](ietf.md#ietf-interface-periodic-sample) | sample |

## On-change support

On-change works only where the device's `Cisco-IOS-XE-mdt-capabilities-oper`
model enables it. On this C9300, 48 of 53 running-datastore entries enable
on-change; enabled subtrees include `interfaces-ios-xe-oper:interfaces/interface`
and `vlan-ios-xe-oper:vlans`. OpenConfig general interface state/counters, IETF
`ietf-interfaces`, and `Cisco-IOS-XE-native` have no on-change override and fall
back to periodic sampling.

Read your device's on-change capability tree before relying on it:

```bash
gnmi get \
  --path 'rfc7951:/Cisco-IOS-XE-mdt-capabilities-oper:mdt-capabilities-oper-data' \
  --encoding json_ietf
```

Full sanitized capability response:
[captures/mdt-capabilities-get.json](../captures/mdt-capabilities-get.json).

For modes and paths that did not work on this device (memory periodic,
target-defined), see [docs/limitations.md](../docs/limitations.md#subscribe-operations).
