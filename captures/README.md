# Captured output policy

This directory is reserved for command and response pairs captured from the
lab C9300. Before publication, remove or redact device addresses, hostnames,
usernames, passwords, interface identifiers, VLAN IDs, IP addresses, MAC
addresses, serial numbers, descriptions, timestamps where needed, and any
customer-identifying values.

Each capture should include:

- the copyable command, using environment variables and placeholders;
- the sanitized stdout/stderr response;
- whether it was verified against the device, a local dry run, or a template;
- the IOS XE release, YANG model/path, encoding, and subscription mode when
  relevant;
- a note describing any redactions.

Do not store private keys or credentials here. A public server certificate can
still reveal device identity; get explicit approval before tracking one. The
example pages ([get/](../get/README.md), [set/](../set/README.md),
[subscribe/](../subscribe/README.md)) include full sanitized response envelopes
for verified Gets, hostname and interface Set operations, the VLAN Set and
same-value Replace, and Subscribe responses for SAMPLE, ONCE, POLL, and
ON_CHANGE. The captures in this directory include the sanitized inventory of all
486 advertised models, the complete MDT capability Get, a bounded MDT config
stream-leaf Get, initial objects from VLAN and interface on-change
subscriptions, a full VLAN-name on-change change-event stream, the complete
connected-interface shut/no-shut ON_CHANGE stream with SetResponse objects,
OpenConfig/IETF and Cisco-native interface description SetResponse/Get
sequences, final VLAN-name Get, interface counter Get, IETF periodic and ONCE
samples, the keyed CPU-flag POLL response, and post-reload memory,
environment-sensor, and NTP Gets.
Device and peer IP addresses are replaced with placeholders in operational
captures; interface names are redacted in subscribe outputs except for the
owner-selected `TwoGigabitEthernet4/0/1` shut/no-shut example. The MDT config
response redacts its subscription ID and device address. Raw unredacted
captures are not stored in the repository.
