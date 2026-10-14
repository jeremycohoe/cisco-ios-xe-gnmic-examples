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
example pages include full sanitized response envelopes for verified Gets,
hostname Set operations, the VLAN Set, and periodic Subscribe. Raw unredacted
captures are not stored in the repository.
