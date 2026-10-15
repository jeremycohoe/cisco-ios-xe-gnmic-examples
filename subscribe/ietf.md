# Subscribe: IETF models

Recipes for `ietf-*` subscriptions. Run the
[connection setup](../README.md#connect-and-authenticate) first. Responses are
sanitized captures from the lab Catalyst 9300, IOS XE 26.02.1. Stop streaming
commands with `Ctrl+C`.

The IETF `interfaces-state` tree is operational data: use it for Subscribe and
Get, not Set. It has no on-change override, so use periodic sampling.

---

## IETF interface periodic sample

**Goal:** Receive interface operational status on a fixed interval.

```bash
IFACE='TwoGigabitEthernet4/0/1'
gnmi subscribe \
  --path "rfc7951:/ietf-interfaces:interfaces-state/interface[name=${IFACE}]/oper-status" \
  --mode stream \
  --stream-mode sample \
  --sample-interval 3s
```

**Observed:** an initial `up` update, a sync response, then repeated `up`
samples every three seconds. Full capture:
[captures/ietf-interfaces-sample.ndjson](../captures/ietf-interfaces-sample.ndjson).

```json
{"source":"<DEVICE_ADDRESS>:9339","subscription-name":"default-1792006690","time":"2026-10-14T12:30:02.957251-07:00","updates":[{"Path":"rfc7951:ietf-interfaces:interfaces-state/interface[name=TwoGigabitEthernet4/0/1]/oper-status","values":{"ietf-interfaces:interfaces-state/interface/oper-status":"up"}}]}
{"sync-response":true}
{"source":"<DEVICE_ADDRESS>:9339","subscription-name":"default-1792006690","time":"2026-10-14T12:30:05.876262-07:00","updates":[{"Path":"rfc7951:ietf-interfaces:interfaces-state/interface[name=TwoGigabitEthernet4/0/1]/oper-status","values":{"ietf-interfaces:interfaces-state/interface/oper-status":"up"}}]}
```

**Change these fields:**
- `IFACE` — the interface to sample.
- `--sample-interval` — the sampling period.

**Verify:** the first update and sync arrive immediately, then updates recur near
the interval.

**Status:** Verified on C9300 / IOS XE 26.02.1 / 2026-10-14 (port 4/0/1).

---

## IETF interface POLL

**Goal:** Poll an interface's operational status on demand through IETF.

`POLL` is model-independent (see also
[Cisco](cisco.md#cisco-interface-oper-status-poll) and
[OpenConfig](openconfig.md#openconfig-interface-poll)). It is interactive: press
Enter to select the target and subscription and send a poll; `Ctrl+C` to exit.

```bash
IFACE='GigabitEthernet0/0'
gnmi subscribe \
  --path "rfc7951:/ietf-interfaces:interfaces-state/interface[name=${IFACE}]/oper-status" \
  --mode poll
```

**Observed** (initial update, then sync). Full capture:
[captures/poll-oper-status.ndjson](../captures/poll-oper-status.ndjson).

```json
{"source":"<DEVICE_ADDRESS>:9339","time":"2026-10-14T20:50:24.894018-07:00","updates":[{"Path":"rfc7951:ietf-interfaces:interfaces-state/interface[name=GigabitEthernet0/0]/oper-status","values":{"ietf-interfaces:interfaces-state/interface/oper-status":"up"}}]}
{"sync-response":true}
```

**Change these fields:**
- `IFACE` — the interface to poll.

**Verify:** each poll returns the current `oper-status` (`up`/`down`/...).

**Status:** Verified on C9300 / IOS XE 26.02.1 / 2026-10-14.
