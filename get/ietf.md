# Get: IETF models

Recipes for `ietf-*` models. Run the
[connection setup](../README.md#connect-and-authenticate) first. Responses are
sanitized captures from the lab Catalyst 9300, IOS XE 26.02.1.

This device's advertised IETF model exposes interface state under the
operational `interfaces-state` tree. That tree is read-only: use it for Get and
Subscribe, not Set. For writable IETF interface config (description), see
[set/ietf.md](../set/ietf.md).

---

## IETF interface operational status

**Goal:** Read an interface's operational status through the IETF model.

```bash
VLAN_ID='899'
gnmi get \
  --path "rfc7951:/ietf-interfaces:interfaces-state/interface[name=Vlan${VLAN_ID}]/oper-status" \
  --encoding json_ietf
```

**Observed response** (SVI name redacted):

```json
[
  {
    "source": "<DEVICE_ADDRESS>:9339",
    "timestamp": 1791951993985375150,
    "time": "2026-10-13T21:26:33.985375150-07:00",
    "updates": [
      {
        "Path": "rfc7951:ietf-interfaces:interfaces-state/interface[name=<REDACTED_SVI>]/oper-status",
        "values": {
          "ietf-interfaces:interfaces-state/interface/oper-status": "lower-layer-down"
        }
      }
    ]
  }
]
```

**Change these fields:**
- `Vlan${VLAN_ID}` — the full interface name. For a physical port use the key
  directly, e.g. `name=TwoGigabitEthernet4/0/1`.

**Verify:** `oper-status` returns an IETF value such as `up`, `down`, or
`lower-layer-down`. This matches the
[Cisco](cisco.md#cisco-interface-operational-status) and
[OpenConfig](openconfig.md#openconfig-interface-operational-status) status for
the same interface.

**Status:** Verified on C9300 / IOS XE 26.02.1 / 2026-10-13.
