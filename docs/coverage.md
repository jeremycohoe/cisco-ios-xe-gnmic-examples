# Example coverage

The gNMI operations and YANG model combinations are not a closed finite list:
IOS XE model revisions expose different paths, and each model can include many
operations and encodings. This matrix records the deliberate starter scope and
what has actually been observed so examples do not overstate coverage.

| Operation | Model/path | Status | Response evidence |
|---|---|---|---|
| Get | Cisco native hostname | Verified | Device returned the hostname; sensitive value omitted |
| Get | Cisco native interface description | Verified | Leaf read succeeded; identifier/value withheld |
| Get | Cisco native VLAN list entry | Verified | Full response shows lab VLAN ID/name |
| Get | Cisco VLAN-oper status | Verified | VLAN 899 active; full response captured |
| Get | Cisco VLAN-oper ports | Verified | Empty list; no ports assigned |
| Get | Cisco gNMI cfg `config/secure-port` | Verified | Returned secure listener port 9339 |
| Get | Cisco process CPU `cpu-utilization/five-seconds` | Verified | Returned 4 in the five-second CPU utilization leaf |
| Get | Cisco YANG interfaces cfg | Advertised; not yet queried | Candidate to compare with Cisco native interface config |
| Get | Cisco MDT cfg | Advertised; not yet queried | Inspect only a specific subscription; receiver details may be sensitive |
| Get | Cisco memory, process-memory, environment, NTP models | Advertised; not yet queried | Candidate operational health samples |
| Get | Cisco interface-oper `oper-status` | Verified | Returned `lower-layer-down` for the selected SVI |
| Get | OpenConfig interfaces `oper-status` | Verified | Returned `LOWER_LAYER_DOWN` for the selected SVI |
| Get | IETF `interfaces-state/oper-status` | Verified | Returned `lower-layer-down` for the selected SVI |
| Set Update | Cisco native hostname | Verified live, then rolled back | Full SetResponse and verification Get captured |
| Set Replace | Cisco native hostname | Verified live, then rolled back | Full SetResponse and verification Get captured |
| Set Update/Replace | Cisco native interface description | Local dry-run template | Update request rendering captured; no live Set |
| Set Update | Cisco native VLAN name | Verified live | VLAN 899 created as `GNMI-LAB`, unassigned; full SetResponse and Get captured |
| Subscribe periodic | OpenConfig interface state, 5 s sample | Verified | Initial response and repeated samples observed |
| Subscribe on-change | OpenConfig interface state | Inconclusive | No SubscribeResponse (including initial sync) was captured in 10 seconds |
| Subscribe once/poll/target-defined | Various | Not verified | Future examples |

The examples are starter recipes, not every possible operation/model/encoding
permutation. Each included command has a paired sanitized response or an
explicit note that no response was observed. Hostname writes were temporary and
rolled back; VLAN 899 was created and remains configured.
