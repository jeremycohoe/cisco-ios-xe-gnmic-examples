# Subscribe to telemetry

These examples use the `gnmi()` Bash helper in the primary README. Run its
[connection setup](../README.md#connect-to-the-switch) in the same terminal
before copying these commands. Compare the path and mode behavior; timestamps,
subscription names, and live values may differ. Full
response transcripts and output summaries are in the
[README Subscribe section](../README.md#subscribe-examples-and-full-responses).
Stop streaming commands with `Ctrl+C`.

## Periodic sample

Verified against the C9300 with OpenConfig interface state. The device returned
an initial update, sync response, and repeated five-second samples:

```bash
VLAN_ID='REPLACE_WITH_TEST_VLAN'
gnmi subscribe \
  --path "openconfig:/interfaces/interface[name=Vlan${VLAN_ID}]/state/oper-status" \
  --mode stream \
  --stream-mode sample \
  --sample-interval 5s
```

The large response is collapsed in the primary README. A Cisco memory
operational Get succeeded, but a periodic subscription to the same model
produced timestamp-only notifications with no values; see the
[sanitized output](../captures/memory-oper-sample.ndjson).

### IETF interfaces periodic sample

Verified for the keyed interface oper-status leaf. This was a 3-second
sample; output included the initial `up`, sync response, and repeated `up`
updates. Full sanitized output:
[ietf-interfaces-sample.ndjson](../captures/ietf-interfaces-sample.ndjson).

```bash
IFACE='MEMBER/PORT'
gnmi subscribe \
  --path "rfc7951:/ietf-interfaces:interfaces-state/interface[name=${IFACE}]/oper-status" \
  --mode stream \
  --stream-mode sample \
  --sample-interval 3s
```

The IETF `interfaces-state` tree is operational data. It is appropriate for
Get and Subscribe, not Set.

## ONCE

`ONCE` requests the initial snapshot and then closes the subscription. This
was observed on the Cisco interface-oper admin-status leaf; the device
returned `if-state-up` and a timestamp-only response. The capture has no
`sync-response` object in this CLI transcript.

```bash
IFACE='TwoGigabitEthernet4/0/1'
gnmi subscribe \
  --path "rfc7951:/Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=${IFACE}]/admin-status" \
  --mode once
```

See [interface-oper-once.ndjson](../captures/interface-oper-once.ndjson).

## Target-defined stream

The command below was tried against the same Cisco interface-oper leaf. No
values arrived during the roughly 10-second observation window; it was
interrupted. This does not prove the target-defined mode is unsupported.

```bash
IFACE='TwoGigabitEthernet4/0/1'
gnmi subscribe \
  --path "rfc7951:/Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=${IFACE}]/admin-status" \
  --mode stream \
  --stream-mode target-defined
```

## On-change: VLAN name

The C9300's MDT capability response permits on-change below
`vlan-ios-xe-oper:vlans`. This subscription returned an initial VLAN-name
update and sync response:

```bash
gnmi subscribe \
  --path 'rfc7951:/Cisco-IOS-XE-vlan-oper:vlans/vlan[id=899]/name' \
  --mode stream \
  --stream-mode on_change
```

A later Set to trigger a changed name timed out, and IOS XE reported a
configuration database lock. A verification Get at that time confirmed VLAN
899 remained `GNMI-LAB`; no change notification was captured. The VLAN
persisted as active after reload. Later a rename attempt temporarily changed
the observed value to `GNMI-LAB-EVENT`; although the restore request timed out,
a later Get confirmed `GNMI-LAB` again. See [Set coverage](set.md) for history.

## On-change: interface admin status

The MDT capability response also permits on-change below
`interfaces-ios-xe-oper:interfaces/interface`. An earlier no-transceiver test
port emitted only its initial update. A subsequent test on connected port
`4/0/1` (YANG interface type `TwoGigabitEthernet`) produced down and up events.
The initial state was enabled/admin UP/oper UP.

```bash
IFACE='TwoGigabitEthernet4/0/1'
gnmi subscribe \
  --encoding json_ietf \
  --path "rfc7951:/Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=${IFACE}]/admin-status" \
  --mode stream \
  --stream-mode on_change
```

For a connected port, first Get `config/enabled` and confirm it is `true` and
safe to interrupt. Start the subscription in one terminal, then issue these
Sets from a second terminal:

```bash
# Terminal 2: the original config/enabled state was true
IFACE='TwoGigabitEthernet4/0/1'
ENABLE_PATH="openconfig:/interfaces/interface[name=${IFACE}]/config/enabled"
gnmi set \
  --encoding json_ietf \
  --update "${ENABLE_PATH}:::bool:::false" # shut
gnmi set \
  --encoding json_ietf \
  --update "${ENABLE_PATH}:::bool:::true" # no shut
```

The captured stream reported initial `if-state-up`, then `if-state-down` after
the first Set, and `if-state-up` after restoration. Final Get verified
`config/enabled: true`, OpenConfig admin/oper UP, and Cisco
`oper-status: if-oper-state-ready`. Both Sets succeeded. See the primary
[README transcript](../README.md#subscribe-examples-and-full-responses) and
[sanitized stream/Set capture](../captures/interface-onchange-shut-no-shut.ndjson).
A shut/no-shut briefly interrupts the link.

## POLL

The C9300 accepted gNMI `POLL` subscriptions for both Cisco interface-oper
`admin-status` and the OpenConfig `state/cpu` leaf. The command you supplied
uses an unkeyed interface path and returned the `cpu` leaf for every interface,
so the complete output was intentionally not saved. Prefer the keyed path
below to limit both collection and output. gNMIc's interactive selector prompts
for a target and subscription. Press Enter to select each one and send the
poll; repeat to poll again. Press `Ctrl+C` to exit.

```bash
IFACE='TwoGigabitEthernet4/0/1'
gnmi subscribe \
  --path "rfc7951:/Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=${IFACE}]/admin-status" \
  --mode poll
```

The initial update and the first manually requested poll both returned
`if-state-down` for the test interface used in that capture. Its identifier
is redacted. See the primary README for the response transcript.

Keyed CPU flag poll (verified; initial and manual poll both returned `false`):

```bash
IFACE='TwoGigabitEthernet4/0/1'
gnmi subscribe \
  --path "/interfaces/interface[name=${IFACE}]/state/cpu" \
  --mode poll
```

The sanitized response is in [interfaces-oper-poll.ndjson](../captures/interfaces-oper-poll.ndjson).

## Capability limits

- OpenConfig interface `oper-status` is not advertised for on-change by this
  device; use periodic sampling for that path.
- Cisco IOS XE 26 documents streaming `SAMPLE` and `ON_CHANGE`. This C9300
  accepted interactive `POLL`; `ONCE` returned a snapshot; target-defined
  produced no values in a 10-second trial, so support remains undetermined.
- On-change paths must be checked against the device's live
  `Cisco-IOS-XE-mdt-capabilities-oper` response; advertised module support
  alone does not imply on-change support for every path.
