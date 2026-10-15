# Subscribe: OpenConfig models

Recipes for `openconfig-*` subscriptions. Run the
[connection setup](../README.md#connect-and-authenticate) first. Responses are
sanitized captures from the lab Catalyst 9300, IOS XE 26.02.1. Stop streaming
commands with `Ctrl+C`.

OpenConfig general interface `oper-status` is **not** advertised for on-change
on this device, so use periodic sampling for that path. See
[on-change support](README.md#on-change-support).

---

## OpenConfig interface periodic sample

**Goal:** Receive interface operational status on a fixed interval.

```bash
VLAN_ID='899'
gnmi subscribe \
  --path "openconfig:/interfaces/interface[name=Vlan${VLAN_ID}]/state/oper-status" \
  --mode stream \
  --stream-mode sample \
  --sample-interval 5s
```

**Observed:** an initial update, a sync response, then repeated five-second
samples of `oper-status`.

**Change these fields:**
- `Vlan${VLAN_ID}` — the full interface name; for a physical port use the key
  directly, e.g. `name=TwoGigabitEthernet4/0/1`.
- `--sample-interval` — the sampling period.

**Verify:** the first update and sync arrive immediately, then updates recur near
the interval.

**Status:** Verified on C9300 / IOS XE 26.02.1.

---

## OpenConfig interface POLL

**Goal:** Poll an interface's operational status on demand through OpenConfig.

`POLL` is model-independent (see also
[Cisco](cisco.md#cisco-interface-oper-status-poll) and
[IETF](ietf.md#ietf-interface-poll)). It is interactive: press Enter to select
the target and subscription and send a poll; `Ctrl+C` to exit.

```bash
IFACE='GigabitEthernet0/0'
gnmi subscribe \
  --path "openconfig:/interfaces/interface[name=${IFACE}]/state/oper-status" \
  --mode poll
```

**Observed** (initial update, sync, then the value again on the manual poll).
Full capture: [captures/poll-oper-status.ndjson](../captures/poll-oper-status.ndjson).

```json
{"source":"<DEVICE_ADDRESS>:9339","time":"2026-10-14T20:49:54.120276-07:00","updates":[{"Path":"openconfig:interfaces/interface[name=GigabitEthernet0/0]/state/oper-status","values":{"interfaces/interface/state/oper-status":"UP"}}]}
{"sync-response":true}
```

**Change these fields:**
- `IFACE` — the interface to poll.

**Verify:** each poll returns the current `oper-status` (`UP`/`DOWN`/...).

**Status:** Verified on C9300 / IOS XE 26.02.1 / 2026-10-14.
