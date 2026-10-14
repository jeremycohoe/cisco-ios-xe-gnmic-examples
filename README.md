# Cisco IOS XE gNMIc Examples

A hands-on gNMIc guide for Cisco Catalyst 9300 running IOS XE. The commands,
settings, and sanitized response envelopes below were collected from the lab
switch. The README is the primary tutorial; the linked files provide focused
detail and reusable helpers.

## Contents

- [Connect and discover](#connect-to-the-switch)
  - [Supported models and encodings](#what-the-switch-supports)
  - [MDT path support for subscriptions](#mdt-subscription-capability-results)
  - [Quick navigation by operation and model](#quick-navigation-by-operation-and-model)
- [Get: configuration and operational state](#get-examples-and-full-responses)
  - Cisco native configuration: [hostname](#cisco-native-hostname), [interface description](#cisco-native-interface-description), [VLAN](#cisco-native-vlan-configuration)
  - [Cisco VLAN operational state and ports](#cisco-vlan-operational-state-and-ports)
  - [Cisco, OpenConfig, and IETF interface status](#cisco-interface-operational-status)
  - [Cisco gNMI cfg](#cisco-gnmi-cfg-get)
  - [Cisco MDT cfg](#cisco-mdt-cfg-get)
  - [Cisco process CPU](#cpu-utilization-sample)
  - [Cisco memory, environment sensors, and NTP](#additional-cisco-operational-gets)
- [Set: live configuration examples](#set-examples-and-full-responses)
  - Hostname: [Update](#hostname-update), [Replace](#hostname-replace)
  - [VLAN name Update](#create-or-name-a-vlan-with-update)
  - [Set coverage by model and operation](#set-operation-coverage-by-model)
  - [VLAN name Replace](#vlan-name-replace)
  - [OpenConfig interface enabled Update](#verified-openconfig-interface-set-update)
- [Subscribe: streaming, snapshots, and polling](#subscribe-examples-and-full-responses)
  - [OpenConfig periodic sample](#periodic-sampling)
  - [IETF interface periodic sample](#ietf-interface-periodic-sample)
  - [ONCE and target-defined stream](#once-and-target-defined-stream)
  - [On-change, including interface shut/no-shut](#on-change)
  - [POLL interface status](#poll-subscription) and [CPU flag](#poll-the-interface-cpu-flag)
- [TLS, changes, and reference material](#tls-and-credentials)
  - [Lab configuration changes and rollback](#what-changed-on-the-lab-device)
  - [Redactions and publication notes](#redactions-and-publication)
  - [More detail and references](#more-detail)

### Quick navigation by operation and model

| Operation | Model / example | Jump to |
|---|---|---|
| Get | Cisco native config | [hostname, interface description, VLAN](#get-examples-and-full-responses) |
| Get | Cisco gNMI cfg | [secure gNMI port](#cisco-gnmi-cfg-get) |
| Get | Cisco MDT cfg | [configured stream leaf](#cisco-mdt-cfg-get) |
| Get | Cisco and IETF interface state | [interface status examples](#cisco-interface-operational-status) |
| Get | Cisco process CPU operational model | [five-second CPU sample](#cpu-utilization-sample) |
| Get | Cisco memory, environment, and NTP operational models | [additional Cisco operational Gets](#additional-cisco-operational-gets) |
| Set | Cisco native config | [hostname Update/Replace and VLAN Update/Replace](#set-examples-and-full-responses) |
| Set | OpenConfig and IETF interfaces | [live description Update/Replace/Delete](#set-operation-coverage-by-model) |
| Subscribe | OpenConfig interface state | [periodic sample](#periodic-sampling) |
| Subscribe | Cisco VLAN operational state | [on-change initial sync](#on-change) |
| Subscribe | Cisco interface operational admin state | [ONCE](#once-and-target-defined-stream), [POLL](#poll-subscription), [ON_CHANGE shut/no-shut](#on-change) |
| Subscribe | IETF interface operational state | [periodic sample](#ietf-interface-periodic-sample) |
| Subscribe | Cisco interfaces CPU flag | [narrow POLL example](#poll-subscription) |
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

The switch was reloaded during collection. Post-reload checks confirmed that
gNMI was reachable, the original hostname was restored (the value is redacted),
and VLAN 899 persisted as active `GNMI-LAB` with no ports assigned. A later
rename and restore both timed out; immediate Gets showed `GNMI-LAB-EVENT`, but
a later Get at 12:55 returned `GNMI-LAB`, confirming that the authorized
restore eventually took effect. Additional post-reload memory, environment,
and NTP Gets also succeeded.

| Model | Observed use in this guide |
|---|---|
| `Cisco-IOS-XE-native` | Hostname, interface description, and VLAN configuration |
| `Cisco-IOS-XE-interfaces-oper` | Interface operational status |
| `Cisco-IOS-XE-vlan-oper` | VLAN status and port membership |
| `Cisco-IOS-XE-gnmi-cfg` | gNMI server configuration; secure port Get below |
| `Cisco-IOS-XE-process-cpu-oper` | Five-second CPU utilization Get below |
| `Cisco-IOS-XE-ntp` | Advertised writable NTP configuration model; not yet collected |
| `Cisco-IOS-XE-yang-interfaces-cfg` | Advertised; controls deprecated YANG model exposure and YANG AAA, not interface descriptions |
| `Cisco-IOS-XE-mdt-cfg` | Bounded stream-leaf Get; full tree omitted because it contains collector addresses and site telemetry filters |
| `Cisco-IOS-XE-mdt-capabilities-oper` | Full Get; 53 running-datastore subscription path entries |
| `Cisco-IOS-XE-memory-oper` | Memory pools Get below |
| `Cisco-IOS-XE-process-memory-oper` | Advertised; not yet collected |
| `Cisco-IOS-XE-environment-oper` | Chassis sensors Get below; full response is large |
| `Cisco-IOS-XE-ntp-oper` | NTP status and peer list Get below; peer IPs redacted |
| `openconfig-interfaces` | Interface operational status and Subscribe |
| `ietf-interfaces` | Operational interface status under `interfaces-state` |

The device reported gNMI version `0.7.0` and encodings `JSON`, `JSON_IETF`,
and `PROTO`; Cisco's IOS XE 26.x guide describes support for protocol version
`0.4.0`. Prefer live Capabilities when selecting a path or encoding because
model revisions vary by IOS XE release.

The full sanitized Capabilities inventory contains 486 advertised module names
and revisions, including shared types, deviations, and operational models.
Download or search the [complete model inventory](captures/capabilities-model-inventory.json).
The device advertises 11 Cisco modules ending in `-cfg`; advertised does not
mean each is a useful or safe write target. App-Hosting is excluded from the
examples. The additional config-model candidates are:

<details>
<summary>Complete advertised model and revision inventory — expand (486 entries)</summary>

| Model | Revision |
|---|---|
| `ietf-yang-types` | `2013-07-15` |
| `ietf-restconf` | `2017-01-26` |
| `ietf-netconf-with-defaults` | `2011-06-01` |
| `ietf-netconf` | `2011-06-01` |
| `ietf-yang-patch` | `2017-02-22` |
| `ietf-yang-library` | `2019-01-04` |
| `ietf-inet-types` | `2013-07-15` |
| `ietf-datastores` | `2018-02-14` |
| `Cisco-IOS-XE-aaa` | `2026-08-01` |
| `Cisco-IOS-XE-aaa-deviation` | `2025-07-01` |
| `Cisco-IOS-XE-aaa-events` | `2022-11-01` |
| `Cisco-IOS-XE-aaa-oper` | `2026-08-01` |
| `Cisco-IOS-XE-aaa-types` | `2024-11-01` |
| `Cisco-IOS-XE-acl` | `2026-08-01` |
| `Cisco-IOS-XE-types` | `2026-08-01` |
| `Cisco-IOS-XE-acl-oper` | `2026-08-01` |
| `Cisco-IOS-XE-aging-time-deviation` | `2025-07-01` |
| `Cisco-IOS-XE-app-hosting-cfg` | `2026-08-01` |
| `Cisco-IOS-XE-app-hosting-oper` | `2026-08-01` |
| `Cisco-IOS-XE-arp` | `2022-11-01` |
| `Cisco-IOS-XE-arp-oper` | `2026-08-01` |
| `Cisco-IOS-XE-ios-common-oper` | `2022-11-01` |
| `Cisco-IOS-XE-atm` | `2024-11-01` |
| `Cisco-IOS-XE-audit-cfg` | `2026-08-01` |
| `Cisco-IOS-XE-avb` | `2022-11-01` |
| `Cisco-IOS-XE-aws-common-cfg` | `2026-08-01` |
| `Cisco-IOS-XE-aws-common-oper` | `2026-08-01` |
| `Cisco-IOS-XE-aws-cw-cfg` | `2026-08-01` |
| `Cisco-IOS-XE-common-types` | `2026-08-01` |
| `Cisco-IOS-XE-aws-cw-oper` | `2026-08-01` |
| `Cisco-IOS-XE-aws-s3-cfg` | `2026-08-01` |
| `Cisco-IOS-XE-aws-s3-oper` | `2026-08-01` |
| `Cisco-IOS-XE-banner-internal` | `2024-07-01` |
| `Cisco-IOS-XE-bfd` | `2026-08-01` |
| `Cisco-IOS-XE-bfd-oper` | `2026-08-01` |
| `Cisco-IOS-XE-bgp` | `2026-08-01` |
| `Cisco-IOS-XE-bgp-common-oper` | `2022-11-01` |
| `Cisco-IOS-XE-bgp-nbr-oper` | `2026-08-01` |
| `Cisco-IOS-XE-bgp-oper` | `2026-08-01` |
| `Cisco-IOS-XE-bgp-route-oper` | `2026-08-01` |
| `Cisco-IOS-XE-bgp-rib-oper` | `2026-08-01` |
| `Cisco-IOS-XE-boot-integrity-oper` | `2026-08-01` |
| `Cisco-IOS-XE-breakout-port-oper` | `2022-11-01` |
| `Cisco-IOS-XE-bridge` | `2022-11-01` |
| `Cisco-IOS-XE-buffers` | `2024-07-01` |
| `Cisco-IOS-XE-cable-diag-oper` | `2026-08-01` |
| `Cisco-IOS-XE-cable-diag-rpc` | `2022-11-01` |
| `Cisco-IOS-XE-call-home` | `2024-11-01` |
| `Cisco-IOS-XE-cdp` | `2026-08-01` |
| `Cisco-IOS-XE-cdp-oper` | `2026-08-01` |
| `Cisco-IOS-XE-cef` | `2024-11-01` |
| `Cisco-IOS-XE-cef-deviation` | `2024-11-01` |
| `Cisco-IOS-XE-cellwan-oper` | `2026-08-01` |
| `Cisco-IOS-XE-cfm-oper` | `2026-08-01` |
| `Cisco-IOS-XE-checkpoint-archive-oper` | `2026-08-01` |
| `Cisco-IOS-XE-clns` | `2024-07-01` |
| `Cisco-IOS-XE-cloud-services-cfg` | `2026-08-01` |
| `Cisco-IOS-XE-cloud-services-oper` | `2026-08-01` |
| `Cisco-IOS-XE-coap` | `2022-11-01` |
| `Cisco-IOS-XE-crypto` | `2026-08-01` |
| `Cisco-IOS-XE-crypto-oper` | `2026-08-01` |
| `Cisco-IOS-XE-crypto-types` | `2026-02-01` |
| `Cisco-IOS-XE-crypto-pki-events` | `2023-11-01` |
| `Cisco-IOS-XE-crypto-pki-oper` | `2026-08-01` |
| `Cisco-IOS-XE-cts` | `2026-08-01` |
| `Cisco-IOS-XE-cts-switching-deviation` | `2022-11-01` |
| `Cisco-IOS-XE-device-hardware-oper` | `2026-08-01` |
| `Cisco-IOS-XE-device-sensor` | `2026-08-01` |
| `Cisco-IOS-XE-device-sensor-deviation` | `2026-02-01` |
| `Cisco-IOS-XE-device-tracking` | `2026-02-01` |
| `Cisco-IOS-XE-device-tracking-cat9k-deviation` | `2026-08-01` |
| `Cisco-IOS-XE-dhcp` | `2026-08-01` |
| `Cisco-IOS-XE-dhcp-oper` | `2026-08-01` |
| `Cisco-IOS-XE-dhcp-security-track-server-oper` | `2026-08-01` |
| `Cisco-IOS-XE-diagnostics` | `2024-03-01` |
| `Cisco-IOS-XE-dialer` | `2025-03-01` |
| `Cisco-IOS-XE-dialer-deviation` | `2022-11-01` |
| `Cisco-IOS-XE-dmi-common-types` | `2022-11-01` |
| `Cisco-IOS-XE-dns-oper` | `2026-08-01` |
| `Cisco-IOS-XE-dot1x` | `2026-08-01` |
| `Cisco-IOS-XE-eem` | `2026-02-01` |
| `Cisco-IOS-XE-eem-oper` | `2026-08-01` |
| `Cisco-IOS-XE-efp-oper` | `2022-11-01` |
| `Cisco-IOS-XE-eigrp` | `2026-08-01` |
| `Cisco-IOS-XE-eigrp-oper` | `2026-08-01` |
| `Cisco-IOS-XE-environment-oper` | `2026-08-01` |
| `Cisco-IOS-XE-eta` | `2026-08-01` |
| `Cisco-IOS-XE-ethernet` | `2026-08-01` |
| `Cisco-IOS-XE-ethernet-cat9k-deviation` | `2026-02-01` |
| `Cisco-IOS-XE-event-history-types` | `2026-08-01` |
| `Cisco-IOS-XE-evpn-oper` | `2026-08-01` |
| `Cisco-IOS-XE-ezpm` | `2026-02-01` |
| `Cisco-IOS-XE-features` | `2026-08-01` |
| `Cisco-IOS-XE-fib-events` | `2022-11-01` |
| `Cisco-IOS-XE-fib-oper` | `2026-08-01` |
| `Cisco-IOS-XE-flow` | `2026-08-01` |
| `Cisco-IOS-XE-flow-deviation` | `` |
| `Cisco-IOS-XE-flow-monitor-oper` | `2026-08-01` |
| `Cisco-IOS-XE-flow-rpc` | `2022-11-01` |
| `Cisco-IOS-XE-fqdn` | `2022-11-01` |
| `Cisco-IOS-XE-fwd-oper` | `2026-08-01` |
| `Cisco-IOS-XE-gir-oper` | `2026-08-01` |
| `Cisco-IOS-XE-gnmi-cfg` | `2026-08-01` |
| `Cisco-IOS-XE-gnss-oper` | `2026-08-01` |
| `Cisco-IOS-XE-group-policy` | `2026-08-01` |
| `Cisco-IOS-XE-group-policy-oper` | `2026-08-01` |
| `Cisco-IOS-XE-grpc-tunnel-cfg` | `2026-08-01` |
| `Cisco-IOS-XE-ha-oper` | `2026-08-01` |
| `Cisco-IOS-XE-hsrp-events` | `2022-11-01` |
| `Cisco-IOS-XE-hsrp-oper` | `2026-08-01` |
| `Cisco-IOS-XE-http` | `2026-08-01` |
| `Cisco-IOS-XE-icmp` | `2026-08-01` |
| `Cisco-IOS-XE-identity-oper` | `2026-08-01` |
| `Cisco-IOS-XE-igmp` | `2026-08-01` |
| `Cisco-IOS-XE-install-event-types` | `2026-08-01` |
| `Cisco-IOS-XE-install-events` | `2022-11-01` |
| `Cisco-IOS-XE-install-oper` | `2026-08-01` |
| `Cisco-IOS-XE-install-oper-types` | `2022-11-01` |
| `Cisco-IOS-XE-interface-common` | `2026-08-01` |
| `Cisco-IOS-XE-interfaces-cat9k-deviation` | `2025-03-01` |
| `Cisco-IOS-XE-interfaces-deviation` | `2026-08-01` |
| `Cisco-IOS-XE-interfaces-oper` | `2026-08-01` |
| `Cisco-IOS-XE-ios-events-oper` | `2026-08-01` |
| `Cisco-IOS-XE-utd-common-oper` | `2024-03-01` |
| `Cisco-IOS-XE-ip-arp-oper` | `2026-08-01` |
| `Cisco-IOS-XE-ip-sla-events` | `2022-11-01` |
| `Cisco-IOS-XE-ip-sla-oper` | `2026-08-01` |
| `Cisco-IOS-XE-ipc` | `2024-11-01` |
| `Cisco-IOS-XE-ipv6-nd-oper` | `2026-08-01` |
| `Cisco-IOS-XE-ipv6-oper` | `2026-08-01` |
| `Cisco-IOS-XE-isis` | `2026-08-01` |
| `Cisco-IOS-XE-isis-intf-oper` | `2026-08-01` |
| `Cisco-IOS-XE-isis-oper` | `2022-11-01` |
| `Cisco-IOS-XE-isis-operv2-oper` | `2026-08-01` |
| `Cisco-IOS-XE-kron` | `2024-11-01` |
| `Cisco-IOS-XE-l2tp-oper` | `2026-08-01` |
| `Cisco-IOS-XE-l2vpn` | `2026-08-01` |
| `Cisco-IOS-XE-l2vpn-oper` | `2026-08-01` |
| `Cisco-IOS-XE-l3vpn` | `2022-11-01` |
| `Cisco-IOS-XE-lacp-oper` | `2026-08-01` |
| `Cisco-IOS-XE-line-common-deviation` | `2023-11-01` |
| `Cisco-IOS-XE-line-nonquake-deviation` | `2024-07-01` |
| `Cisco-IOS-XE-linecard-oper` | `2022-11-01` |
| `Cisco-IOS-XE-lisp` | `2026-08-01` |
| `Cisco-IOS-XE-lisp-deviation` | `2022-11-01` |
| `Cisco-IOS-XE-lisp-oper` | `2026-08-01` |
| `Cisco-IOS-XE-livetools-common-types` | `2025-03-01` |
| `Cisco-IOS-XE-livetools-oper` | `2026-08-01` |
| `Cisco-IOS-XE-lldp` | `2026-08-01` |
| `Cisco-IOS-XE-lldp-oper` | `2026-08-01` |
| `Cisco-IOS-XE-logging-deviation` | `2024-07-01` |
| `Cisco-IOS-XE-loop-detect` | `2026-02-01` |
| `Cisco-IOS-XE-loop-detect-events` | `2024-03-01` |
| `Cisco-IOS-XE-macsec-oper` | `2026-08-01` |
| `Cisco-IOS-XE-matm-events` | `2024-03-01` |
| `Cisco-IOS-XE-matm-oper` | `2026-08-01` |
| `Cisco-IOS-XE-matm-state-oper` | `2026-02-01` |
| `Cisco-IOS-XE-mcast-events` | `2024-07-01` |
| `Cisco-IOS-XE-mdns-gateway` | `2026-08-01` |
| `Cisco-IOS-XE-mdt-capabilities-oper` | `2026-08-01` |
| `Cisco-IOS-XE-mdt-common-defs` | `2026-08-01` |
| `Cisco-IOS-XE-mdt-cfg` | `2026-08-01` |
| `Cisco-IOS-XE-mdt-oper` | `2026-08-01` |
| `Cisco-IOS-XE-mdt-oper-v2` | `2026-08-01` |
| `Cisco-IOS-XE-mdt-stats-oper` | `2026-08-01` |
| `Cisco-IOS-XE-memory-oper` | `2022-11-01` |
| `Cisco-IOS-XE-meraki-connect-oper` | `2026-08-01` |
| `Cisco-IOS-XE-mka` | `2026-08-01` |
| `Cisco-IOS-XE-mka-oper` | `2026-08-01` |
| `Cisco-IOS-XE-mld` | `2026-08-01` |
| `Cisco-IOS-XE-mlppp-oper` | `2026-08-01` |
| `Cisco-IOS-XE-mmode` | `2023-07-01` |
| `Cisco-IOS-XE-mpls` | `2026-08-01` |
| `Cisco-IOS-XE-mpls-forwarding-oper` | `2026-08-01` |
| `Cisco-IOS-XE-mpls-ldp-oper` | `2026-08-01` |
| `Cisco-IOS-XE-mpls-te-oper` | `2026-08-01` |
| `Cisco-IOS-XE-mroute-oper` | `2026-08-01` |
| `Cisco-IOS-XE-msdp-oper` | `2026-08-01` |
| `Cisco-IOS-XE-multicast` | `2026-08-01` |
| `Cisco-IOS-XE-mvrp` | `2026-08-01` |
| `Cisco-IOS-XE-nat-oper` | `2026-08-01` |
| `Cisco-IOS-XE-native` | `2026-08-01` |
| `Cisco-IOS-XE-uplink-autoconfig` | `2026-08-01` |
| `Cisco-IOS-XE-switch` | `2026-08-01` |
| `Cisco-IOS-XE-sla` | `2024-11-01` |
| `Cisco-IOS-XE-service-routing` | `2022-11-01` |
| `Cisco-IOS-XE-service-discovery` | `2022-11-01` |
| `Cisco-IOS-XE-sanet` | `2026-08-01` |
| `Cisco-IOS-XE-qos` | `2025-07-01` |
| `Cisco-IOS-XE-power` | `2026-08-01` |
| `Cisco-IOS-XE-policy` | `2026-08-01` |
| `Cisco-IOS-XE-pnp` | `2026-08-01` |
| `Cisco-IOS-XE-nhrp` | `2026-02-01` |
| `Cisco-IOS-XE-template` | `2026-08-01` |
| `Cisco-IOS-XE-wsma` | `2026-08-01` |
| `Cisco-IOS-XE-ntp` | `2026-08-01` |
| `Cisco-IOS-XE-udld` | `2026-02-01` |
| `Cisco-IOS-XE-service-insertion` | `2025-03-01` |
| `Cisco-IOS-XE-segment-routing` | `2026-02-01` |
| `Cisco-IOS-XE-snmp` | `2026-08-01` |
| `Cisco-IOS-XE-ospfv3` | `2026-08-01` |
| `Cisco-IOS-XE-ospf` | `2026-08-01` |
| `Cisco-IOS-XE-rip` | `2026-08-01` |
| `Cisco-IOS-XE-vtp` | `2026-02-01` |
| `Cisco-IOS-XE-ppp` | `2026-08-01` |
| `Cisco-IOS-XE-track` | `2026-08-01` |
| `Cisco-IOS-XE-spanning-tree` | `2026-08-01` |
| `Cisco-IOS-XE-object-group` | `2026-02-01` |
| `Cisco-IOS-XE-route-map` | `2026-02-01` |
| `Cisco-IOS-XE-nd` | `2026-08-01` |
| `Cisco-IOS-XE-wccp` | `2026-08-01` |
| `Cisco-IOS-XE-tunnel` | `2026-02-01` |
| `Cisco-IOS-XE-rsvp` | `2026-08-01` |
| `Cisco-IOS-XE-vrrp` | `2026-08-01` |
| `Cisco-IOS-XE-vlan` | `2026-08-01` |
| `Cisco-IOS-XE-ptp` | `2026-08-01` |
| `Cisco-IOS-XE-pppoe` | `2026-02-01` |
| `Cisco-IOS-XE-nbar` | `2026-08-01` |
| `Cisco-IOS-XE-platform` | `2026-08-01` |
| `Cisco-IOS-XE-stackwise-virtual` | `2025-03-01` |
| `Cisco-IOS-XE-ncch-cfg` | `2026-08-01` |
| `Cisco-IOS-XE-ncch-oper` | `2026-08-01` |
| `Cisco-IOS-XE-nd-deviation` | `2022-11-01` |
| `Cisco-IOS-XE-netconf-diag-oper` | `2026-08-01` |
| `Cisco-IOS-XE-ngfw-common-oper` | `2026-08-01` |
| `Cisco-IOS-XE-ntp-oper` | `2026-08-01` |
| `Cisco-IOS-XE-nve-oper` | `2026-08-01` |
| `Cisco-IOS-XE-ospf-common` | `2022-11-01` |
| `Cisco-IOS-XE-ospf-deviation` | `2026-08-01` |
| `Cisco-IOS-XE-ospf-events` | `2022-11-01` |
| `Cisco-IOS-XE-ospf-oper` | `2026-08-01` |
| `Cisco-IOS-XE-ospfv3-deviation` | `2023-07-01` |
| `Cisco-IOS-XE-pae` | `2022-11-01` |
| `Cisco-IOS-XE-perf-measure-events` | `2024-03-01` |
| `Cisco-IOS-XE-perf-measure-oper` | `2026-08-01` |
| `Cisco-IOS-XE-pim-oper` | `2026-08-01` |
| `Cisco-IOS-XE-platform-common-oper` | `2022-11-01` |
| `Cisco-IOS-XE-platform-events-oper` | `2022-11-01` |
| `Cisco-IOS-XE-platform-oper` | `2026-08-01` |
| `Cisco-IOS-XE-platform-software-events` | `2022-11-01` |
| `Cisco-IOS-XE-platform-software-oper` | `2026-08-01` |
| `Cisco-IOS-XE-pnp-deviation` | `` |
| `Cisco-IOS-XE-poch-lb-switch-deviation` | `2022-11-01` |
| `Cisco-IOS-XE-poe-oper` | `2026-08-01` |
| `Cisco-IOS-XE-policy-cat9k-deviation` | `2025-03-01` |
| `Cisco-IOS-XE-port-bounce-events` | `2024-07-01` |
| `Cisco-IOS-XE-ppp-oper` | `2026-08-01` |
| `Cisco-IOS-XE-process-cpu-oper` | `2026-08-01` |
| `Cisco-IOS-XE-process-memory-oper` | `2026-08-01` |
| `Cisco-IOS-XE-psecure-oper` | `2026-08-01` |
| `Cisco-IOS-XE-rib-oper` | `2026-08-01` |
| `Cisco-IOS-XE-sanet-deviation` | `2022-11-01` |
| `Cisco-IOS-XE-sisf` | `2026-02-01` |
| `Cisco-IOS-XE-sm-enum-types` | `2022-11-01` |
| `Cisco-IOS-XE-sm-events-oper` | `2026-02-01` |
| `Cisco-IOS-XE-snmp-deviation` | `2024-11-01` |
| `Cisco-IOS-XE-spanning-tree-events` | `2024-03-01` |
| `Cisco-IOS-XE-spanning-tree-oper` | `2026-08-01` |
| `Cisco-IOS-XE-stack-member-oper` | `2026-08-01` |
| `Cisco-IOS-XE-stack-mgr-events-oper` | `2025-07-01` |
| `Cisco-IOS-XE-stack-oper` | `2026-08-01` |
| `Cisco-IOS-XE-stacking-oper` | `2026-08-01` |
| `Cisco-IOS-XE-steering-policy-oper` | `2026-08-01` |
| `Cisco-IOS-XE-switch-cp-svl-oper` | `2022-11-01` |
| `Cisco-IOS-XE-switch-deviation` | `2026-02-01` |
| `Cisco-IOS-XE-switch-dp-mac-learning-oper` | `2026-08-01` |
| `Cisco-IOS-XE-switch-dp-punt-inject-oper` | `2022-11-01` |
| `Cisco-IOS-XE-switch-dp-resources-oper` | `2026-08-01` |
| `Cisco-IOS-XE-switch-ptp-dp-oper` | `2023-03-01` |
| `Cisco-IOS-XE-switch-ptp-oper` | `2026-08-01` |
| `Cisco-IOS-XE-switchport-deviation` | `2024-07-01` |
| `Cisco-IOS-XE-switchport-oper` | `2026-08-01` |
| `Cisco-IOS-XE-system-integrity-oper` | `2026-08-01` |
| `Cisco-IOS-XE-system-security-events` | `2026-02-01` |
| `Cisco-IOS-XE-system-security-types` | `2026-08-01` |
| `Cisco-IOS-XE-system-security-oper` | `2026-08-01` |
| `Cisco-IOS-XE-tcam-oper` | `2026-08-01` |
| `Cisco-IOS-XE-tech-support-events` | `2023-11-01` |
| `Cisco-IOS-XE-trace-events` | `2022-11-01` |
| `Cisco-IOS-XE-transceiver-oper` | `2026-08-01` |
| `Cisco-IOS-XE-trustsec-oper` | `2026-08-01` |
| `Cisco-IOS-XE-tunnel-oper` | `2026-08-01` |
| `Cisco-IOS-XE-tunnel-types` | `2026-08-01` |
| `Cisco-IOS-XE-udld-events` | `2024-03-01` |
| `Cisco-IOS-XE-udld-oper` | `2026-08-01` |
| `Cisco-IOS-XE-umbrella-oper` | `2026-08-01` |
| `Cisco-IOS-XE-utd-oper` | `2026-08-01` |
| `Cisco-IOS-XE-verify-events` | `2022-11-01` |
| `Cisco-IOS-XE-vlan-ewlc-deviation` | `2024-11-01` |
| `Cisco-IOS-XE-vlan-oper` | `2026-08-01` |
| `Cisco-IOS-XE-vrf-oper` | `2022-11-01` |
| `Cisco-IOS-XE-vrrp-deviation` | `2022-11-01` |
| `Cisco-IOS-XE-vrrp-oper` | `2026-08-01` |
| `Cisco-IOS-XE-vrrp-types` | `2022-11-01` |
| `Cisco-IOS-XE-vstack` | `2022-11-01` |
| `Cisco-IOS-XE-webauth-banner-internal` | `2025-03-01` |
| `Cisco-IOS-XE-xcopy-events` | `2026-08-01` |
| `Cisco-IOS-XE-yang-interfaces-cfg` | `2026-08-01` |
| `Cisco-IOS-XE-yang-interfaces-oper` | `2026-08-01` |
| `cisco-ethernet` | `2016-05-10` |
| `cisco-evpn-service` | `2022-03-01` |
| `cisco-extensions` | `` |
| `cisco-ospf` | `2019-07-01` |
| `cisco-policy` | `2019-07-01` |
| `cisco-policy-filters` | `2019-07-01` |
| `cisco-policy-target` | `2019-07-01` |
| `cisco-routing-ext` | `2019-11-01` |
| `cisco-self-mgmt` | `2019-07-01` |
| `cisco-semver` | `2019-03-20` |
| `cisco-smart-license` | `2021-03-01` |
| `cisco-xe-ietf-event-notifications-deviation` | `2018-12-03` |
| `cisco-xe-ietf-ip-deviation` | `2016-08-10` |
| `cisco-xe-ietf-ipv4-unicast-routing-deviation` | `2015-09-11` |
| `cisco-xe-ietf-ipv6-unicast-routing-deviation` | `2015-09-11` |
| `cisco-xe-ietf-ospf-deviation` | `2018-02-09` |
| `cisco-xe-ietf-routing-deviation` | `2016-07-09` |
| `cisco-xe-ietf-routing-ext` | `2024-03-01` |
| `cisco-xe-ietf-yang-push-deviation` | `2018-12-03` |
| `cisco-xe-ietf-yang-push-ext` | `2024-06-25` |
| `cisco-xe-openconfig-acl-deviation` | `2017-08-25` |
| `cisco-xe-openconfig-acl-ext` | `1.0.2` |
| `cisco-xe-openconfig-aft-deviation` | `2025-07-01` |
| `cisco-xe-openconfig-bgp-deviation` | `2024-03-01` |
| `cisco-xe-openconfig-bgp-policy-deviation` | `2017-07-24` |
| `cisco-xe-openconfig-ethernet-segments-deviation` | `2025-07-01` |
| `cisco-xe-openconfig-evpn-deviation` | `2025-07-01` |
| `cisco-xe-openconfig-if-ethernet-ext` | `2017-10-30` |
| `cisco-xe-openconfig-if-ip-deviation` | `2017-03-04` |
| `cisco-xe-openconfig-if-poe-deviation` | `2021-10-29` |
| `cisco-xe-openconfig-interfaces-deviation` | `2018-08-21` |
| `cisco-xe-openconfig-interfaces-ext` | `2018-07-14` |
| `cisco-xe-openconfig-isis-deviation` | `2018-12-05` |
| `cisco-xe-openconfig-isis-policy-deviation` | `2020-07-30` |
| `cisco-xe-openconfig-lldp-deviation` | `2018-07-25` |
| `cisco-xe-openconfig-local-routing-deviation` | `2020-09-20` |
| `cisco-xe-openconfig-mpls-deviation` | `2019-06-27` |
| `cisco-xe-openconfig-network-instance-deviation` | `2023-10-13` |
| `cisco-xe-openconfig-network-instance-l2-deviation` | `2023-11-01` |
| `cisco-xe-openconfig-openflow-deviation` | `2019-07-01` |
| `cisco-xe-openconfig-platform-ext` | `2023-06-06` |
| `cisco-xe-openconfig-qos-deviation` | `2025-07-01` |
| `cisco-xe-openconfig-rib-bgp-ext` | `2016-11-30` |
| `openconfig-bgp-types` | `5.3.1` |
| `cisco-xe-openconfig-routing-policy-deviation` | `2017-03-30` |
| `cisco-xe-openconfig-segment-routing-deviation` | `2018-12-05` |
| `cisco-xe-openconfig-spanning-tree-deviation` | `2017-08-21` |
| `cisco-xe-openconfig-spanning-tree-ext` | `2017-10-24` |
| `cisco-xe-openconfig-system-ext` | `1.0.2` |
| `cisco-xe-openconfig-system-grpc-deviation` | `2021-10-22` |
| `cisco-xe-openconfig-telemetry-deviation` | `2026-08-01` |
| `cisco-xe-openconfig-telemetry-ext` | `2026-08-01` |
| `cisco-xe-openconfig-vlan-ext` | `2017-06-14` |
| `cisco-xe-switching-cat9k-openconfig-system-deviation` | `2018-07-01` |
| `cisco-xe-switching-openconfig-if-ethernet-deviation` | `2021-07-01` |
| `cisco-xe-switching-openconfig-interfaces-deviation` | `2018-12-12` |
| `cisco-xe-switching-openconfig-lacp-deviation` | `2022-08-25` |
| `cisco-xe-switching-openconfig-platform-deviation` | `2021-09-20` |
| `cisco-xe-switching-openconfig-vlan-deviation` | `2017-03-17` |
| `common-mpls-static` | `2019-07-01` |
| `common-mpls-types` | `2019-07-01` |
| `common-mpls-static-devs` | `2015-09-11` |
| `openconfig-inet-types` | `0.3.1` |
| `iana-crypt-hash` | `2014-08-06` |
| `iana-if-type` | `2014-05-08` |
| `ietf-diffserv-action` | `2015-04-07` |
| `ietf-diffserv-classifier` | `2015-04-07` |
| `policy-types` | `2019-07-01` |
| `ietf-diffserv-policy` | `2015-04-07` |
| `ietf-diffserv-target` | `2015-04-07` |
| `ietf-event-notifications` | `2016-10-27` |
| `ietf-yang-push` | `2021-03-01` |
| `ietf-interfaces` | `2014-05-08` |
| `ietf-ipv6-unicast-routing` | `2015-05-25` |
| `ietf-ip` | `2014-06-16` |
| `ietf-interfaces-ext` | `` |
| `ietf-ipv4-unicast-routing` | `2015-05-25` |
| `ietf-key-chain` | `2015-02-24` |
| `ietf-netconf-acm` | `2012-02-22` |
| `ietf-netconf-monitoring` | `2010-10-04` |
| `ietf-netconf-notifications` | `2012-02-06` |
| `ietf-netconf-otlp-context` | `2023-07-01` |
| `ietf-netconf-otlp-context-traceparent-version-1.0` | `` |
| `ietf-netconf-otlp-context-tracestate-version-1.0` | `` |
| `ietf-network-instance` | `2019-01-21` |
| `ietf-ospf` | `2015-03-09` |
| `ietf-restconf-monitoring` | `2017-01-26` |
| `ietf-routing` | `2015-05-25` |
| `ietf-routing-types` | `2017-02-27` |
| `ietf-yang-schema-mount` | `2019-01-14` |
| `ietf-yang-smiv2` | `2012-06-22` |
| `ietf-yang-structure-ext` | `2020-06-17` |
| `nvo` | `2019-07-01` |
| `pim` | `2019-07-01` |
| `nvo-devs` | `2015-09-11` |
| `openconfig-policy-types` | `2.0.1` |
| `openconfig-spanning-tree-types` | `0.2.1` |
| `openconfig-aaa` | `0.5.0` |
| `openconfig-aaa-types` | `0.4.1` |
| `openconfig-acl` | `1.0.0` |
| `openconfig-yang-types` | `0.2.1` |
| `openconfig-interfaces` | `2.3.0` |
| `openconfig-packet-match-types` | `1.0.0` |
| `openconfig-aft` | `2.2.0` |
| `openconfig-aft-network-instance` | `0.3.1` |
| `openconfig-network-instance` | `4.4.1` |
| `openconfig-aft-types` | `1.1.0` |
| `openconfig-alarm-types` | `0.2.1` |
| `openconfig-alarms` | `0.3.2` |
| `openconfig-bfd` | `0.2.2` |
| `openconfig-types` | `0.6.0` |
| `openconfig-bgp` | `9.1.0` |
| `openconfig-bgp-policy` | `6.1.0` |
| `openconfig-ethernet-segments` | `0.1.0` |
| `openconfig-evpn` | `0.11.0` |
| `openconfig-evpn-types` | `0.2.0` |
| `openconfig-extensions` | `2020-06-16` |
| `openconfig-if-aggregate` | `2.3.0` |
| `openconfig-if-ethernet` | `2.8.1` |
| `openconfig-if-ip` | `2.3.0` |
| `openconfig-if-ip-ext` | `2.3.0` |
| `openconfig-if-poe` | `0.1.0` |
| `openconfig-if-types` | `0.2.1` |
| `openconfig-igmp` | `0.2.0` |
| `openconfig-igmp-types` | `0.1.1` |
| `openconfig-vlan` | `1.0.2` |
| `openconfig-vlan-types` | `1.0.2` |
| `openconfig-platform-transceiver` | `0.5.0` |
| `openconfig-isis` | `0.2.1` |
| `openconfig-isis-lsdb-types` | `0.2.1` |
| `openconfig-isis-policy` | `0.8.0` |
| `openconfig-isis-types` | `0.2.1` |
| `openconfig-keychain` | `0.4.0` |
| `openconfig-keychain-types` | `0.2.0` |
| `openconfig-lacp` | `1.1.1` |
| `openconfig-license` | `0.2.0` |
| `openconfig-lldp` | `0.2.1` |
| `openconfig-lldp-types` | `0.1.0` |
| `openconfig-local-routing` | `1.0.0` |
| `openconfig-macsec` | `0.1.0` |
| `openconfig-macsec-types` | `0.1.0` |
| `openconfig-messages` | `0.0.1` |
| `openconfig-system-logging` | `0.3.0` |
| `openconfig-mpls` | `2.1.0` |
| `openconfig-mpls-ldp` | `2.1.0` |
| `openconfig-mpls-rsvp` | `2.1.0` |
| `openconfig-mpls-sr` | `2.1.0` |
| `openconfig-mpls-types` | `3.4.0` |
| `openconfig-network-instance-types` | `0.9.3` |
| `openconfig-programming-errors` | `0.1.0` |
| `openconfig-pcep` | `0.1.1` |
| `openconfig-pim-types` | `0.1.1` |
| `openconfig-ospf-types` | `0.1.3` |
| `openconfig-route-summary` | `1.0.0` |
| `openconfig-routing-policy` | `3.4.2` |
| `openconfig-network-instance-l3` | `2.0.0` |
| `openconfig-network-instance-policy` | `0.1.2` |
| `openconfig-openflow` | `0.1.1` |
| `openconfig-openflow-types` | `0.1.0` |
| `openconfig-ospf-policy` | `0.1.3` |
| `openconfig-ospfv2` | `0.2.3` |
| `openconfig-packet-match` | `1.0.0` |
| `openconfig-pim` | `0.4.1` |
| `openconfig-platform` | `0.12.1` |
| `openconfig-platform-types` | `0.10.1` |
| `openconfig-platform-port` | `0.3.2` |
| `openconfig-platform-cpu` | `0.1.1` |
| `openconfig-platform-fan` | `0.1.1` |
| `openconfig-platform-linecard` | `0.1.1` |
| `openconfig-platform-psu` | `0.2.1` |
| `openconfig-policy-forwarding` | `0.3.0` |
| `openconfig-procmon` | `0.3.0` |
| `openconfig-qos` | `0.11.2` |
| `openconfig-qos-types` | `0.2.1` |
| `openconfig-rib-bgp` | `0.8.1` |
| `openconfig-rib-bgp-ext` | `0.6.0` |
| `openconfig-rib-bgp-types` | `0.5.0` |
| `openconfig-segment-routing` | `0.0.3` |
| `openconfig-segment-routing-types` | `0.2.0` |
| `openconfig-spanning-tree` | `0.2.1` |
| `openconfig-system` | `2.3.0` |
| `openconfig-system-grpc` | `0.1.1` |
| `openconfig-system-terminal` | `0.3.0` |
| `openconfig-telemetry` | `0.5.1` |
| `openconfig-telemetry-types` | `0.4.2` |
| `openconfig-transport-types` | `0.5.0` |
| `policy-attr` | `2019-07-01` |

</details>

<details>
<summary>Other advertised Cisco configuration modules — expand</summary>

- `Cisco-IOS-XE-audit-cfg`
- `Cisco-IOS-XE-aws-common-cfg`
- `Cisco-IOS-XE-aws-cw-cfg`
- `Cisco-IOS-XE-aws-s3-cfg`
- `Cisco-IOS-XE-cloud-services-cfg`
- `Cisco-IOS-XE-grpc-tunnel-cfg`
- `Cisco-IOS-XE-ncch-cfg`
- `Cisco-IOS-XE-yang-interfaces-cfg`

`Cisco-IOS-XE-gnmi-cfg` and `Cisco-IOS-XE-mdt-cfg` have bounded Gets in this
guide. The other modules above require path and schema inspection before
examples are selected; several can affect security, external services, or
active telemetry.

</details>

Live Capabilities also advertised `Cisco-IOS-XE-mdt-cfg`,
`Cisco-IOS-XE-mdt-capabilities-oper`, `Cisco-IOS-XE-yang-interfaces-cfg`, `Cisco-IOS-XE-memory-oper`,
`Cisco-IOS-XE-process-memory-oper`, `Cisco-IOS-XE-environment-oper`, and
`Cisco-IOS-XE-ntp-oper`. These are useful next samples. MDT configuration can
include collector addresses and subscription filters, so inspect only a
specific path and redact it before publication. The YANG interfaces cfg model
controls deprecated models and YANG AAA settings, so it is not an alternate
interface description model.

To filter Capabilities down to several relevant advertised models:

```bash
gnmic capabilities --format json |
  rg -A 1 '"name": "Cisco-IOS-XE-(gnmi-cfg|process-cpu-oper|mdt-cfg|mdt-capabilities-oper|yang-interfaces-cfg|memory-oper|process-memory-oper|environment-oper|ntp-oper)"'
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

### MDT subscription capability results

The device's `Cisco-IOS-XE-mdt-capabilities-oper` response reports a running
datastore with 53 ordered path entries: 48 enable on-change for config and
state notifications, and 5 explicitly disable it. At system level, periodic is
supported for config and state; on-change is not. The gNMI transport has no
separate path overrides, so its effective support comes from the ordered
per-node entries. Use periodic sampling where no on-change-enabled entry
matches.

The entries are inflection points, not a whitelist of exact leaves: an entry
applies to its subtree until a more-specific entry overrides it. Examples of
enabled subtrees include `/yang-interfaces-oper:yang-interfaces-oper-data`,
`/vlan-ios-xe-oper:vlans`, and
`/interfaces-ios-xe-oper:interfaces/interface`. More-specific interface
exceptions disable on-change for `lag-aggregate-state` and `diffserv-info`.
OpenConfig interface support is partial: the advertised paths are specific
IPv4/IPv6 neighbor subtrees, not general interface state or counters. No
general `ios:native` or IETF `ietf-interfaces` path is advertised for
on-change, so use periodic subscriptions for those trees.

Read the tree with:

```bash
gnmic get \
  --path 'rfc7951:/Cisco-IOS-XE-mdt-capabilities-oper:mdt-capabilities-oper-data' \
  --encoding json_ietf
```

The complete sanitized Get response is also available as [JSON](captures/mdt-capabilities-get.json). It preserves the returned path list and transport overrides. Cisco documents the matching rules in its [MDT capability model guide](https://www.cisco.com/c/en/us/td/docs/ios-xml/ios/prog/configuration/26x/26x-programmability-cg/model-driven-telemetry.html).

<details>
<summary>Full MDT capability Get response — expand (53 path entries plus transport overrides)</summary>

```json
[
  {
    "source": "<DEVICE_ADDRESS>:9339",
    "timestamp": 1791992026916416660,
    "time": "2026-10-14T08:33:46.91641666-07:00",
    "updates": [
      {
        "Path": "rfc7951:Cisco-IOS-XE-mdt-capabilities-oper:mdt-capabilities-oper-data",
        "values": {
          "Cisco-IOS-XE-mdt-capabilities-oper:mdt-capabilities-oper-data": {
            "mdt-system": {
              "mdt-datastore": [
                {
                  "datastore": "mdt-cap-ds-running",
                  "mdt-per-node": [
                    {
                      "index": 1,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/yang-interfaces-oper:yang-interfaces-oper-data"
                    },
                    {
                      "index": 3,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/xcvr-ios-xe-oper:transceiver-oper-data"
                    },
                    {
                      "index": 59,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/vlan-ios-xe-oper:vlans"
                    },
                    {
                      "index": 62,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/trustsec-ios-xe-oper:trustsec-state/cts-sxp-connections"
                    },
                    {
                      "index": 63,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/trustsec-ios-xe-oper:trustsec-state/cts-rolebased-sgtmaps"
                    },
                    {
                      "index": 64,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/tcam-ios-xe-oper:tcam-details"
                    },
                    {
                      "index": 65,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": [
                          null
                        ]
                      },
                      "xpath": "/steering-policy-ios-xe-oper:steering-policy-oper-data/steering-service/steering-rloc"
                    },
                    {
                      "index": 66,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/steering-policy-ios-xe-oper:steering-policy-oper-data/steering-service"
                    },
                    {
                      "index": 67,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": [
                          null
                        ]
                      },
                      "xpath": "/steering-policy-ios-xe-oper:steering-policy-oper-data/steering-policy/steering-policy-rule"
                    },
                    {
                      "index": 68,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/steering-policy-ios-xe-oper:steering-policy-oper-data/steering-policy"
                    },
                    {
                      "index": 69,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/stacking-ios-xe-oper:stacking-oper-data"
                    },
                    {
                      "index": 72,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/rib-ios-xe-oper:rib-oper-data"
                    },
                    {
                      "index": 73,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/poe-ios-xe-oper:poe-oper-data"
                    },
                    {
                      "index": 75,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/platform-ios-xe-oper:components"
                    },
                    {
                      "index": 76,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/oc-platform:components/component/state"
                    },
                    {
                      "index": 77,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/oc-platform:components/component/power-supply/state"
                    },
                    {
                      "index": 78,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/oc-netinst:network-instances/network-instance/evpn/evpn-instances/evpn-instance"
                    },
                    {
                      "index": 79,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/oc-netinst:network-instances/network-instance/connection-points/connection-point/endpoints/endpoint/vxlan"
                    },
                    {
                      "index": 80,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/oc-netinst:network-instances/network-instance/afts/next-hops"
                    },
                    {
                      "index": 81,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/oc-netinst:network-instances/network-instance/afts/next-hop-groups"
                    },
                    {
                      "index": 82,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/oc-netinst:network-instances/network-instance/afts/ipv6-unicast/ipv6-entry"
                    },
                    {
                      "index": 83,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/oc-netinst:network-instances/network-instance/afts/ipv4-unicast/ipv4-entry"
                    },
                    {
                      "index": 84,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/oc-if:interfaces/interface/subinterfaces/subinterface/oc-ip:ipv6/neighbors/neighbor"
                    },
                    {
                      "index": 85,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/oc-if:interfaces/interface/subinterfaces/subinterface/oc-ip:ipv4/neighbors/neighbor"
                    },
                    {
                      "index": 86,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/oc-if:interfaces/interface/oc-vlan:routed-vlan/oc-ip:ipv6/neighbors/neighbor"
                    },
                    {
                      "index": 87,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/oc-if:interfaces/interface/oc-vlan:routed-vlan/oc-ip:ipv4/neighbors/neighbor"
                    },
                    {
                      "index": 88,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/nve-ios-xe-oper:nve-oper-data"
                    },
                    {
                      "index": 89,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/meraki-connect-ios-xe-oper:meraki-connect-oper-data"
                    },
                    {
                      "index": 90,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/mdt-oper-v2:mdt-oper-v2-data"
                    },
                    {
                      "index": 91,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/mdt-cfg:mdt-config-data"
                    },
                    {
                      "index": 93,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/matm-ios-xe-state-oper:matm-state-oper-data"
                    },
                    {
                      "index": 96,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/linecard-ios-xe-oper:linecard-oper-data"
                    },
                    {
                      "index": 97,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/isis-ios-xe-operv2:isis-operv2-oper-data"
                    },
                    {
                      "index": 98,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/isis-intf-ios-xe-oper:isis-intf-oper-data"
                    },
                    {
                      "index": 99,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/ipv6-nd-ios-xe-oper:ipv6-nd-oper-data"
                    },
                    {
                      "index": 100,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/ip-arp-ios-xe-oper:ip-arp-oper-data"
                    },
                    {
                      "index": 103,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": [
                          null
                        ]
                      },
                      "xpath": "/interfaces-ios-xe-oper:interfaces/interface/lag-aggregate-state"
                    },
                    {
                      "index": 104,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": [
                          null
                        ]
                      },
                      "xpath": "/interfaces-ios-xe-oper:interfaces/interface/diffserv-info"
                    },
                    {
                      "index": 105,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/interfaces-ios-xe-oper:interfaces/interface"
                    },
                    {
                      "index": 106,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/ha-ios-xe-oper:ha-oper-data"
                    },
                    {
                      "index": 108,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/group-policy-ios-xe-oper:group-policy-oper-data/grp-steer-policy-info"
                    },
                    {
                      "index": 110,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/fwd-ios-xe-oper:fwd-oper-data"
                    },
                    {
                      "index": 111,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/evpn-ios-xe-oper:evpn-oper-data"
                    },
                    {
                      "index": 112,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/dp-resources-oper:switch-dp-resources-oper-data"
                    },
                    {
                      "index": 115,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/cdp-ios-xe-oper:cdp-neighbor-details"
                    },
                    {
                      "index": 116,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/boot-integrity-ios-xe-oper:boot-integrity-oper-data"
                    },
                    {
                      "index": 117,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/bgp-nbr-ios-xe-oper:bgp-nbr-oper-data"
                    },
                    {
                      "index": 118,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/bgp-ios-rib-xe-oper:bgp-rib-oper-data"
                    },
                    {
                      "index": 119,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/bc-port-ios-xe-oper:breakout-port-oper-data"
                    },
                    {
                      "index": 125,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/arp-ios-xe-oper:arp-data/arp-vrf/arp-entry"
                    },
                    {
                      "index": 126,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": [
                          null
                        ]
                      },
                      "xpath": "/arp-ios-xe-oper:arp-data/arp-vrf"
                    },
                    {
                      "index": 127,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/app-hosting-ios-xe-oper:app-hosting-oper-data"
                    },
                    {
                      "index": 128,
                      "sub-caps": {
                        "on-change-is-valid": [
                          null
                        ],
                        "on-change-supported": "mdt-cap-notif-config mdt-cap-notif-state"
                      },
                      "xpath": "/app-hosting-ios-xe-cfg:app-hosting-cfg-data"
                    }
                  ],
                  "mdt-transport": [
                    {
                      "mdt-transport-per-node": [
                        {
                          "index": 17,
                          "sub-caps": {
                            "on-change-is-valid": [
                              null
                            ],
                            "on-change-supported": [
                              null
                            ]
                          },
                          "xpath": "/oc-platform:components/component/state"
                        },
                        {
                          "index": 18,
                          "sub-caps": {
                            "on-change-is-valid": [
                              null
                            ],
                            "on-change-supported": [
                              null
                            ]
                          },
                          "xpath": "/oc-platform:components/component/power-supply/state"
                        },
                        {
                          "index": 19,
                          "sub-caps": {
                            "on-change-is-valid": [
                              null
                            ],
                            "on-change-supported": [
                              null
                            ]
                          },
                          "xpath": "/oc-netinst:network-instances/network-instance/evpn/evpn-instances/evpn-instance"
                        },
                        {
                          "index": 20,
                          "sub-caps": {
                            "on-change-is-valid": [
                              null
                            ],
                            "on-change-supported": [
                              null
                            ]
                          },
                          "xpath": "/oc-netinst:network-instances/network-instance/connection-points/connection-point/endpoints/endpoint/vxlan"
                        },
                        {
                          "index": 21,
                          "sub-caps": {
                            "on-change-is-valid": [
                              null
                            ],
                            "on-change-supported": [
                              null
                            ]
                          },
                          "xpath": "/oc-netinst:network-instances/network-instance/afts/next-hops"
                        },
                        {
                          "index": 22,
                          "sub-caps": {
                            "on-change-is-valid": [
                              null
                            ],
                            "on-change-supported": [
                              null
                            ]
                          },
                          "xpath": "/oc-netinst:network-instances/network-instance/afts/next-hop-groups"
                        },
                        {
                          "index": 23,
                          "sub-caps": {
                            "on-change-is-valid": [
                              null
                            ],
                            "on-change-supported": [
                              null
                            ]
                          },
                          "xpath": "/oc-netinst:network-instances/network-instance/afts/ipv6-unicast/ipv6-entry"
                        },
                        {
                          "index": 24,
                          "sub-caps": {
                            "on-change-is-valid": [
                              null
                            ],
                            "on-change-supported": [
                              null
                            ]
                          },
                          "xpath": "/oc-netinst:network-instances/network-instance/afts/ipv4-unicast/ipv4-entry"
                        },
                        {
                          "index": 25,
                          "sub-caps": {
                            "on-change-is-valid": [
                              null
                            ],
                            "on-change-supported": [
                              null
                            ]
                          },
                          "xpath": "/oc-if:interfaces/interface/subinterfaces/subinterface/oc-ip:ipv6/neighbors/neighbor"
                        },
                        {
                          "index": 26,
                          "sub-caps": {
                            "on-change-is-valid": [
                              null
                            ],
                            "on-change-supported": [
                              null
                            ]
                          },
                          "xpath": "/oc-if:interfaces/interface/subinterfaces/subinterface/oc-ip:ipv4/neighbors/neighbor"
                        },
                        {
                          "index": 27,
                          "sub-caps": {
                            "on-change-is-valid": [
                              null
                            ],
                            "on-change-supported": [
                              null
                            ]
                          },
                          "xpath": "/oc-if:interfaces/interface/oc-vlan:routed-vlan/oc-ip:ipv6/neighbors/neighbor"
                        },
                        {
                          "index": 28,
                          "sub-caps": {
                            "on-change-is-valid": [
                              null
                            ],
                            "on-change-supported": [
                              null
                            ]
                          },
                          "xpath": "/oc-if:interfaces/interface/oc-vlan:routed-vlan/oc-ip:ipv4/neighbors/neighbor"
                        }
                      ],
                      "transport": "mdt-cap-transport-netconf"
                    },
                    {
                      "transport": "mdt-cap-transport-gnmi"
                    },
                    {
                      "transport": "mdt-cap-transport-grpc"
                    }
                  ]
                }
              ],
              "sub-caps": {
                "on-change-is-valid": [
                  null
                ],
                "on-change-supported": [
                  null
                ],
                "periodic-is-valid": [
                  null
                ],
                "periodic-supported": "mdt-cap-notif-config mdt-cap-notif-state"
              }
            }
          }
        }
      }
    ]
  }
]
```

</details>
This result is specific to this switch and IOS XE release.

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

### Cisco MDT cfg Get

`Cisco-IOS-XE-mdt-cfg` contains configured telemetry subscriptions and
receivers. A full-tree Get would expose collector addresses and site-specific
telemetry filters, so this example reads one stream leaf only. No MDT
configuration was changed.

```bash
SUBSCRIPTION_ID='REPLACE_WITH_SUBSCRIPTION_ID'
gnmic get \
  --path "rfc7951:/Cisco-IOS-XE-mdt-cfg:mdt-config-data/mdt-subscription[subscription-id=${SUBSCRIPTION_ID}]/base/stream" \
  --encoding json_ietf
```

**Observed value:** `yang-push`. The subscription identifier and switch address are redacted. The complete response is also saved as [JSON](captures/mdt-cfg-get-stream.json).

<details>
<summary>Full MDT cfg Get response — expand</summary>

```json
[
  {
    "source": "<DEVICE_ADDRESS>:9339",
    "timestamp": 1791999530894600204,
    "time": "2026-10-14T10:38:50.894600204-07:00",
    "updates": [
      {
        "Path": "rfc7951:Cisco-IOS-XE-mdt-cfg:mdt-config-data/mdt-subscription[subscription-id=<REDACTED_ID>]/base/stream",
        "values": {
          "Cisco-IOS-XE-mdt-cfg:mdt-config-data/mdt-subscription/base/stream": "yang-push"
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

## Additional Cisco operational Gets

The following read-only models are useful examples beyond interfaces and CPU. Operational models do not accept configuration Set operations. Values are point-in-time samples and may differ on another switch or after a later collection.

### Cisco memory operational Get

```bash
gnmic get \
  --path 'rfc7951:/Cisco-IOS-XE-memory-oper:memory-statistics' \
  --encoding json_ietf
```

**Observed:** Three memory pools (`Processor`, `reserve Processor`, and `lsmpi_io`). The captured values are in bytes and change over time. The complete sanitized response is saved as [JSON](captures/cisco-memory-oper-get.json).

<details>
<summary>Full response — expand</summary>

```json
[
  {
    "source": "<DEVICE_ADDRESS>:9339",
    "timestamp": 1792000744103157166,
    "time": "2026-10-14T10:59:04.103157166-07:00",
    "updates": [
      {
        "Path": "rfc7951:Cisco-IOS-XE-memory-oper:memory-statistics",
        "values": {
          "Cisco-IOS-XE-memory-oper:memory-statistics": {
            "memory-statistic": [
              {
                "free-memory": "946637716",
                "highest-usage": "944947744",
                "lowest-usage": "943638332",
                "name": "Processor",
                "total-memory": "1326519612",
                "used-memory": "379881896"
              },
              {
                "free-memory": "102312",
                "highest-usage": "102312",
                "lowest-usage": "102312",
                "name": "reserve Processor",
                "total-memory": "102404",
                "used-memory": "92"
              },
              {
                "free-memory": "824",
                "highest-usage": "412",
                "lowest-usage": "824",
                "name": "lsmpi_io",
                "total-memory": "6295128",
                "used-memory": "6294304"
              }
            ]
          }
        }
      }
    ]
  }
]
```

</details>

### Cisco environment sensor Get

```bash
gnmic get \
  --path 'rfc7951:/Cisco-IOS-XE-environment-oper:environment-sensors' \
  --encoding json_ietf
```

**Observed:** 64 sensor entries were returned across the stack. Temperature sensors reported normal state; absent power supplies appear as `NotExist`. This is a large response, so the full sanitized payload is collapsed below and also available as a separate JSON file. The complete sanitized response is saved as [JSON](captures/cisco-environment-oper-get.json).

<details>
<summary>Full response — expand</summary>

```json
[
  {
    "source": "<DEVICE_ADDRESS>:9339",
    "timestamp": 1792000745188409544,
    "time": "2026-10-14T10:59:05.188409544-07:00",
    "updates": [
      {
        "Path": "rfc7951:Cisco-IOS-XE-environment-oper:environment-sensors",
        "values": {
          "Cisco-IOS-XE-environment-oper:environment-sensors": {
            "env-stat": {
              "cancl-snsrs": 0,
              "crit-alrm": 0,
              "major-alrm": 0,
              "minor-alrm": 0,
              "null-st-snsrs": 0
            },
            "environment-sensor": [
              {
                "current-reading": 32,
                "hi-major-thrsld": 56,
                "hi-minor-thrsld": 56,
                "high-critical-threshold": 56,
                "high-normal-threshold": 46,
                "location": "Switch 1",
                "low-critical-threshold": -10,
                "low-normal-threshold": 0,
                "name": "Inlet Temp Sensor",
                "reading": 32,
                "sensor-name": "temperature",
                "sensor-units": "celsius",
                "state": "Norm"
              },
              {
                "current-reading": 40,
                "hi-major-thrsld": 125,
                "hi-minor-thrsld": 125,
                "high-critical-threshold": 125,
                "high-normal-threshold": 105,
                "location": "Switch 1",
                "low-critical-threshold": -10,
                "low-normal-threshold": 0,
                "name": "Outlet Temp Sensor",
                "reading": 40,
                "sensor-name": "temperature",
                "sensor-units": "celsius",
                "state": "Norm"
              },
              {
                "current-reading": 56,
                "hi-major-thrsld": 125,
                "hi-minor-thrsld": 125,
                "high-critical-threshold": 125,
                "high-normal-threshold": 105,
                "location": "Switch 1",
                "low-critical-threshold": -10,
                "low-normal-threshold": 0,
                "name": "HotSpot Temp Sensor",
                "reading": 56,
                "sensor-name": "temperature",
                "sensor-units": "celsius",
                "state": "Norm"
              },
              {
                "current-reading": 31,
                "hi-major-thrsld": 56,
                "hi-minor-thrsld": 56,
                "high-critical-threshold": 56,
                "high-normal-threshold": 46,
                "location": "Switch 2",
                "low-critical-threshold": -10,
                "low-normal-threshold": 0,
                "name": "Inlet Temp Sensor",
                "reading": 31,
                "sensor-name": "temperature",
                "sensor-units": "celsius",
                "state": "Norm"
              },
              {
                "current-reading": 40,
                "hi-major-thrsld": 125,
                "hi-minor-thrsld": 125,
                "high-critical-threshold": 125,
                "high-normal-threshold": 105,
                "location": "Switch 2",
                "low-critical-threshold": -10,
                "low-normal-threshold": 0,
                "name": "Outlet Temp Sensor",
                "reading": 40,
                "sensor-name": "temperature",
                "sensor-units": "celsius",
                "state": "Norm"
              },
              {
                "current-reading": 55,
                "hi-major-thrsld": 125,
                "hi-minor-thrsld": 125,
                "high-critical-threshold": 125,
                "high-normal-threshold": 105,
                "location": "Switch 2",
                "low-critical-threshold": -10,
                "low-normal-threshold": 0,
                "name": "HotSpot Temp Sensor",
                "reading": 55,
                "sensor-name": "temperature",
                "sensor-units": "celsius",
                "state": "Norm"
              },
              {
                "current-reading": 32,
                "hi-major-thrsld": 56,
                "hi-minor-thrsld": 56,
                "high-critical-threshold": 56,
                "high-normal-threshold": 46,
                "location": "Switch 3",
                "low-critical-threshold": -10,
                "low-normal-threshold": 0,
                "name": "Inlet Temp Sensor",
                "reading": 32,
                "sensor-name": "temperature",
                "sensor-units": "celsius",
                "state": "Norm"
              },
              {
                "current-reading": 39,
                "hi-major-thrsld": 125,
                "hi-minor-thrsld": 125,
                "high-critical-threshold": 125,
                "high-normal-threshold": 105,
                "location": "Switch 3",
                "low-critical-threshold": -10,
                "low-normal-threshold": 0,
                "name": "Outlet Temp Sensor",
                "reading": 39,
                "sensor-name": "temperature",
                "sensor-units": "celsius",
                "state": "Norm"
              },
              {
                "current-reading": 53,
                "hi-major-thrsld": 125,
                "hi-minor-thrsld": 125,
                "high-critical-threshold": 125,
                "high-normal-threshold": 105,
                "location": "Switch 3",
                "low-critical-threshold": -10,
                "low-normal-threshold": 0,
                "name": "HotSpot Temp Sensor",
                "reading": 53,
                "sensor-name": "temperature",
                "sensor-units": "celsius",
                "state": "Norm"
              },
              {
                "current-reading": 32,
                "hi-major-thrsld": 56,
                "hi-minor-thrsld": 56,
                "high-critical-threshold": 56,
                "high-normal-threshold": 46,
                "location": "Switch 4",
                "low-critical-threshold": -10,
                "low-normal-threshold": 0,
                "name": "Inlet Temp Sensor",
                "reading": 32,
                "sensor-name": "temperature",
                "sensor-units": "celsius",
                "state": "Norm"
              },
              {
                "current-reading": 39,
                "hi-major-thrsld": 125,
                "hi-minor-thrsld": 125,
                "high-critical-threshold": 125,
                "high-normal-threshold": 105,
                "location": "Switch 4",
                "low-critical-threshold": -10,
                "low-normal-threshold": 0,
                "name": "Outlet Temp Sensor",
                "reading": 39,
                "sensor-name": "temperature",
                "sensor-units": "celsius",
                "state": "Norm"
              },
              {
                "current-reading": 52,
                "hi-major-thrsld": 125,
                "hi-minor-thrsld": 125,
                "high-critical-threshold": 125,
                "high-normal-threshold": 105,
                "location": "Switch 4",
                "low-critical-threshold": -10,
                "low-normal-threshold": 0,
                "name": "HotSpot Temp Sensor",
                "reading": 52,
                "sensor-name": "temperature",
                "sensor-units": "celsius",
                "state": "Norm"
              },
              {
                "current-reading": 35,
                "hi-major-thrsld": 56,
                "hi-minor-thrsld": 56,
                "high-critical-threshold": 56,
                "high-normal-threshold": 46,
                "location": "Switch 5",
                "low-critical-threshold": -10,
                "low-normal-threshold": 0,
                "name": "Inlet Temp Sensor",
                "reading": 35,
                "sensor-name": "temperature",
                "sensor-units": "celsius",
                "state": "Norm"
              },
              {
                "current-reading": 45,
                "hi-major-thrsld": 125,
                "hi-minor-thrsld": 125,
                "high-critical-threshold": 125,
                "high-normal-threshold": 105,
                "location": "Switch 5",
                "low-critical-threshold": -10,
                "low-normal-threshold": 0,
                "name": "Outlet Temp Sensor",
                "reading": 45,
                "sensor-name": "temperature",
                "sensor-units": "celsius",
                "state": "Norm"
              },
              {
                "current-reading": 73,
                "hi-major-thrsld": 125,
                "hi-minor-thrsld": 125,
                "high-critical-threshold": 125,
                "high-normal-threshold": 105,
                "location": "Switch 5",
                "low-critical-threshold": -10,
                "low-normal-threshold": 0,
                "name": "HotSpot Temp Sensor",
                "reading": 73,
                "sensor-name": "temperature",
                "sensor-units": "celsius",
                "state": "Norm"
              },
              {
                "current-reading": 34,
                "hi-major-thrsld": 56,
                "hi-minor-thrsld": 56,
                "high-critical-threshold": 56,
                "high-normal-threshold": 46,
                "location": "Switch 6",
                "low-critical-threshold": -10,
                "low-normal-threshold": 0,
                "name": "Inlet Temp Sensor",
                "reading": 34,
                "sensor-name": "temperature",
                "sensor-units": "celsius",
                "state": "Norm"
              },
              {
                "current-reading": 36,
                "hi-major-thrsld": 125,
                "hi-minor-thrsld": 125,
                "high-critical-threshold": 125,
                "high-normal-threshold": 105,
                "location": "Switch 6",
                "low-critical-threshold": -10,
                "low-normal-threshold": 0,
                "name": "Outlet Temp Sensor",
                "reading": 36,
                "sensor-name": "temperature",
                "sensor-units": "celsius",
                "state": "Norm"
              },
              {
                "current-reading": 48,
                "hi-major-thrsld": 125,
                "hi-minor-thrsld": 125,
                "high-critical-threshold": 125,
                "high-normal-threshold": 105,
                "location": "Switch 6",
                "low-critical-threshold": -10,
                "low-normal-threshold": 0,
                "name": "HotSpot Temp Sensor",
                "reading": 48,
                "sensor-name": "temperature",
                "sensor-units": "celsius",
                "state": "Norm"
              },
              {
                "current-reading": 33,
                "hi-major-thrsld": 56,
                "hi-minor-thrsld": 56,
                "high-critical-threshold": 56,
                "high-normal-threshold": 46,
                "location": "Switch 7",
                "low-critical-threshold": -10,
                "low-normal-threshold": 0,
                "name": "Inlet Temp Sensor",
                "reading": 33,
                "sensor-name": "temperature",
                "sensor-units": "celsius",
                "state": "Norm"
              },
              {
                "current-reading": 47,
                "hi-major-thrsld": 125,
                "hi-minor-thrsld": 125,
                "high-critical-threshold": 125,
                "high-normal-threshold": 105,
                "location": "Switch 7",
                "low-critical-threshold": -10,
                "low-normal-threshold": 0,
                "name": "Outlet Temp Sensor",
                "reading": 47,
                "sensor-name": "temperature",
                "sensor-units": "celsius",
                "state": "Norm"
              },
              {
                "current-reading": 73,
                "hi-major-thrsld": 125,
                "hi-minor-thrsld": 125,
                "high-critical-threshold": 125,
                "high-normal-threshold": 105,
                "location": "Switch 7",
                "low-critical-threshold": -10,
                "low-normal-threshold": 0,
                "name": "HotSpot Temp Sensor",
                "reading": 73,
                "sensor-name": "temperature",
                "sensor-units": "celsius",
                "state": "Norm"
              },
              {
                "current-reading": 32,
                "hi-major-thrsld": 56,
                "hi-minor-thrsld": 56,
                "high-critical-threshold": 56,
                "high-normal-threshold": 46,
                "location": "Switch 8",
                "low-critical-threshold": -10,
                "low-normal-threshold": 0,
                "name": "Inlet Temp Sensor",
                "reading": 32,
                "sensor-name": "temperature",
                "sensor-units": "celsius",
                "state": "Norm"
              },
              {
                "current-reading": 46,
                "hi-major-thrsld": 125,
                "hi-minor-thrsld": 125,
                "high-critical-threshold": 125,
                "high-normal-threshold": 105,
                "location": "Switch 8",
                "low-critical-threshold": -10,
                "low-normal-threshold": 0,
                "name": "Outlet Temp Sensor",
                "reading": 46,
                "sensor-name": "temperature",
                "sensor-units": "celsius",
                "state": "Norm"
              },
              {
                "current-reading": 73,
                "hi-major-thrsld": 125,
                "hi-minor-thrsld": 125,
                "high-critical-threshold": 125,
                "high-normal-threshold": 105,
                "location": "Switch 8",
                "low-critical-threshold": -10,
                "low-normal-threshold": 0,
                "name": "HotSpot Temp Sensor",
                "reading": 73,
                "sensor-name": "temperature",
                "sensor-units": "celsius",
                "state": "Norm"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 1",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "FAN - T1 1",
                "reading": 0,
                "sensor-name": "fan",
                "sensor-units": "revolutions-per-minute",
                "state": "Norm"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 1",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "FAN - T1 2",
                "reading": 0,
                "sensor-name": "fan",
                "sensor-units": "revolutions-per-minute",
                "state": "Norm"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 1",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "FAN - T1 3",
                "reading": 0,
                "sensor-name": "fan",
                "sensor-units": "revolutions-per-minute",
                "state": "Norm"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 2",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "FAN - T1 1",
                "reading": 0,
                "sensor-name": "fan",
                "sensor-units": "revolutions-per-minute",
                "state": "Norm"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 2",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "FAN - T1 2",
                "reading": 0,
                "sensor-name": "fan",
                "sensor-units": "revolutions-per-minute",
                "state": "Norm"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 2",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "FAN - T1 3",
                "reading": 0,
                "sensor-name": "fan",
                "sensor-units": "revolutions-per-minute",
                "state": "Norm"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 3",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "FAN - T1 1",
                "reading": 0,
                "sensor-name": "fan",
                "sensor-units": "revolutions-per-minute",
                "state": "Norm"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 3",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "FAN - T1 2",
                "reading": 0,
                "sensor-name": "fan",
                "sensor-units": "revolutions-per-minute",
                "state": "Norm"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 3",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "FAN - T1 3",
                "reading": 0,
                "sensor-name": "fan",
                "sensor-units": "revolutions-per-minute",
                "state": "Norm"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 4",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "FAN - T1 1",
                "reading": 0,
                "sensor-name": "fan",
                "sensor-units": "revolutions-per-minute",
                "state": "Norm"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 4",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "FAN - T1 2",
                "reading": 0,
                "sensor-name": "fan",
                "sensor-units": "revolutions-per-minute",
                "state": "Norm"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 4",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "FAN - T1 3",
                "reading": 0,
                "sensor-name": "fan",
                "sensor-units": "revolutions-per-minute",
                "state": "Norm"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 5",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "FAN - T1 1",
                "reading": 0,
                "sensor-name": "fan",
                "sensor-units": "revolutions-per-minute",
                "state": "Norm"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 5",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "FAN - T1 2",
                "reading": 0,
                "sensor-name": "fan",
                "sensor-units": "revolutions-per-minute",
                "state": "Norm"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 5",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "FAN - T1 3",
                "reading": 0,
                "sensor-name": "fan",
                "sensor-units": "revolutions-per-minute",
                "state": "Norm"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 6",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "FAN - T1 1",
                "reading": 0,
                "sensor-name": "fan",
                "sensor-units": "revolutions-per-minute",
                "state": "Norm"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 6",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "FAN - T1 2",
                "reading": 0,
                "sensor-name": "fan",
                "sensor-units": "revolutions-per-minute",
                "state": "Norm"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 6",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "FAN - T1 3",
                "reading": 0,
                "sensor-name": "fan",
                "sensor-units": "revolutions-per-minute",
                "state": "Norm"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 7",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "FAN - T1 1",
                "reading": 0,
                "sensor-name": "fan",
                "sensor-units": "revolutions-per-minute",
                "state": "Norm"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 7",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "FAN - T1 2",
                "reading": 0,
                "sensor-name": "fan",
                "sensor-units": "revolutions-per-minute",
                "state": "Norm"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 7",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "FAN - T1 3",
                "reading": 0,
                "sensor-name": "fan",
                "sensor-units": "revolutions-per-minute",
                "state": "Norm"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 8",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "FAN - T1 1",
                "reading": 0,
                "sensor-name": "fan",
                "sensor-units": "revolutions-per-minute",
                "state": "Norm"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 8",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "FAN - T1 2",
                "reading": 0,
                "sensor-name": "fan",
                "sensor-units": "revolutions-per-minute",
                "state": "Norm"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 8",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "FAN - T1 3",
                "reading": 0,
                "sensor-name": "fan",
                "sensor-units": "revolutions-per-minute",
                "state": "Norm"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 1",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "Power Supply A",
                "reading": 0,
                "sensor-name": "power",
                "sensor-units": "watts",
                "state": "Norm"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 1",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "Power Supply B",
                "reading": 0,
                "sensor-name": "power",
                "sensor-units": "watts",
                "state": "NotExist"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 2",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "Power Supply A",
                "reading": 0,
                "sensor-name": "power",
                "sensor-units": "watts",
                "state": "Norm"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 2",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "Power Supply B",
                "reading": 0,
                "sensor-name": "power",
                "sensor-units": "watts",
                "state": "NotExist"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 3",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "Power Supply A",
                "reading": 0,
                "sensor-name": "power",
                "sensor-units": "watts",
                "state": "Norm"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 3",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "Power Supply B",
                "reading": 0,
                "sensor-name": "power",
                "sensor-units": "watts",
                "state": "NotExist"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 4",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "Power Supply A",
                "reading": 0,
                "sensor-name": "power",
                "sensor-units": "watts",
                "state": "Norm"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 4",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "Power Supply B",
                "reading": 0,
                "sensor-name": "power",
                "sensor-units": "watts",
                "state": "NotExist"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 5",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "Power Supply A",
                "reading": 0,
                "sensor-name": "power",
                "sensor-units": "watts",
                "state": "Norm"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 5",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "Power Supply B",
                "reading": 0,
                "sensor-name": "power",
                "sensor-units": "watts",
                "state": "NotExist"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 6",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "Power Supply A",
                "reading": 0,
                "sensor-name": "power",
                "sensor-units": "watts",
                "state": "Norm"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 6",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "Power Supply B",
                "reading": 0,
                "sensor-name": "power",
                "sensor-units": "watts",
                "state": "NotExist"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 7",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "Power Supply A",
                "reading": 0,
                "sensor-name": "power",
                "sensor-units": "watts",
                "state": "Norm"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 7",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "Power Supply B",
                "reading": 0,
                "sensor-name": "power",
                "sensor-units": "watts",
                "state": "NotExist"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 8",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "Power Supply A",
                "reading": 0,
                "sensor-name": "power",
                "sensor-units": "watts",
                "state": "Norm"
              },
              {
                "current-reading": 0,
                "hi-major-thrsld": 0,
                "hi-minor-thrsld": 0,
                "high-critical-threshold": 0,
                "high-normal-threshold": 0,
                "location": "Switch 8",
                "low-critical-threshold": 0,
                "low-normal-threshold": 0,
                "name": "Power Supply B",
                "reading": 0,
                "sensor-name": "power",
                "sensor-units": "watts",
                "state": "NotExist"
              }
            ]
          }
        }
      }
    ]
  }
]
```

</details>

### Cisco NTP operational Get

```bash
gnmic get \
  --path 'rfc7951:/Cisco-IOS-XE-ntp-oper:ntp-oper-data/ntp-status-info' \
  --encoding json_ietf
```

**Observed:** Two NTP associations were returned. The captured status reports stratum 16 and rejected peers; peer addresses are redacted. This is a point-in-time operational result, not a Set example. The complete sanitized response is saved as [JSON](captures/cisco-ntp-oper-get.json).

<details>
<summary>Full response — expand</summary>

```json
[
  {
    "source": "<DEVICE_ADDRESS>:9339",
    "timestamp": 1792000746809546157,
    "time": "2026-10-14T10:59:06.809546157-07:00",
    "updates": [
      {
        "Path": "rfc7951:Cisco-IOS-XE-ntp-oper:ntp-oper-data/ntp-status-info",
        "values": {
          "Cisco-IOS-XE-ntp-oper:ntp-oper-data/ntp-status-info": {
            "freq-drift-ppm": "0.0",
            "ntp-associations": [
              {
                "assoc-id": 21402,
                "delay": "0.0",
                "jitter": "0.0",
                "last-peer-event": "ntp-peer-event-mobilize",
                "last-poll-time": "0",
                "ntp-address": {
                  "ip-addr": "<REDACTED_IP>",
                  "vrf-name": "default"
                },
                "num-events": 1,
                "offset": "0.0",
                "peer-authentication-status": "ntp-auth-none",
                "peer-reach": 0,
                "peer-selection-status": "ntp-peer-rejected",
                "peer-stratum": 16,
                "poll": 6,
                "psw-crypto": "crypto-flag-sig",
                "refid": {
                  "kod-data": {
                    "kod-type": "ntp-ref-acst"
                  }
                },
                "reftime": "1970-01-01T00:00:00+00:00",
                "serv-type": "ntp-server"
              },
              {
                "assoc-id": 21403,
                "delay": "0.0",
                "jitter": "0.0",
                "last-peer-event": "ntp-peer-event-mobilize",
                "last-poll-time": "0",
                "ntp-address": {
                  "ip-addr": "<REDACTED_IP>",
                  "vrf-name": "default"
                },
                "num-events": 1,
                "offset": "0.0",
                "peer-authentication-status": "ntp-auth-none",
                "peer-reach": 0,
                "peer-selection-status": "ntp-peer-rejected",
                "peer-stratum": 16,
                "poll": 6,
                "psw-crypto": "crypto-flag-sig",
                "refid": {
                  "kod-data": {
                    "kod-type": "ntp-ref-acst"
                  }
                },
                "reftime": "1970-01-01T00:00:00+00:00",
                "serv-type": "ntp-server"
              }
            ],
            "offset": "0.0",
            "refid": {
              "kod-data": {
                "kod-type": "ntp-ref-init"
              }
            },
            "reftime": "1970-01-01T00:00:00+00:00",
            "root-delay": "0.0",
            "root-disp": "9.0",
            "stratum": 16,
            "sys-poll": 3
          }
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
reported the VLAN active with an empty ports list immediately after the Set.
Persistence across the subsequent device reload is unverified. The first Set
attempt timed out and IOS XE reported
a configuration database lock; after the lock cleared, the retry above
succeeded. For any timed-out Set, Get the path before retrying.

### Cisco native interface description

No live Set was sent through Cisco native for interface descriptions. The live
interface-description examples below use OpenConfig and IETF models on the
owner-approved port. This guide avoids local request-render-only Set examples.

### Set operation coverage by model

`SetRequest` has three core operations: `Update`, `Replace`, and `Delete`.
This target advertises gNMI version 0.7.0. The gNMI specification added
`union_replace` in version 0.10.0, so treat it as unavailable here even though
gNMIc's local CLI exposes a `UnionReplace` option. The table distinguishes verified live operations from combinations that were
not collected or are not applicable.

| Data model and path | Update | Replace | Delete | UnionReplace | What this guide verified |
|---|---|---|---|---|---|
| Cisco native hostname | Live | Live | Not applicable: mandatory leaf | Not verified | Update and Replace were applied and rolled back |
| Cisco native VLAN name | Live; final restore verified | Live | Not collected | Not supported by advertised gNMI version | VLAN 899 is `GNMI-LAB`; a same-value Replace was verified after restoration |
| Cisco native interface description | Not collected | Not collected | Not collected | Not supported by advertised gNMI version | No live interface change; examples use OpenConfig and IETF models |
| OpenConfig interface `config/enabled` | Live | Not collected | Not collected | Not supported by advertised gNMI version | Enabled a lab interface briefly, then restored `false`; Gets confirmed both states |
| OpenConfig interface `config/description` | Live | Live | Live | Not supported by advertised gNMI version | On port 4/0/1, Update and Replace set `GNMI-LAB-TEST`; Delete restored the original empty value; each step was verified with Get |
| IETF interface `description` | Live | Live | Live | Not supported by advertised gNMI version | Same temporary value and port; Update/Replace/Delete all succeeded; final Get in both models returned empty |
| `Cisco-IOS-XE-interfaces-oper`, `Cisco-IOS-XE-vlan-oper`, `Cisco-IOS-XE-process-cpu-oper`, `Cisco-IOS-XE-memory-oper`, `Cisco-IOS-XE-environment-oper`, `Cisco-IOS-XE-ntp-oper`, `ietf-interfaces:interfaces-state` | Not applicable | Not applicable | Not applicable | Not applicable | Operational state is read-only |
| `Cisco-IOS-XE-gnmi-cfg` secure-port | Excluded | Excluded | Excluded | Not supported by advertised gNMI version | Read-only final Get returned 9339; no Set was issued and the port was not changed |
| `Cisco-IOS-XE-mdt-cfg` subscription stream leaf | No live write | No live write | No live write | Not supported by advertised gNMI version | Read-only Get only; telemetry changes need a specifically authorized target and value |
| `Cisco-IOS-XE-ntp`, `Cisco-IOS-XE-yang-interfaces-cfg` | No live write | No live write | No live write | Not supported by advertised gNMI version | Time configuration and YANG/AAA model exposure were outside the authorized writes; no Set leaf template is claimed |
| `Cisco-IOS-XE-audit-cfg`, `Cisco-IOS-XE-aws-common-cfg`, `Cisco-IOS-XE-aws-cw-cfg`, `Cisco-IOS-XE-aws-s3-cfg`, `Cisco-IOS-XE-cloud-services-cfg`, `Cisco-IOS-XE-grpc-tunnel-cfg`, `Cisco-IOS-XE-ncch-cfg` | Not collected | Not collected | Not collected | Not supported by advertised gNMI version | Advertised in Capabilities, but no narrow live Get/schema review was done; no Set path or response is claimed |

### VLAN-name Replace

After VLAN 899 was restored to `GNMI-LAB`, Replace wrote that same current
value to the name leaf. It returned a `REPLACE` SetResponse and the following
Get returned `GNMI-LAB`. This verified Replace without changing the VLAN.
Delete was not sent because it would remove the lab VLAN.

```bash
gnmic set --replace \
  'rfc7951:/Cisco-IOS-XE-native:native/vlan/Cisco-IOS-XE-vlan:vlan-list[id=899]/name:::string:::GNMI-LAB'
```

The complete sanitized SetResponse and Get are in
[vlan-name-replace.ndjson](captures/vlan-name-replace.ndjson).

OpenConfig interface description: verified live on the user-approved connected
port. The original description was empty. Update and Replace wrote
`GNMI-LAB-TEST`; Delete restored the empty value, with a Get after every Set.

```bash
IFACE='TwoGigabitEthernet4/0/1'
TEST_DESCRIPTION='GNMI-LAB-TEST'
OC_DESC="openconfig:/interfaces/interface[name=${IFACE}]/config/description"
gnmic set --update "${OC_DESC}:::string:::${TEST_DESCRIPTION}"
gnmic set --replace "${OC_DESC}:::string:::${TEST_DESCRIPTION}"
gnmic set --delete "${OC_DESC}"
```

IETF `interfaces/interface/description` was verified with the same three live
operations and temporary value:

```bash
IFACE='TwoGigabitEthernet4/0/1'
TEST_DESCRIPTION='GNMI-LAB-TEST'
IETF_DESC="rfc7951:/ietf-interfaces:interfaces/interface[name=${IFACE}]/description"
gnmic set --update "${IETF_DESC}:::string:::${TEST_DESCRIPTION}"
gnmic set --replace "${IETF_DESC}:::string:::${TEST_DESCRIPTION}"
gnmic set --delete "${IETF_DESC}"
```

The `interfaces-state` tree is the IETF operational tree and cannot accept
these configuration operations. The full sanitized SetResponse/Get sequence
for both models is in
[interface-descriptions-set.ndjson](captures/interface-descriptions-set.ndjson).
Both description leaves ended in their original empty state. The gNMI listener
and port were not changed; final Get returned secure-port 9339. Other unverified paths are not presented as live
Set examples; see the focused [Set notes](examples/set.md).

<details>
<summary>Full sanitized description Set/Get responses — expand</summary>

```text
{"source":"<DEVICE_ADDRESS>:9339","timestamp":1792007287448815358,"time":"2026-10-14T12:48:07.448815358-07:00","updates":[{"Path":"openconfig:interfaces/interface[name=TwoGigabitEthernet4/0/1]/config/description","values":{"interfaces/interface/config/description":""}}]}
{"source":"<DEVICE_ADDRESS>:9339","timestamp":1792007287454618363,"time":"2026-10-14T12:48:07.454618363-07:00","updates":[{"Path":"rfc7951:ietf-interfaces:interfaces/interface[name=TwoGigabitEthernet4/0/1]/description","values":{"ietf-interfaces:interfaces/interface/description":""}}]}
{"source":"<DEVICE_ADDRESS>:9339","timestamp":1792007316341638969,"time":"2026-10-14T12:48:36.341638969-07:00","results":[{"operation":"UPDATE","path":"openconfig:interfaces/interface[name=TwoGigabitEthernet4/0/1]/config/description"}]}
{"source":"<DEVICE_ADDRESS>:9339","timestamp":1792007319624828774,"time":"2026-10-14T12:48:39.624828774-07:00","updates":[{"Path":"openconfig:interfaces/interface[name=TwoGigabitEthernet4/0/1]/config/description","values":{"interfaces/interface/config/description":"GNMI-LAB-TEST"}}]}
{"source":"<DEVICE_ADDRESS>:9339","timestamp":1792007333766533740,"time":"2026-10-14T12:48:53.76653374-07:00","results":[{"operation":"REPLACE","path":"openconfig:interfaces/interface[name=TwoGigabitEthernet4/0/1]/config/description"}]}
{"source":"<DEVICE_ADDRESS>:9339","timestamp":1792007334677158116,"time":"2026-10-14T12:48:54.677158116-07:00","updates":[{"Path":"openconfig:interfaces/interface[name=TwoGigabitEthernet4/0/1]/config/description","values":{"interfaces/interface/config/description":"GNMI-LAB-TEST"}}]}
{"source":"<DEVICE_ADDRESS>:9339","timestamp":1792007348997642232,"time":"2026-10-14T12:49:08.997642232-07:00","results":[{"operation":"DELETE","path":"openconfig:interfaces/interface[name=TwoGigabitEthernet4/0/1]/config/description"}]}
{"source":"<DEVICE_ADDRESS>:9339","timestamp":1792007352319799603,"time":"2026-10-14T12:49:12.319799603-07:00","updates":[{"Path":"openconfig:interfaces/interface[name=TwoGigabitEthernet4/0/1]/config/description","values":{"interfaces/interface/config/description":""}}]}
{"source":"<DEVICE_ADDRESS>:9339","timestamp":1792007369403941072,"time":"2026-10-14T12:49:29.403941072-07:00","results":[{"operation":"UPDATE","path":"rfc7951:ietf-interfaces:interfaces/interface[name=TwoGigabitEthernet4/0/1]/description"}]}
{"source":"<DEVICE_ADDRESS>:9339","timestamp":1792007372582310036,"time":"2026-10-14T12:49:32.582310036-07:00","updates":[{"Path":"rfc7951:ietf-interfaces:interfaces/interface[name=TwoGigabitEthernet4/0/1]/description","values":{"ietf-interfaces:interfaces/interface/description":"GNMI-LAB-TEST"}}]}
{"source":"<DEVICE_ADDRESS>:9339","timestamp":1792007387068105863,"time":"2026-10-14T12:49:47.068105863-07:00","results":[{"operation":"REPLACE","path":"rfc7951:ietf-interfaces:interfaces/interface[name=TwoGigabitEthernet4/0/1]/description"}]}
{"source":"<DEVICE_ADDRESS>:9339","timestamp":1792007388153767122,"time":"2026-10-14T12:49:48.153767122-07:00","updates":[{"Path":"rfc7951:ietf-interfaces:interfaces/interface[name=TwoGigabitEthernet4/0/1]/description","values":{"ietf-interfaces:interfaces/interface/description":"GNMI-LAB-TEST"}}]}
{"source":"<DEVICE_ADDRESS>:9339","timestamp":1792007402792792324,"time":"2026-10-14T12:50:02.792792324-07:00","results":[{"operation":"DELETE","path":"rfc7951:ietf-interfaces:interfaces/interface[name=TwoGigabitEthernet4/0/1]/description"}]}
{"source":"<DEVICE_ADDRESS>:9339","timestamp":1792007405941201983,"time":"2026-10-14T12:50:05.941201983-07:00","updates":[{"Path":"rfc7951:ietf-interfaces:interfaces/interface[name=TwoGigabitEthernet4/0/1]/description","values":{"ietf-interfaces:interfaces/interface/description":""}}]}
{"source":"<DEVICE_ADDRESS>:9339","timestamp":1792007422246089149,"time":"2026-10-14T12:50:22.246089149-07:00","updates":[{"Path":"openconfig:interfaces/interface[name=TwoGigabitEthernet4/0/1]/config/description","values":{"interfaces/interface/config/description":""}}]}
{"source":"<DEVICE_ADDRESS>:9339","timestamp":1792007422250869506,"time":"2026-10-14T12:50:22.250869506-07:00","updates":[{"Path":"rfc7951:ietf-interfaces:interfaces/interface[name=TwoGigabitEthernet4/0/1]/description","values":{"ietf-interfaces:interfaces/interface/description":""}}]}
{"source":"<DEVICE_ADDRESS>:9339","timestamp":1792007883721940829,"time":"2026-10-14T12:58:03.721940829-07:00","updates":[{"Path":"rfc7951:Cisco-IOS-XE-gnmi-cfg:gnmi-cfg-data/config/secure-port","values":{"Cisco-IOS-XE-gnmi-cfg:gnmi-cfg-data/config/secure-port":9339}}]}
{"source":"<DEVICE_ADDRESS>:9339","timestamp":1792007883729119834,"time":"2026-10-14T12:58:03.729119834-07:00","updates":[{"Path":"openconfig:interfaces/interface[name=TwoGigabitEthernet4/0/1]/config/description","values":{"interfaces/interface/config/description":""}}]}
{"source":"<DEVICE_ADDRESS>:9339","timestamp":1792007883733145787,"time":"2026-10-14T12:58:03.733145787-07:00","updates":[{"Path":"rfc7951:ietf-interfaces:interfaces/interface[name=TwoGigabitEthernet4/0/1]/description","values":{"ietf-interfaces:interfaces/interface/description":""}}]}
```

</details>

The gNMI service and MDT configuration rows are read-only examples in this
guide. No Set command is included for the gNMI port, and no live telemetry
configuration change was authorized.

### Verified OpenConfig interface Set Update

For the Subscribe examples, the device showed `<REDACTED_INTERFACE>` as
admin-down with operational state `not-present`, no description, and no IP
address. OpenConfig `config/enabled` was temporarily set to `true` and restored
to `false`. The interface remained `not-present` throughout; Gets confirmed
admin status changed to `UP`, then back to `DOWN`.

```bash
IFACE='MEMBER/PORT'
ENABLE_PATH="openconfig:/interfaces/interface[name=${IFACE}]/config/enabled"
gnmic set --update "${ENABLE_PATH}:::bool:::true"
gnmic set --update "${ENABLE_PATH}:::bool:::false"
```

<details>
<summary>SetResponse and verification summaries — expand</summary>

Temporary SetResponse:

```json
{
  "source": "<DEVICE_ADDRESS>:9339",
  "timestamp": 1792001580558886196,
  "time": "2026-10-14T11:13:00.558886196-07:00",
  "results": [
    {
      "operation": "UPDATE",
      "path": "openconfig:interfaces/interface[name=<REDACTED_INTERFACE>]/config/enabled"
    }
  ]
}
```

After enabling, Get returned `config/enabled: true` and `state/admin-status: UP`.
The restore SetResponse acknowledged the same Update operation; after restore,
Get returned `config/enabled: false`, `state/admin-status: DOWN`, Cisco
`admin-status: if-state-down`, and Cisco `oper-status: if-oper-state-not-present`.
The complete on-change initial notification is saved in
[interface-onchange-initial.ndjson](captures/interface-onchange-initial.ndjson).

</details>

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

### IETF interface periodic sample

This 3-second `SAMPLE` subscription returned the initial `up` state, sync
response, and repeated `up` updates for keyed interface
`TwoGigabitEthernet4/0/1`. It reads operational data under IETF
`interfaces-state`:

```bash
IFACE='TwoGigabitEthernet4/0/1'
gnmic subscribe \
  --path "rfc7951:/ietf-interfaces:interfaces-state/interface[name=${IFACE}]/oper-status" \
  --mode stream \
  --stream-mode sample \
  --sample-interval 3s
```

See full sanitized [IETF sample output](captures/ietf-interfaces-sample.ndjson).

<details>
<summary>Initial response, sync, and repeated sample values — expand</summary>

```text
{"source":"<DEVICE_ADDRESS>:9339","subscription-name":"default-1792006690","timestamp":1792006202957251000,"time":"2026-10-14T12:30:02.957251-07:00","updates":[{"Path":"rfc7951:ietf-interfaces:interfaces-state/interface[name=TwoGigabitEthernet4/0/1]/oper-status","values":{"ietf-interfaces:interfaces-state/interface/oper-status":"up"}}]}
{"source":"<DEVICE_ADDRESS>:9339","subscription-name":"default-1792006690","timestamp":1792006202958414000,"time":"2026-10-14T12:30:02.958414-07:00"}
{"sync-response":true}
{"source":"<DEVICE_ADDRESS>:9339","subscription-name":"default-1792006690","timestamp":1792006205876262000,"time":"2026-10-14T12:30:05.876262-07:00","updates":[{"Path":"rfc7951:ietf-interfaces:interfaces-state/interface[name=TwoGigabitEthernet4/0/1]/oper-status","values":{"ietf-interfaces:interfaces-state/interface/oper-status":"up"}}]}
{"source":"<DEVICE_ADDRESS>:9339","subscription-name":"default-1792006690","timestamp":1792006208906869000,"time":"2026-10-14T12:30:08.906869-07:00","updates":[{"Path":"rfc7951:ietf-interfaces:interfaces-state/interface[name=TwoGigabitEthernet4/0/1]/oper-status","values":{"ietf-interfaces:interfaces-state/interface/oper-status":"up"}}]}
{"source":"<DEVICE_ADDRESS>:9339","subscription-name":"default-1792006690","timestamp":1792006211873787000,"time":"2026-10-14T12:30:11.873787-07:00","updates":[{"Path":"rfc7951:ietf-interfaces:interfaces-state/interface[name=TwoGigabitEthernet4/0/1]/oper-status","values":{"ietf-interfaces:interfaces-state/interface/oper-status":"up"}}]}
{"source":"<DEVICE_ADDRESS>:9339","subscription-name":"default-1792006690","timestamp":1792006214875611000,"time":"2026-10-14T12:30:14.875611-07:00","updates":[{"Path":"rfc7951:ietf-interfaces:interfaces-state/interface[name=TwoGigabitEthernet4/0/1]/oper-status","values":{"ietf-interfaces:interfaces-state/interface/oper-status":"up"}}]}
```

</details>

### ONCE and target-defined stream

`ONCE` returned the initial `if-state-up` value for the connected port and
then closed. This CLI transcript contains a timestamp-only response and no
`sync-response` object:

```bash
IFACE='TwoGigabitEthernet4/0/1'
gnmic subscribe \
  --path "rfc7951:/Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=${IFACE}]/admin-status" \
  --mode once
```

See [interface-oper-once.ndjson](captures/interface-oper-once.ndjson). The
same path was tried in `target-defined` stream mode. No values arrived in
roughly 10 seconds before it was interrupted. This is inconclusive and does
not establish that the target rejects the mode.

<details>
<summary>Full ONCE response — expand</summary>

```text
{"source":"<DEVICE_ADDRESS>:9339","subscription-name":"default-1792006431","timestamp":1792005943842405000,"time":"2026-10-14T12:25:43.842405-07:00","updates":[{"Path":"rfc7951:Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=TwoGigabitEthernet4/0/1]/admin-status","values":{"Cisco-IOS-XE-interfaces-oper:interfaces/interface/admin-status":"if-state-up"}}]}
{"source":"<DEVICE_ADDRESS>:9339","subscription-name":"default-1792006431","timestamp":1792005943843457000,"time":"2026-10-14T12:25:43.843457-07:00"}
```

</details>

### Cisco memory periodic sampling result

A periodic stream to `rfc7951:/Cisco-IOS-XE-memory-oper:memory-statistics`
returned timestamp-only notifications and a sync response, but no `updates`
values, even though a Get to the same path succeeded. Preserve that distinction
when adapting the example. The complete sanitized output is in
[memory-oper-sample.ndjson](captures/memory-oper-sample.ndjson).

### On-change

```bash
gnmic subscribe \
  --path 'rfc7951:/Cisco-IOS-XE-vlan-oper:vlans/vlan[id=899]/name' \
  --mode stream \
  --stream-mode on_change
```

This path is covered by the device's MDT on-change capability entry. The
subscription emitted the initial VLAN-name update and sync response; it was
stopped with Ctrl+C. The [full sanitized response](captures/vlan-onchange-sync.ndjson)
redacts the device address. A later attempt to trigger a second event was
blocked by an IOS XE configuration database lock. A follow-up Get confirmed
that VLAN 899 remained `GNMI-LAB` at that time. After reload, gNMI reachability
and VLAN persistence were verified. On 2026-10-14, a later rename attempt
timed out; a subsequent Get returned `GNMI-LAB-EVENT`. The restore request to
`GNMI-LAB` also timed out and the immediate Get still returned that temporary
value. A later Get at 12:55 confirmed that the restore eventually applied and
the VLAN name was again `GNMI-LAB`; see the [final Get capture](captures/vlan-name-final-get.ndjson).

The OpenConfig interface `oper-status` path is not advertised for on-change
by this device, so use periodic sampling for it. Cisco IOS XE documents
streaming `SAMPLE` and `ON_CHANGE`, with on-change limited to paths advertised
by `Cisco-IOS-XE-mdt-capabilities-oper`. This C9300 also accepted interactive
gNMI `POLL` and `ONCE`. The supplied `/interfaces/interface/state/cpu`
example was tested on this same `.110` device. Unkeyed, it returned the CPU
flag for every interface; use the keyed form below to keep the collection
narrow.

An earlier test on a no-transceiver interface produced no follow-up
notification when its admin state changed. A second test used the user-selected
connected port `4/0/1` (YANG interface type `TwoGigabitEthernet`). Its initial
state was enabled/admin UP/oper UP. The ON_CHANGE stream then reported both the
shut and no-shut transitions. The port was restored to enabled/admin UP/oper
UP; the final Cisco oper state was `if-oper-state-ready`.

For this pattern, first Get the interface's OpenConfig `config/enabled` value
and confirm that it is `true` and safe to interrupt. Run the subscription in
one terminal, then use a second terminal to shut and restore it. Set `IFACE`
to the full interface name used by OpenConfig and Cisco interfaces-oper:

```bash
IFACE='TwoGigabitEthernet4/0/1'
gnmic -a "$GNMIC_ADDRESS" -u "$GNMIC_USERNAME" -p "$GNMIC_PASSWORD" \
  --skip-verify --encoding json_ietf subscribe \
  --path "rfc7951:/Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=${IFACE}]/admin-status" \
  --mode stream \
  --stream-mode on_change
```

```bash
IFACE='TwoGigabitEthernet4/0/1'
ENABLE_PATH="openconfig:/interfaces/interface[name=${IFACE}]/config/enabled"
gnmic -a "$GNMIC_ADDRESS" -u "$GNMIC_USERNAME" -p "$GNMIC_PASSWORD" \
  --skip-verify --encoding json_ietf set \
  --update "${ENABLE_PATH}:::bool:::false" # shut
gnmic -a "$GNMIC_ADDRESS" -u "$GNMIC_USERNAME" -p "$GNMIC_PASSWORD" \
  --skip-verify --encoding json_ietf set \
  --update "${ENABLE_PATH}:::bool:::true" # no shut; restore baseline
```

The output below is the captured stream. The device address is redacted; the
owner-selected interface ID is retained for this example. gNMIc printed the
initial update and both change updates; no `sync-response` object appeared in
this captured session.

<details>
<summary>Full ON_CHANGE stream and SetResponse objects — expand</summary>

```text
{"source":"<DEVICE_ADDRESS>:9339","subscription-name":"default-1792003670","timestamp":1792003183497701000,"time":"2026-10-14T11:39:43.497701-07:00","updates":[{"Path":"rfc7951:Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=TwoGigabitEthernet4/0/1]/admin-status","values":{"Cisco-IOS-XE-interfaces-oper:interfaces/interface/admin-status":"if-state-up"}}]}
{"source":"<DEVICE_ADDRESS>:9339","timestamp":1792003214913064434,"time":"2026-10-14T11:40:14.913064434-07:00","results":[{"operation":"UPDATE","path":"openconfig:interfaces/interface[name=TwoGigabitEthernet4/0/1]/config/enabled"}]}
{"source":"<DEVICE_ADDRESS>:9339","subscription-name":"default-1792003670","timestamp":1792003220127473000,"time":"2026-10-14T11:40:20.127473-07:00","updates":[{"Path":"rfc7951:Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=TwoGigabitEthernet4/0/1]/admin-status","values":{"Cisco-IOS-XE-interfaces-oper:interfaces/interface/admin-status":"if-state-down"}}]}
{"source":"<DEVICE_ADDRESS>:9339","timestamp":1792003239746253827,"time":"2026-10-14T11:40:39.746253827-07:00","results":[{"operation":"UPDATE","path":"openconfig:interfaces/interface[name=TwoGigabitEthernet4/0/1]/config/enabled"}]}
{"source":"<DEVICE_ADDRESS>:9339","subscription-name":"default-1792003670","timestamp":1792003248219897000,"time":"2026-10-14T11:40:48.219897-07:00","updates":[{"Path":"rfc7951:Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=TwoGigabitEthernet4/0/1]/admin-status","values":{"Cisco-IOS-XE-interfaces-oper:interfaces/interface/admin-status":"if-state-up"}}]}
```

The SetResponse timestamps pair with the false (`shut`) and true (`no shut`)
updates respectively. The final verification Get returned
`config/enabled: true`, OpenConfig admin/oper status `UP`, Cisco
`admin-status: if-state-up`, and Cisco `oper-status: if-oper-state-ready`.
The sanitized event/Set capture is also available as
[interface-onchange-shut-no-shut.ndjson](captures/interface-onchange-shut-no-shut.ndjson).

</details>

This test briefly interrupted the interface link. Both Set operations
succeeded, both state changes generated ON_CHANGE updates, and the original
enabled state was restored and verified.

### POLL subscription

The C9300 accepted a `POLL` subscription on the Cisco interface-oper
`admin-status` leaf. Unlike stream mode, gNMIc's poll mode waits for manual
poll requests. In the interactive selector, press Enter to choose the target,
then Enter again to choose the subscription; each selection sends a poll and
returns the current value. Press Ctrl+C to exit.

```bash
IFACE='MEMBER/PORT'
gnmic subscribe \
  --path "rfc7951:/Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=${IFACE}]/admin-status" \
  --mode poll
```

The initial response and one manual poll returned `if-state-down`. The first
sequence below is the initial update and sync response:

```text
{
  "timestamp": 1792001692792075000,
  "time": "2026-10-14T11:14:52.792075-07:00",
  "updates": [
    {
      "Path": "rfc7951:Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=<REDACTED_INTERFACE>]/admin-status",
      "values": {
        "Cisco-IOS-XE-interfaces-oper:interfaces/interface/admin-status": "if-state-down"
      }
    }
  ]
}
{
  "timestamp": 1792001692793312000,
  "time": "2026-10-14T11:14:52.793312-07:00"
}
{"sync-response": true}
```

Selecting that subscription to poll returned another update:

```text
{
  "timestamp": 1792001704239679000,
  "time": "2026-10-14T11:15:04.239679-07:00",
  "updates": [
    {
      "Path": "rfc7951:Cisco-IOS-XE-interfaces-oper:interfaces/interface[name=<REDACTED_INTERFACE>]/admin-status",
      "values": {
        "Cisco-IOS-XE-interfaces-oper:interfaces/interface/admin-status": "if-state-down"
      }
    }
  ]
}
{
  "timestamp": 1792001704240870000,
  "time": "2026-10-14T11:15:04.24087-07:00"
}
{"sync-response": true}
```

Full interactive terminal control characters are omitted from the transcript.

### POLL the interface CPU flag

The supplied path `/interfaces/interface/state/cpu` works on this C9300, but
without a list key it returned values across the full interface list. The
response was intentionally summarized rather than publishing the device's
complete interface inventory. This keyed form was verified on
`TwoGigabitEthernet4/0/1`; both the initial response and a manual poll returned
`false`:

```bash
IFACE='TwoGigabitEthernet4/0/1'
gnmic subscribe \
  --path "/interfaces/interface[name=${IFACE}]/state/cpu" \
  --mode poll
```

The initial update, sync response, and manually requested poll are preserved
in [interfaces-oper-poll.ndjson](captures/interfaces-oper-poll.ndjson).

<details>
<summary>Initial and polled response — expand</summary>

```text
{"timestamp":1792006358049932000,"time":"2026-10-14T12:32:38.049932-07:00","updates":[{"Path":"interfaces/interface[name=TwoGigabitEthernet4/0/1]/state/cpu","values":{"interfaces/interface/state/cpu":false}}]}
{"timestamp":1792006358051034000,"time":"2026-10-14T12:32:38.051034-07:00"}
{"sync-response":true}
{"timestamp":1792006368843668000,"time":"2026-10-14T12:32:48.843668-07:00","updates":[{"Path":"interfaces/interface[name=TwoGigabitEthernet4/0/1]/state/cpu","values":{"interfaces/interface/state/cpu":false}}]}
{"timestamp":1792006368844767000,"time":"2026-10-14T12:32:48.844767-07:00"}
```

</details>

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
- VLAN 899 was created as `GNMI-LAB`; post-reload Gets confirmed it persisted
  and was active with no assigned ports. A later rename and restore timed out,
  but a delayed Get confirmed the authorized restore eventually applied and
  returned the VLAN name to `GNMI-LAB`.
- Post-reload memory, environment, and NTP Gets succeeded.
- The no-transceiver test port `<REDACTED_INTERFACE>` was briefly enabled
  and restored to disabled. Gets verified `UP` then `DOWN`; its operational
  state remained `not-present`.
- The connected test port in slot `4/0/1` was shut/no-shut while an
  interfaces-oper `admin-status` ON_CHANGE subscription was active. The stream
  reported `if-state-up`, `if-state-down`, then `if-state-up`; both Sets
  succeeded, and a final Get verified its original enabled/UP/ready state.
- No interface description Set was sent.
- TLS and gNMI security configuration were left unchanged.

## Redactions and publication

Full response envelopes are included with device address, original hostname,
most physical interface names, and SVI name redacted. The owner-selected
`TwoGigabitEthernet4/0/1` test port is retained in the ON_CHANGE example. The
no-transceiver test port
was restored to admin-down (`enabled: false`) and emitted no follow-up event;
the separate connected test port was restored to admin/oper UP and generated
both shut/no-shut notifications. The lab VLAN ID/name, IOS XE release, response
timestamps, and model paths are retained. Review those remaining details
before reusing the captures for another publication context.

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
