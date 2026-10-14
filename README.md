# Cisco IOS XE gNMIc Examples

A hands-on gNMIc guide for Cisco Catalyst 9300 running IOS XE. The commands,
settings, and sanitized response envelopes below were collected from the lab
switch. The README is the primary tutorial; the linked files provide focused
detail and reusable helpers.

## Contents

- [Quick navigation by operation and model](#quick-navigation-by-operation-and-model)
- [Connect to the switch](#connect-to-the-switch)
- [What the switch supports](#what-the-switch-supports)
- [Get examples and full responses](#get-examples-and-full-responses)
- [Cisco gNMI cfg Get](#cisco-gnmi-cfg-get)
- [Set examples and full responses](#set-examples-and-full-responses)
- [Subscribe examples and full responses](#subscribe-examples-and-full-responses)
- [TLS and credentials](#tls-and-credentials)
- [What changed on the lab device](#what-changed-on-the-lab-device)
- [Redactions and publication](#redactions-and-publication)
- [More detail](#more-detail)

### Quick navigation by operation and model

| Operation | Model / example | Jump to |
|---|---|---|
| Get | Cisco native config | [hostname, interface description, VLAN](#get-examples-and-full-responses) |
| Get | Cisco gNMI cfg | [secure gNMI port](#cisco-gnmi-cfg-get) |
| Get | Cisco and IETF interface state | [interface status examples](#cisco-interface-operational-status) |
| Get | Cisco process CPU operational model | [five-second CPU sample](#cpu-utilization-sample) |
| Set | Cisco native config | [hostname Update/Replace and VLAN Update](#set-examples-and-full-responses) |
| Subscribe | OpenConfig interface state | [periodic sample](#periodic-sampling) and [on-change](#on-change) |
| TLS | `gnxi secure-init` bootstrap | [TLS and credentials](#tls-and-credentials) |

Each captured response below has a short result summary in its disclosure label.
Expand it to see the complete gNMI response envelope, including timestamps and
paths. This keeps the page scannable while retaining the raw evidence.

## Connect to the switch

Install [gNMIc](https://gnmic.openconfig.net/install/). Set the target and
username, then enter the password at the prompt so it does not enter shell
history:

```bash
export GNMIC_ADDRESS="192.0.2.10:9339"
export GNMIC_USERNAME="admin"
export GNMIC_SKIP_VERIFY="true"
read -rsp "gNMI password: " GNMIC_PASSWORD
printf '\n'
export GNMIC_PASSWORD
```

The address above is a documentation placeholder. Use your switch's reachable
address. Clear the password from the shell when finished with
`unset GNMIC_PASSWORD`.

Check the connection and advertised models:

```bash
gnmic capabilities
```

## What the switch supports

Observed device profile: Catalyst 9300 stack, IOS XE 26.02.1, secure gNMI on
port `9339`, username/password authentication, and a self-signed certificate
created with the device's existing `gnxi secure-init` setup. The device
advertised these relevant models and encodings:

| Model | Observed use in this guide |
|---|---|
| `Cisco-IOS-XE-native` | Hostname, interface description, and VLAN configuration |
| `Cisco-IOS-XE-interfaces-oper` | Interface operational status |
| `Cisco-IOS-XE-vlan-oper` | VLAN status and port membership |
| `Cisco-IOS-XE-gnmi-cfg` | gNMI server configuration; secure port Get below |
| `Cisco-IOS-XE-process-cpu-oper` | Five-second CPU utilization Get below |
| `Cisco-IOS-XE-yang-interfaces-cfg` | Advertised; useful alternative interface configuration model, not yet queried |
| `Cisco-IOS-XE-mdt-cfg` | Advertised; not yet collected (contains receiver/subscription settings) |
| `Cisco-IOS-XE-memory-oper` | Advertised; not yet collected |
| `Cisco-IOS-XE-process-memory-oper` | Advertised; not yet collected |
| `Cisco-IOS-XE-environment-oper` | Advertised; not yet collected |
| `Cisco-IOS-XE-ntp-oper` | Advertised; not yet collected |
| `openconfig-interfaces` | Interface operational status and Subscribe |
| `ietf-interfaces` | Operational interface status under `interfaces-state` |

The device reported gNMI version `0.7.0`; Cisco's IOS XE 26.x guide describes
support for protocol version `0.4.0`. Prefer live Capabilities when selecting a
path or encoding because model revisions vary by IOS XE release.

Live Capabilities also advertised `Cisco-IOS-XE-mdt-cfg`,
`Cisco-IOS-XE-yang-interfaces-cfg`, `Cisco-IOS-XE-memory-oper`,
`Cisco-IOS-XE-process-memory-oper`, `Cisco-IOS-XE-environment-oper`, and
`Cisco-IOS-XE-ntp-oper`. These are useful next samples. MDT configuration can
include collector addresses and subscription filters, so inspect only a
specific path and redact it before publication. The YANG interfaces cfg model
is a good next comparison with the native interface description example.

To filter Capabilities down to several relevant advertised models:

```bash
gnmic capabilities --format json |
  rg -A 1 '"name": "Cisco-IOS-XE-(gnmi-cfg|process-cpu-oper|mdt-cfg|yang-interfaces-cfg|memory-oper|process-memory-oper|environment-oper|ntp-oper)"'
```

<details>
<summary>Capabilities result: eight gNMI, CPU, interface cfg, MDT, memory, environment, and NTP models are advertised — expand excerpt</summary>

```text
      "name": "Cisco-IOS-XE-gnmi-cfg",
      "version": "2026-08-01",
      "name": "Cisco-IOS-XE-mdt-cfg",
      "version": "2026-08-01",
      "name": "Cisco-IOS-XE-yang-interfaces-cfg",
      "version": "2026-08-01",
      "name": "Cisco-IOS-XE-memory-oper",
      "version": "2022-11-01",
      "name": "Cisco-IOS-XE-environment-oper",
      "version": "2026-08-01",
      "name": "Cisco-IOS-XE-ntp-oper",
      "version": "2026-08-01",
      "name": "Cisco-IOS-XE-process-cpu-oper",
      "version": "2026-08-01",
      "name": "Cisco-IOS-XE-process-memory-oper",
      "version": "2026-08-01",
```

</details>

## Get examples and full responses

These commands use `json_ietf`. In the responses, `<DEVICE_ADDRESS>` replaces
the device address; hostname, physical interface, and SVI names are also
redacted where they appeared. The timestamps and response shape are retained.

### Cisco native hostname

```bash
gnmic get \
  --path 'rfc7951:/Cisco-IOS-XE-native:native/hostname' \
  --encoding json_ietf
```

<details>
<summary>hostname = <REDACTED_HOSTNAME> — expand full response</summary>

```json
[
  {
    "source": "<DEVICE_ADDRESS>:9339",
    "timestamp": 1791951992025736485,
    "time": "2026-10-13T21:26:32.025736485-07:00",
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

</details>

### Cisco native interface description

Replace `MEMBER/PORT` with an interface on your device.

```bash
IFACE='MEMBER/PORT'
gnmic get \
  --path "rfc7951:/Cisco-IOS-XE-native:native/interface/GigabitEthernet[name=${IFACE}]/description" \
  --encoding json_ietf
```

<details>
<summary>description = (empty value) — expand full response</summary>

```json
[
  {
    "source": "<DEVICE_ADDRESS>:9339",
    "timestamp": 1791951992802115522,
    "time": "2026-10-13T21:26:32.802115522-07:00",
    "updates": [
      {
        "Path": "rfc7951:Cisco-IOS-XE-native:native/interface/GigabitEthernet[name=<REDACTED_INTERFACE>]/description",
        "values": {
          "Cisco-IOS-XE-native:native/interface/GigabitEthernet/description": ""
        }
      }
    ]
  }
]
```

</details>

### Cisco native VLAN configuration

VLAN 899 was created for this example. This Get reads its configured list entry.

```bash
VLAN_ID='899'
gnmic get \
  --path "rfc7951:/Cisco-IOS-XE-native:native/vlan/Cisco-IOS-XE-vlan:vlan-list[id=${VLAN_ID}]" \
  --encoding json_ietf
```

<details>
<summary>id = 899 — expand full response</summary>

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

</details>

### Cisco VLAN operational state and ports

```bash
gnmic get \
  --path 'rfc7951:/Cisco-IOS-XE-vlan-oper:vlans/vlan[id=899]' \
  --encoding json_ietf
```

<details>
<summary>id = 899 — expand full response</summary>

```json
[
  {
    "source": "<DEVICE_ADDRESS>:9339",
    "timestamp": 1791952317884553482,
    "time": "2026-10-13T21:31:57.884553482-07:00",
    "updates": [
      {
        "Path": "rfc7951:Cisco-IOS-XE-vlan-oper:vlans/vlan[id=899]",
        "values": {
          "Cisco-IOS-XE-vlan-oper:vlans/vlan": {
            "id": 899,
            "name": "GNMI-LAB",
            "status": "active"
          }
        }
      }
    ]
  }
]
```

</details>

Check port membership separately:

```bash
gnmic get \
  --path 'rfc7951:/Cisco-IOS-XE-vlan-oper:vlans/vlan[id=899]/ports' \
  --encoding json_ietf
```

<details>
<summary>1 response messages captured — expand full response</summary>

```json
[
  {
    "source": "<DEVICE_ADDRESS>:9339",
    "timestamp": 1791952338433699896,
    "time": "2026-10-13T21:32:18.433699896-07:00",
    "updates": [
      {
        "Path": "rfc7951:Cisco-IOS-XE-vlan-oper:vlans/vlan[id=899]/ports",
        "values": {
          "Cisco-IOS-XE-vlan-oper:vlans/vlan/ports": {}
        }
      }
    ]
  }
]
```

</details>

### Cisco interface-operational status

```bash
VLAN_ID='REPLACE_WITH_TEST_VLAN'
gnmic get \
  --path "rfc7951:/Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=Vlan${VLAN_ID}]/oper-status" \
  --encoding json_ietf
```

<details>
<summary>oper-status = if-oper-state-lower-layer-down — expand full response</summary>

```json
[
  {
    "source": "<DEVICE_ADDRESS>:9339",
    "timestamp": 1791951993319796124,
    "time": "2026-10-13T21:26:33.319796124-07:00",
    "updates": [
      {
        "Path": "rfc7951:Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=<REDACTED_SVI>]/oper-status",
        "values": {
          "Cisco-IOS-XE-interfaces-oper:interfaces/interface/oper-status": "if-oper-state-lower-layer-down"
        }
      }
    ]
  }
]
```

</details>

### OpenConfig interface status

```bash
VLAN_ID='REPLACE_WITH_TEST_VLAN'
gnmic get \
  --path "openconfig:/interfaces/interface[name=Vlan${VLAN_ID}]/state/oper-status" \
  --encoding json_ietf
```

<details>
<summary>oper-status = LOWER_LAYER_DOWN — expand full response</summary>

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

</details>

### IETF interface status

This device exposes operational interface state under the older
`interfaces-state` tree:

```bash
VLAN_ID='REPLACE_WITH_TEST_VLAN'
gnmic get \
  --path "rfc7951:/ietf-interfaces:interfaces-state/interface[name=Vlan${VLAN_ID}]/oper-status" \
  --encoding json_ietf
```

<details>
<summary>oper-status = lower-layer-down — expand full response</summary>

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

</details>

### Cisco gNMI cfg Get

`Cisco-IOS-XE-gnmi-cfg` models the gNMI/gNXI service's own configuration.
This narrow read confirms the secure gNMI listener port. Do not Set the service
port or TLS/authentication controls over the same session without a planned
recovery path; a change can interrupt access.

```bash
gnmic get \
  --path 'rfc7951:/Cisco-IOS-XE-gnmi-cfg:gnmi-cfg-data/config/secure-port' \
  --encoding json_ietf
```

<details>
<summary>secure-port = 9339 — expand full response</summary>

```json
[
  {
    "source": "<DEVICE_ADDRESS>:9339",
    "timestamp": 1791953806580286544,
    "time": "2026-10-13T21:56:46.580286544-07:00",
    "updates": [
      {
        "Path": "rfc7951:Cisco-IOS-XE-gnmi-cfg:gnmi-cfg-data/config/secure-port",
        "values": {
          "Cisco-IOS-XE-gnmi-cfg:gnmi-cfg-data/config/secure-port": 9339
        }
      }
    ]
  }
]
```

</details>

### CPU utilization sample

`Cisco-IOS-XE-process-cpu-oper` is an operational model. This reads one
five-second CPU utilization leaf rather than the full process table:

```bash
gnmic get \
  --path 'rfc7951:/Cisco-IOS-XE-process-cpu-oper:cpu-usage/cpu-utilization/five-seconds' \
  --encoding json_ietf
```

<details>
<summary>five-seconds CPU utilization = 4 — expand full response</summary>

```json
[
  {
    "source": "<DEVICE_ADDRESS>:9339",
    "timestamp": 1791953814816488622,
    "time": "2026-10-13T21:56:54.816488622-07:00",
    "updates": [
      {
        "Path": "rfc7951:Cisco-IOS-XE-process-cpu-oper:cpu-usage/cpu-utilization/five-seconds",
        "values": {
          "Cisco-IOS-XE-process-cpu-oper:cpu-usage/cpu-utilization/five-seconds": 4
        }
      }
    ]
  }
]
```

</details>

## Set examples and full responses

Set changes configuration. Save the original value before changing it, use a
narrow leaf path, and verify with Get afterward.

### Hostname Update

First Get and save the current hostname for rollback. The lab hostname was
temporarily updated to `GNMIC-LAB`:

```bash
gnmic set --update \
  'rfc7951:/Cisco-IOS-XE-native:native/hostname:::string:::GNMIC-LAB'
```

<details>
<summary>UPDATE acknowledged: rfc7951:Cisco-IOS-XE-native:native/hostname — expand full response</summary>

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

</details>

The verification Get returned `GNMIC-LAB`:

<details>
<summary>hostname = GNMIC-LAB — expand full response</summary>

```json
[
  {
    "source": "<DEVICE_ADDRESS>:9339",
    "timestamp": 1791951625365063926,
    "time": "2026-10-13T21:20:25.365063926-07:00",
    "updates": [
      {
        "Path": "rfc7951:Cisco-IOS-XE-native:native/hostname",
        "values": {
          "Cisco-IOS-XE-native:native/hostname": "GNMIC-LAB"
        }
      }
    ]
  }
]
```

</details>

### Hostname Replace

Replace was tested at the same leaf with a second temporary value:

```bash
gnmic set --replace \
  'rfc7951:/Cisco-IOS-XE-native:native/hostname:::string:::GNMIC-REPLACE-DEMO'
```

<details>
<summary>REPLACE acknowledged: rfc7951:Cisco-IOS-XE-native:native/hostname — expand full response</summary>

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

</details>

The verification Get returned `GNMIC-REPLACE-DEMO`:

<details>
<summary>hostname = GNMIC-REPLACE-DEMO — expand full response</summary>

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

</details>

Set these variables using
the values saved before the test, then restore the original hostname with
Update:

```bash
HOSTNAME_PATH='rfc7951:/Cisco-IOS-XE-native:native/hostname'
ORIGINAL_HOSTNAME='<COPY_VALUE_FROM_INITIAL_GET>'
gnmic set --update \
  "${HOSTNAME_PATH}:::string:::${ORIGINAL_HOSTNAME}"
```

The rollback SetResponse was successful:

<details>
<summary>UPDATE acknowledged: rfc7951:Cisco-IOS-XE-native:native/hostname — expand full response</summary>

```json
{
  "source": "<DEVICE_ADDRESS>:9339",
  "timestamp": 1791951661491447751,
  "time": "2026-10-13T21:21:01.491447751-07:00",
  "results": [
    {
      "operation": "UPDATE",
      "path": "rfc7951:Cisco-IOS-XE-native:native/hostname"
    }
  ]
}
```

</details>

The final Get confirmed the original value; it is redacted here:

<details>
<summary>hostname = <REDACTED_HOSTNAME> — expand full response</summary>

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

</details>

### Create or name a VLAN with Update

VLAN 899 was unused, so it was created as `GNMI-LAB`. This live Set succeeded:

```bash
gnmic set --timeout 45s --update \
  'rfc7951:/Cisco-IOS-XE-native:native/vlan/Cisco-IOS-XE-vlan:vlan-list[id=899]/name:::string:::GNMI-LAB'
```

<details>
<summary>UPDATE acknowledged: rfc7951:Cisco-IOS-XE-native:native/vlan/Cisco-IOS-XE-vlan:vlan-list[id=899]/name — expand full response</summary>

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

</details>

The verification Get returned the configured ID and name; operational Get
reported the VLAN active with an empty ports list. VLAN 899 remains configured
and no ports were assigned. The first Set attempt timed out and IOS XE reported
a configuration database lock; after the lock cleared, the retry above
succeeded. For any timed-out Set, Get the path before retrying.

### Interface description template

This Update was locally rendered as a dry run only; it was not sent to the
switch. Choose an interface safe for testing, Get and save the old description,
then provide a rollback before removing `--dry-run`:

```bash
IFACE='MEMBER/PORT'
NEW_DESCRIPTION='gnmi-lab-test'
DESC_PATH="rfc7951:/Cisco-IOS-XE-native:native/interface/GigabitEthernet[name=${IFACE}]/description"
gnmic set --dry-run --update \
  "${DESC_PATH}:::string:::${NEW_DESCRIPTION}"
```

## Subscribe examples and full responses

### Periodic sampling

This OpenConfig stream returned an initial update, sync response, and repeated
updates at a 5-second sample interval:

```bash
VLAN_ID='REPLACE_WITH_TEST_VLAN'
gnmic subscribe \
  --path "openconfig:/interfaces/interface[name=Vlan${VLAN_ID}]/state/oper-status" \
  --mode stream \
  --stream-mode sample \
  --sample-interval 5s
```

The device address and SVI name are redacted in these response envelopes:

<details>
<summary>oper-status = LOWER_LAYER_DOWN; 5 response objects — expand full response</summary>

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

</details>

### On-change

```bash
VLAN_ID='REPLACE_WITH_TEST_VLAN'
gnmic subscribe \
  --path "openconfig:/interfaces/interface[name=Vlan${VLAN_ID}]/state/oper-status" \
  --mode stream \
  --stream-mode on_change \
  --heartbeat-interval 30s
```

The RPC opened, but the device emitted no update or sync response during the
10-second observation window. The stream was stopped with Ctrl+C. No response
block was received, so event delivery on this stable leaf remains unverified.

Other modes include `--mode once`, `--mode poll`, and
`--stream-mode target_defined`; these have not been verified on this device.

## TLS and credentials

The switch uses the existing `gnxi secure-init` bootstrap setup. Cisco describes
this default/encrypted state as using a self-signed certificate that the client
does not verify. The certificate captured during this work had no Subject
Alternative Name. We made no device TLS changes, and the gNMIc examples use
`GNMIC_SKIP_VERIFY=true` for this bootstrap setup. This encrypts traffic but
does not authenticate the server.

An optional fingerprint helper can capture and compare the presented
certificate, but gNMIc has no SSH-style trust-on-first-use prompt or
fingerprint-pin flag. A first fingerprint must be confirmed over an independent
trusted channel. See [TLS details and helper usage](docs/tls-and-credentials.md).

Never publish a functioning password, private key, client certificate, or
device-specific credential. Use `CHANGE_ME` only as a non-working placeholder.

## What changed on the lab device

- The hostname was temporarily changed with Update and Replace, then restored
  to its original value and verified.
- VLAN 899 was created as `GNMI-LAB`; it is active and has no assigned ports.
- No interface description Set was sent.
- TLS and gNMI security configuration were left unchanged.

## Redactions and publication

Full response envelopes are included with device address, original hostname,
physical interface name, and SVI name redacted. The lab VLAN ID/name, IOS XE
release, response timestamps, and model paths are retained. Review those
remaining details before reusing the captures for another publication context.

## More detail

- [Get examples with response details](examples/get.md)
- [Set examples and rollback notes](examples/set.md)
- [Subscribe modes and response details](examples/subscribe.md)
- [Operation/model coverage matrix](docs/coverage.md)
- [TLS and credential guidance](docs/tls-and-credentials.md)
- [Repository contribution and redaction rules](AGENTS.md)
- [Capture policy](captures/README.md)
- [Certificate capture helper](scripts/capture-server-cert.sh)
- [Certificate fingerprint check helper](scripts/check-server-cert.sh)

## References

- [Cisco IOS XE 26.x gNMI Protocol](https://www.cisco.com/c/en/us/td/docs/ios-xml/ios/prog/configuration/26x/26x-programmability-cg/gnmi.html)
- [Cisco IOS XE 26.x Model-Driven Telemetry](https://www.cisco.com/c/en/us/td/docs/ios-xml/ios/prog/configuration/26x/26x-programmability-cg/model-driven-telemetry.html)
- [Cisco IOS XE YANG modules](https://github.com/YangModels/yang/tree/main/vendor/cisco/xe) (schema reference; check the device's live Capabilities for its advertised revisions)
- [Cisco gNOI certificate bootstrapping](https://www.cisco.com/c/en/us/td/docs/ios-xml/ios/prog/configuration/1718/b-1718-programmability-cg/gnoi.html)
- [gNMIc documentation](https://gnmic.openconfig.net/)
