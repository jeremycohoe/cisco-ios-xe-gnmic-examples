# Set: OpenConfig interfaces

Recipes for `openconfig-interfaces`. Run the
[connection setup](../README.md#connect-and-authenticate) first, then follow the
[pre-change checklist](README.md#before-you-change-anything). The lab port
`TwoGigabitEthernet4/0/1` is shown because the owner approved it for these
examples; substitute your own approved lab port.

Full sanitized SetResponse and verification-Get sequences:
[captures/interface-descriptions-set.ndjson](../captures/interface-descriptions-set.ndjson).

---

## OpenConfig interface enable

**Goal:** Administratively disable (shut) and re-enable (no-shut) an interface.

> A shut briefly interrupts the link. Only run this on a port that is safe to
> interrupt. **Get `config/enabled` first and confirm it is `true`.**

**Record the current value first:**

```bash
IFACE='TwoGigabitEthernet4/0/1'
ENABLE_PATH="openconfig:/interfaces/interface[name=${IFACE}]/config/enabled"
gnmic get --path "$ENABLE_PATH" --encoding json_ietf
```

**Command — shut, then no-shut:**

```bash
IFACE='TwoGigabitEthernet4/0/1'
ENABLE_PATH="openconfig:/interfaces/interface[name=${IFACE}]/config/enabled"

gnmic set --encoding json_ietf --update "${ENABLE_PATH}:::bool:::false"   # shut
gnmic set --encoding json_ietf --update "${ENABLE_PATH}:::bool:::true"    # no shut
```

**Change these fields:**
- `IFACE` — your approved lab port.

**Verify:**

```bash
gnmic get --path "$ENABLE_PATH" --encoding json_ietf
```

The final Get returned `config/enabled: true`, with OpenConfig admin/oper `UP`
and Cisco `oper-status: if-oper-state-ready`.

**Rollback:** restore the value recorded before the change (this example
restored `true`). The shut/no-shut sequence above already ends in the enabled
state.

**Status:** Verified live and restored on C9300 / IOS XE 26.02.1.

---

## OpenConfig interface description

**Goal:** Set, replace, and clear an interface description.

**Record the current value first:**

```bash
IFACE='TwoGigabitEthernet4/0/1'
DESC_PATH="openconfig:/interfaces/interface[name=${IFACE}]/config/description"
gnmic get --path "$DESC_PATH" --encoding json_ietf
```

On the lab port the initial description was empty.

**Command — Update, Replace, then Delete:**

```bash
IFACE='TwoGigabitEthernet4/0/1'
TEST_DESCRIPTION='GNMI-LAB-TEST'
DESC_PATH="openconfig:/interfaces/interface[name=${IFACE}]/config/description"

gnmic set --update "${DESC_PATH}:::string:::${TEST_DESCRIPTION}"
gnmic set --replace "${DESC_PATH}:::string:::${TEST_DESCRIPTION}"
gnmic set --delete "${DESC_PATH}"
```

**Change these fields:**
- `IFACE` — your approved lab port.
- `TEST_DESCRIPTION` — the description text.

**Verify:** run the Get after each operation. Update and Replace show
`GNMI-LAB-TEST`; Delete returns the description to empty.

**Rollback:** the `Delete` restores the original empty value. If the port had a
description before you started, re-apply it with `--update` instead of `--delete`.

**Status:** Verified live and restored on C9300 / IOS XE 26.02.1 (port 4/0/1).
