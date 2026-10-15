# Subscribe: Cisco models

Recipes for `Cisco-IOS-XE-*` subscriptions. Run the
[connection setup](../README.md#connect-and-authenticate) first. Responses are
sanitized captures from the lab Catalyst 9300, IOS XE 26.02.1. Check on-change
support against your device's [MDT capabilities](README.md#on-change-support)
before relying on it. Stop streaming commands with `Ctrl+C`.

---

## Cisco interface on-change (shut/no-shut)

**Goal:** Stream interface up/down events as they happen.

> A shut briefly interrupts the link. Use a port that is safe to interrupt and
> confirm `config/enabled` is `true` first.

**Command — start the stream (terminal 1):**

```bash
IFACE='TwoGigabitEthernet4/0/1'
gnmi subscribe \
  --encoding json_ietf \
  --path "rfc7951:/Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=${IFACE}]/admin-status" \
  --mode stream \
  --stream-mode on_change
```

**Trigger a change (terminal 2):** run the
[OpenConfig shut/no-shut Set](../set/openconfig.md#openconfig-interface-enable).

**Observed stream** (initial `up`, then `down` after the shut, then `up` after
the no-shut; interleaved lines are the SetResponses from terminal 2). Full
capture:
[captures/interface-onchange-shut-no-shut.ndjson](../captures/interface-onchange-shut-no-shut.ndjson).

```json
{"source":"<DEVICE_ADDRESS>:9339","subscription-name":"default-1792003670","time":"2026-10-14T11:39:43.497701-07:00","updates":[{"Path":"rfc7951:Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=TwoGigabitEthernet4/0/1]/admin-status","values":{"Cisco-IOS-XE-interfaces-oper:interfaces/interface/admin-status":"if-state-up"}}]}
{"source":"<DEVICE_ADDRESS>:9339","subscription-name":"default-1792003670","time":"2026-10-14T11:40:20.127473-07:00","updates":[{"Path":"rfc7951:Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=TwoGigabitEthernet4/0/1]/admin-status","values":{"Cisco-IOS-XE-interfaces-oper:interfaces/interface/admin-status":"if-state-down"}}]}
{"source":"<DEVICE_ADDRESS>:9339","subscription-name":"default-1792003670","time":"2026-10-14T11:40:48.219897-07:00","updates":[{"Path":"rfc7951:Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=TwoGigabitEthernet4/0/1]/admin-status","values":{"Cisco-IOS-XE-interfaces-oper:interfaces/interface/admin-status":"if-state-up"}}]}
```

**Change these fields:**
- `IFACE` — your approved lab port.

**Verify:** the stream emits a new `admin-status` update only when the port
state changes. A final Get confirmed `config/enabled: true` and
`oper-status: if-oper-state-ready`.

**Status:** Verified on C9300 / IOS XE 26.02.1 / 2026-10-14 (connected port
4/0/1).

---

## Cisco VLAN name on-change

**Goal:** Watch a VLAN name and receive an update when it changes.

**Command — start the stream:**

```bash
VLAN_ID='899'
gnmi subscribe \
  --path "rfc7951:/Cisco-IOS-XE-vlan-oper:vlans/vlan[id=${VLAN_ID}]/name" \
  --mode stream \
  --stream-mode on_change
```

**Observed initial sync** (initial name update, then the sync-response marker).
Full capture:
[captures/vlan-onchange-sync.ndjson](../captures/vlan-onchange-sync.ndjson).

```json
{"source":"<DEVICE_ADDRESS>:9339","subscription-name":"default-1792000187","time":"2026-10-14T10:41:39.141582-07:00","updates":[{"Path":"rfc7951:Cisco-IOS-XE-vlan-oper:vlans/vlan[id=899]/name","values":{"Cisco-IOS-XE-vlan-oper:vlans/vlan/name":"GNMI-LAB"}}]}
{"sync-response": true}
```

**Trigger a change (second terminal):** rename the VLAN with the
[Cisco VLAN name Set](../set/cisco.md#cisco-vlan-name). The stream then emits the
change. In this capture the name went from `GNMI-LAB` to `GNMI-LAB-EVENT`;
because the native rename briefly clears the name leaf during the commit, the
stream shows a transient default `VLAN0899` before the new value. Full capture:
[captures/vlan-onchange-event.ndjson](../captures/vlan-onchange-event.ndjson).

```json
{"source":"<DEVICE_ADDRESS>:9339","subscription-name":"default-1792013742","time":"2026-10-14T14:27:34.431902-07:00","updates":[{"Path":"rfc7951:Cisco-IOS-XE-vlan-oper:vlans/vlan[id=899]/name","values":{"Cisco-IOS-XE-vlan-oper:vlans/vlan/name":"GNMI-LAB"}}]}
{"sync-response":true}
{"source":"<DEVICE_ADDRESS>:9339","subscription-name":"default-1792013742","time":"2026-10-14T14:29:54.562143-07:00","updates":[{"Path":"rfc7951:Cisco-IOS-XE-vlan-oper:vlans/vlan[id=899]/name","values":{"Cisco-IOS-XE-vlan-oper:vlans/vlan/name":"VLAN0899"}}]}
{"source":"<DEVICE_ADDRESS>:9339","subscription-name":"default-1792013742","time":"2026-10-14T14:30:00.060026-07:00","updates":[{"Path":"rfc7951:Cisco-IOS-XE-vlan-oper:vlans/vlan[id=899]/name","values":{"Cisco-IOS-XE-vlan-oper:vlans/vlan/name":"GNMI-LAB-EVENT"}}]}
```

**Change these fields:**
- `VLAN_ID` — your approved lab VLAN.

**Verify:** the initial update returns the current name followed by
`sync-response: true`; the rename produces new updates ending in the new name.

**Status:** Verified on C9300 / IOS XE 26.02.1 / 2026-10-14 (initial sync and
change event captured). The native VLAN rename that triggers the event is slow
on this device and may report a client timeout before it applies — see
[limitations](../docs/limitations.md#set-operations).

---

## Cisco interface ONCE snapshot

**Goal:** Fetch the current interface admin status once, then exit.

```bash
IFACE='TwoGigabitEthernet4/0/1'
gnmi subscribe \
  --path "rfc7951:/Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=${IFACE}]/admin-status" \
  --mode once
```

**Observed response** (initial value, then a timestamp-only close). Full
capture:
[captures/interface-oper-once.ndjson](../captures/interface-oper-once.ndjson).

```json
{"source":"<DEVICE_ADDRESS>:9339","subscription-name":"default-1792006431","time":"2026-10-14T12:25:43.842405-07:00","updates":[{"Path":"rfc7951:Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=TwoGigabitEthernet4/0/1]/admin-status","values":{"Cisco-IOS-XE-interfaces-oper:interfaces/interface/admin-status":"if-state-up"}}]}
```

**Change these fields:**
- `IFACE` — the interface to snapshot.

**Verify:** one update returns, then the command exits. This transcript included
no `sync-response` object.

**Status:** Verified on C9300 / IOS XE 26.02.1 / 2026-10-14.

---

## Cisco interface oper-status (POLL)

**Goal:** Poll an interface's operational status on demand.

`POLL` is a subscription mode and is **independent of the model** — it works on
any gettable path. The same poll is shown for
[OpenConfig](openconfig.md#openconfig-interface-poll) and
[IETF](ietf.md#ietf-interface-poll). gNMIc's POLL is interactive: press Enter to
select the target and subscription and send a poll; repeat to poll again;
`Ctrl+C` to exit.

```bash
IFACE='GigabitEthernet0/0'
gnmi subscribe \
  --path "rfc7951:/Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=${IFACE}]/oper-status" \
  --mode poll
```

**Observed** (initial update, sync, then the value again on the manual poll).
Full capture: [captures/poll-oper-status.ndjson](../captures/poll-oper-status.ndjson).

```json
{"source":"<DEVICE_ADDRESS>:9339","time":"2026-10-14T20:49:23.759871-07:00","updates":[{"Path":"rfc7951:Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=GigabitEthernet0/0]/oper-status","values":{"Cisco-IOS-XE-interfaces-oper:interfaces/interface/oper-status":"if-oper-state-ready"}}]}
{"sync-response":true}
```

**Change these fields:**
- `IFACE` — the interface to poll.

**Verify:** each poll returns the current `oper-status`.

**Status:** Verified on C9300 / IOS XE 26.02.1 / 2026-10-14.

---

## Cisco interface CPU flag (POLL)

**Goal:** Poll a single interface leaf on demand.

gNMIc's `POLL` mode is interactive: it prompts for a target and subscription.
Press Enter to select each one and send a poll; repeat to poll again; `Ctrl+C`
to exit. Use a keyed path to keep the output narrow.

```bash
IFACE='TwoGigabitEthernet4/0/1'
gnmi subscribe \
  --path "/interfaces/interface[name=${IFACE}]/state/cpu" \
  --mode poll
```

**Observed response** (initial update, sync, then the value again on the manual
poll). Full capture:
[captures/interfaces-oper-poll.ndjson](../captures/interfaces-oper-poll.ndjson).

```json
{"time":"2026-10-14T12:32:38.049932-07:00","updates":[{"Path":"interfaces/interface[name=TwoGigabitEthernet4/0/1]/state/cpu","values":{"interfaces/interface/state/cpu":false}}]}
{"sync-response":true}
{"time":"2026-10-14T12:32:48.843668-07:00","updates":[{"Path":"interfaces/interface[name=TwoGigabitEthernet4/0/1]/state/cpu","values":{"interfaces/interface/state/cpu":false}}]}
```

**Change these fields:**
- `IFACE` — the interface to poll. Keep the key; an unkeyed path returns the
  flag for every interface.

**Verify:** each poll returns the current `cpu` flag for the keyed interface.

**Status:** Verified on C9300 / IOS XE 26.02.1 / 2026-10-14.

---

## Cisco memory statistics (SAMPLE)

**Goal:** Stream memory pool statistics at a fixed interval.

```bash
gnmi subscribe \
  --path 'rfc7951:/Cisco-IOS-XE-memory-oper:memory-statistics' \
  --mode stream \
  --stream-mode sample \
  --sample-interval 5s \
  --encoding json_ietf
```

**Observed response** (initial update, sync, then repeated 5s samples with full
values for the `Processor`, `reserve Processor`, and `lsmpi_io` pools). Full
capture:
[captures/memory-oper-sample.ndjson](../captures/memory-oper-sample.ndjson).

```json
{"source":"<DEVICE_ADDRESS>:9339","time":"2026-10-14T19:31:46.834721-07:00","updates":[{"Path":"rfc7951:Cisco-IOS-XE-memory-oper:memory-statistics","values":{"Cisco-IOS-XE-memory-oper:memory-statistics":{"memory-statistic":[{"name":"Processor","total-memory":"1331335788","used-memory":"376679760","free-memory":"954656028"}]}}}]}
{"sync-response":true}
```

**Change these fields:**
- `--sample-interval` — the sampling period.

**Verify:** each sample returns the `memory-statistic` list with byte counters.

> **Device note:** this path returned **no values** (timestamp-only
> notifications) on the primary C9300 / IOS XE 26.02.1 used elsewhere in this
> guide. It was verified value-bearing on a second lab unit, a **C9300-24UX /
> IOS XE 26.1**. Streaming support for operational trees is release-specific;
> confirm on your device.

**Status:** Verified on C9300-24UX / IOS XE 26.1 / 2026-10-14.

---

## Multi-path subscribe

**Goal:** Stream several leaves from different models in one subscription.

```bash
IFACE='TenGigabitEthernet1/0/1'
gnmi subscribe \
  --path "rfc7951:/Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=${IFACE}]/oper-status" \
  --path 'rfc7951:/Cisco-IOS-XE-process-cpu-oper:cpu-usage/cpu-utilization/five-seconds' \
  --mode stream --stream-mode sample --sample-interval 5s --encoding json_ietf
```

**Observed response** (each path produces its own update, then a single
`sync-response`, then both repeat each interval). Full capture:
[captures/multi-path-subscribe.ndjson](../captures/multi-path-subscribe.ndjson).

```json
{"source":"<DEVICE_ADDRESS>:9339","time":"2026-10-14T20:00:10.329381-07:00","updates":[{"Path":"rfc7951:Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=TenGigabitEthernet1/0/1]/oper-status","values":{"Cisco-IOS-XE-interfaces-oper:interfaces/interface/oper-status":"if-oper-state-ready"}}]}
{"source":"<DEVICE_ADDRESS>:9339","time":"2026-10-14T20:00:10.331378-07:00","updates":[{"Path":"rfc7951:Cisco-IOS-XE-process-cpu-oper:cpu-usage/cpu-utilization/five-seconds","values":{"Cisco-IOS-XE-process-cpu-oper:cpu-usage/cpu-utilization/five-seconds":2}}]}
{"sync-response":true}
```

**Change these fields:**
- Add or remove `--path` arguments; each is streamed in the same subscription.
- `IFACE` — the interface key; `--sample-interval` — the sampling period.

**Verify:** both paths deliver an initial update, one shared `sync-response`
follows, then each path repeats near the interval.

**Status:** Verified on C9300-24UX / IOS XE 26.1 / 2026-10-14.
