# Get: OpenConfig models

Recipes for `openconfig-*` models. Run the
[connection setup](../README.md#connect-and-authenticate) first. Responses are
sanitized captures from the lab Catalyst 9300, IOS XE 26.02.1.

---

## OpenConfig interface operational status

**Goal:** Read an interface's operational status through the OpenConfig model.

```bash
VLAN_ID='899'
gnmic get \
  --path "openconfig:/interfaces/interface[name=Vlan${VLAN_ID}]/state/oper-status" \
  --encoding json_ietf
```

**Observed response** (SVI name redacted):

```json
[
  {
    "source": "<DEVICE_ADDRESS>:9339",
    "timestamp": 1791951993579492470,
    "time": "2026-10-13T21:26:33.579492470-07:00",
    "updates": [
      {
        "Path": "openconfig:interfaces/interface[name=<REDACTED_SVI>]/state/oper-status",
        "values": {
          "interfaces/interface/state/oper-status": "LOWER_LAYER_DOWN"
        }
      }
    ]
  }
]
```

**Change these fields:**
- `Vlan${VLAN_ID}` — the full interface name. For a physical port use the key
  directly, e.g. `name=TwoGigabitEthernet4/0/1`.

**Verify:** `oper-status` returns an OpenConfig enum such as `UP`, `DOWN`, or
`LOWER_LAYER_DOWN`. This is the same state the
[Cisco](cisco.md#cisco-interface-operational-status) and [IETF](ietf.md#ietf-interface-operational-status)
models report for the same interface, in a different encoding.

**Status:** Verified on C9300 / IOS XE 26.02.1 / 2026-10-13.
