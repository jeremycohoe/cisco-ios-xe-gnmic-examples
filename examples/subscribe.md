# Subscribe to telemetry

Both examples use the OpenConfig operational state of one SVI. Replace
`VLAN_ID` with an interface you want to monitor. Stop a streaming command with
`Ctrl+C`.

## Periodic sampling

The device returned an initial update, a sync response, and repeated updates
at the 5-second interval. Sanitized full response envelopes follow. The device
address and SVI name are redacted.

Command:

```bash
VLAN_ID='REPLACE_WITH_TEST_VLAN'
gnmic subscribe \
  --path "openconfig:/interfaces/interface[name=Vlan${VLAN_ID}]/state/oper-status" \
  --mode stream \
  --stream-mode sample \
  --sample-interval 5s
```

Output (three sampled updates and the sync response):

```text
{
  "source": "<DEVICE_ADDRESS>:9339",
  "subscription-name": "default-1791952522",
  "timestamp": 1791952033802308000,
  "time": "2026-10-13T21:27:13.802308-07:00",
  "updates": [
    {
      "Path": "openconfig:interfaces/interface[name=<REDACTED_SVI>]/state/oper-status",
      "values": {
        "interfaces/interface/state/oper-status": "LOWER_LAYER_DOWN"
      }
    }
  ]
}
{
  "source": "<DEVICE_ADDRESS>:9339",
  "subscription-name": "default-1791952522",
  "timestamp": 1791952033803384000,
  "time": "2026-10-13T21:27:13.803384-07:00"
}
{
  "sync-response": true
}
{
  "source": "<DEVICE_ADDRESS>:9339",
  "subscription-name": "default-1791952522",
  "timestamp": 1791952038797622000,
  "time": "2026-10-13T21:27:18.797622-07:00",
  "updates": [
    {
      "Path": "openconfig:interfaces/interface[name=<REDACTED_SVI>]/state/oper-status",
      "values": {
        "interfaces/interface/state/oper-status": "LOWER_LAYER_DOWN"
      }
    }
  ]
}
{
  "source": "<DEVICE_ADDRESS>:9339",
  "subscription-name": "default-1791952522",
  "timestamp": 1791952043798809000,
  "time": "2026-10-13T21:27:23.798809-07:00",
  "updates": [
    {
      "Path": "openconfig:interfaces/interface[name=<REDACTED_SVI>]/state/oper-status",
      "values": {
        "interfaces/interface/state/oper-status": "LOWER_LAYER_DOWN"
      }
    }
  ]
}
```

## On-change

This asks the target to report changes to the selected leaf. The heartbeat
requests a refresh at least every 30 seconds when supported:

```bash
VLAN_ID='REPLACE_WITH_TEST_VLAN'
gnmic subscribe \
  --path "openconfig:/interfaces/interface[name=Vlan${VLAN_ID}]/state/oper-status" \
  --mode stream \
  --stream-mode on_change \
  --heartbeat-interval 30s
```

No `SubscribeResponse` was captured during the 10-second observation window—not
even an initial update or sync response. The client was stopped with Ctrl+C.
This capture does not establish that the device accepted the subscription or
verify on-change event delivery. Repeat with a controlled change before relying
on this subscription in an application.

This is the complete observed output: no gNMI response block was received.
Test with a path whose value changes, or wait for a real state change, before
concluding that event updates are flowing. Periodic sampling works on this path.

## Related modes

- `--mode once` sends a one-time subscription snapshot and exits.
- `--mode poll` waits for explicit poll requests; it is useful when the client
  needs to choose each update time.
- `--stream-mode target_defined` lets the device choose update behavior.

`on_change` and `sample` are stream modes of the same Subscribe RPC.
