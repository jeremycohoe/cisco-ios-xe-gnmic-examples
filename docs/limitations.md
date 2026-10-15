# Known limitations and gotchas

The example pages contain only workflows that worked on the lab Catalyst 9300
(IOS XE 26.02.1). This page records what did **not** work, was inconclusive, or
needs care, so the examples stay trustworthy. Behavior is device- and
release-specific; confirm against your own device.

## Set operations

- **A Set timeout does not mean the change failed.** A VLAN rename on this
  device returned `DeadlineExceeded`, yet a later Get showed the new value had
  applied. After any Set timeout, **Get the path before retrying**. Do not retry
  blindly.
- **IOS XE config-database lock.** Retrying a timed-out Set while the device
  still held the configuration lock returned
  `code = Unavailable desc = Database is locked for writing`. Wait for the lock
  to clear, confirm state with Get, then retry.
- **Native VLAN-name writes are slow.** On this device, `Cisco-IOS-XE-native`
  VLAN-name Update/Replace consistently returned a client `DeadlineExceeded`
  (even at a 120s timeout) yet applied a short time later. By contrast,
  `Cisco-IOS-XE-native` interface-description Update/Replace/Delete returned
  clean SetResponses with no timeout. Always Get the path to confirm the actual
  result after a native write.
- **`UnionReplace` is unavailable.** The device advertises gNMI `0.7.0`;
  `union_replace` was added to the gNMI specification in `0.10.0`. A local
  gNMIc flag of a similar name does not imply server support.
- **Delete of the lab VLAN was not exercised.** Deleting
  `vlan-list[id=899]` would remove the lab VLAN, so Delete was intentionally not
  sent for that path.

## Subscribe operations

- **Memory periodic subscription is release-specific.** On the primary C9300 /
  IOS XE 26.02.1 a `SAMPLE` of `Cisco-IOS-XE-memory-oper` returned only
  timestamp-only notifications with no data. On a second lab unit
  (**C9300-24UX / IOS XE 26.1**) the same subscription returned full values — see
  [subscribe/cisco.md](../subscribe/cisco.md#cisco-memory-statistics-sample).
  Streaming support for operational trees varies by release; confirm on your
  device.
- **Target-defined stream returned no data.** A `target-defined` subscription to
  `Cisco-IOS-XE-interfaces-oper` `admin-status` produced nothing at all — not
  even an initial update — confirmed on two units (C9300 / IOS XE 26.02.1 and
  C9300-24UX / IOS XE 26.1), while `sample` and `on_change` on the same leaf
  returned data immediately. Treat target-defined as unusable for this path and
  use `sample` or `on_change` instead.
- **On-change support is path-specific.** On-change works only where the
  device's `Cisco-IOS-XE-mdt-capabilities-oper` list enables it. OpenConfig
  general interface state/counters, IETF `ietf-interfaces`, and
  `Cisco-IOS-XE-native` have no on-change override and fall back to periodic.
  Always check live MDT capabilities before relying on on-change for a path.
- **A port with no transceiver emitted no change events.** An on-change
  subscription on an unconnected test port returned only its initial update. Use
  a connected port to observe real state transitions.

## Configuration and security scope

- The gNMI service port and TLS/authentication settings were **not** changed. A
  read-only Get confirmed `secure-port 9339`; no Set was issued against the
  service.
- MDT configuration, NTP configuration, and other advertised `-cfg` models were
  not written. They need an exact approved path and value before any live Set.

## Device state during collection

The switch was reloaded during collection. Post-reload Gets confirmed gNMI was
reachable, the original hostname was restored, and VLAN 899 persisted as active
`GNMI-LAB`. A later rename and authorized restore both timed out; an immediate
Get showed the temporary value, while a later Get confirmed the original value
had been restored without a retry. This reinforces the Set-timeout guidance
above.
