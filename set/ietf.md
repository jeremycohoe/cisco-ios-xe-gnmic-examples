# Set: IETF interfaces

Recipes for `ietf-interfaces`. Run the
[connection setup](../README.md#connect-and-authenticate) first, then follow the
[pre-change checklist](README.md#before-you-change-anything). The lab port
`TwoGigabitEthernet4/0/1` is shown because the owner approved it; substitute
your own approved lab port.

The writable IETF config tree is `ietf-interfaces:interfaces` (not the read-only
`interfaces-state` tree used for [Get](../get/ietf.md)).

Full sanitized SetResponse and verification-Get sequences:
[captures/interface-descriptions-set.ndjson](../captures/interface-descriptions-set.ndjson).

---

## IETF interface description

**Goal:** Set, replace, and clear an interface description through the IETF
model.

**Record the current value first:**

```bash
IFACE='TwoGigabitEthernet4/0/1'
DESC_PATH="rfc7951:/ietf-interfaces:interfaces/interface[name=${IFACE}]/description"
gnmi get --path "$DESC_PATH" --encoding json_ietf
```

On the lab port the initial description was empty.

**Command — Update, Replace, then Delete:**

```bash
IFACE='TwoGigabitEthernet4/0/1'
TEST_DESCRIPTION='GNMI-LAB-TEST'
DESC_PATH="rfc7951:/ietf-interfaces:interfaces/interface[name=${IFACE}]/description"

gnmi set --update "${DESC_PATH}:::string:::${TEST_DESCRIPTION}"
gnmi set --replace "${DESC_PATH}:::string:::${TEST_DESCRIPTION}"
gnmi set --delete "${DESC_PATH}"
```

**Change these fields:**
- `IFACE` — your approved lab port.
- `TEST_DESCRIPTION` — the description text.

**Verify:** run the Get after each operation. Update and Replace show
`GNMI-LAB-TEST`; Delete returns the description to empty.

**Rollback:** the `Delete` restores the original empty value. If the port had a
description before you started, re-apply it with `--update` instead of `--delete`.

**Status:** Verified live and restored on C9300 / IOS XE 26.02.1 (port 4/0/1).
