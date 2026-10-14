# TLS certificates and credentials

The C9300 uses TLS on port `9339`, username/password authentication, and the
Cisco `gnxi secure-init` setup. Cisco describes this default/encrypted bootstrap
state as using a self-signed certificate that the client does not verify. The
certificate captured during this work is self-signed, has `CA:TRUE`, and has no
Subject Alternative Name (SAN). Its subject and fingerprint are omitted from
this public guide. We keep the device's current TLS configuration unchanged and
use gNMIc's `--skip-verify` for this bootstrap-mode example, consistent with
Cisco's described behavior.

The fingerprint helpers below are optional: they help an operator observe and
compare the certificate across connections, but they do not make gNMIc verify
the server or provide an SSH-style trust prompt. Never publish a private key;
the lab certificate itself is not included here.

## Credentials

Do not publish the real password, even with part of it redacted. A shortened
password is still a credential and can be guessed or reused. Use a placeholder
such as `CHANGE_ME` in documentation, and prompt for secrets at runtime:

```bash
export GNMIC_ADDRESS="192.0.2.10:9339"
export GNMIC_USERNAME="admin"
read -rsp "gNMI password: " GNMIC_PASSWORD
printf '\n'
export GNMIC_PASSWORD
```

Unset it when finished with `unset GNMIC_PASSWORD`. If the disclosed password
is valid outside this disposable lab, rotate it. A public repository should
never contain a functioning credential.

## Inspect and capture the presented server certificate

The helper downloads only the public certificate and prints its SHA-256
fingerprint. It does not trust or install the certificate automatically:

```bash
scripts/capture-server-cert.sh 192.0.2.10 9339 /tmp/c9300-server.pem
```

On the first connection, verify that fingerprint through an independent trusted
channel (for example, compare it with a fingerprint derived from the configured
trustpoint on the device). Capturing a fingerprint over the same network path
you are trying to secure is not sufficient against a man-in-the-middle attack.
The companion check can compare a later connection against the fingerprint you
approved:

```bash
scripts/check-server-cert.sh 192.0.2.10 9339 'SHA256_FINGERPRINT_WITHOUT_COLONS'
```

It exits non-zero if the presented certificate changes. Treat an unexpected
change as a trust failure; verify it out of band before updating the pin.
Certificate pinning helps detect changes, but gNMIc itself does not offer an
SSH-style first-use prompt or a certificate fingerprint pin flag.

## Optional: provisioned certificates

If a deployment later moves from `secure-init` bootstrap mode to a provisioned
certificate, use a trusted certificate with a SAN matching the target name and
configure gNMIc with its CA:

```bash
export GNMIC_TLS_CA="/path/to/lab-ca.pem"
unset GNMIC_SKIP_VERIFY
gnmic capabilities --address "$GNMIC_ADDRESS" \
  --username "$GNMIC_USERNAME" --password "$GNMIC_PASSWORD" \
  --tls-ca "$GNMIC_TLS_CA"
```

If connecting by IP but the certificate SAN contains a DNS name, use that DNS
name in the connection target or pass the matching `--tls-server-name` value.
The name must appear in the certificate SAN. Adding the certificate to
`GNMIC_TLS_CA` does not waive hostname validation. See the [Cisco gNMI
guide](https://www.cisco.com/c/en/us/td/docs/ios-xml/ios/prog/configuration/26x/26x-programmability-cg/gnmi.html)
and [Cisco gNOI certificate bootstrapping guide](https://www.cisco.com/c/en/us/td/docs/ios-xml/ios/prog/configuration/1718/b-1718-programmability-cg/gnoi.html)
for certificate provisioning. No provisioning changes are made in this example.

## Lab-only bypass

For a temporary isolated lab diagnostic, gNMIc can skip certificate
verification:

```bash
gnmic capabilities --address "$GNMIC_ADDRESS" \
  --username "$GNMIC_USERNAME" --password "$GNMIC_PASSWORD" \
  --skip-verify
```

This still encrypts traffic, but it does not authenticate the server; an active
attacker could impersonate the device. Do not use it on untrusted networks or
for production credentials. Prefer fixing the server certificate.

## Client certificates

The observed device configuration enables secure password authentication. It
does not show `gnxi secure-client-auth`, so a client certificate is not required
for the current setup. If mutual TLS is configured later, keep the client
certificate and private key private and supply them with gNMIc's `--tls-cert`
and `--tls-key` options. Never commit those files.

## References

- [Cisco IOS XE 26.x gNMI Protocol](https://www.cisco.com/c/en/us/td/docs/ios-xml/ios/prog/configuration/26x/26x-programmability-cg/gnmi.html)
- [gNMIc TLS options](https://gnmic.openconfig.net/commands/global_flags/)
