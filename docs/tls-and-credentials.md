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

## Enable gNMI on IOS XE

gNMI on IOS XE runs over the secure gNXI/gNMI server. The example below enables
it with username/password authentication and the device's own self-signed
trustpoint — the same mode used for most examples in this guide. The commands
are entered in global configuration mode.

```text
conf t
 service internal                              ! required for secure-allow-self-signed-trustpoint
 gnxi
 gnxi secure-allow-self-signed-trustpoint
 gnxi secure-password-auth
 ! "gnxi secure-init" generates the self-signed trustpoint referenced below;
 ! the trustpoint name is device-specific (TP-self-signed-<serial-derived-id>)
 gnxi secure-trustpoint TP-self-signed-3775488971
 gnxi secure-server
end
```

Confirm the running state (note the actual command is `show gnmi-yang state` on
some releases and `show gnxi state` on others):

```text
show gnmi-yang state detail
```

Check that `Secure server: Enabled`, the secure port (default `9339`),
`Secure password authentication: Enabled`, and the `Secure trustpoint`. Then
connect with gNMIc using `--skip-verify` (self-signed) and username/password:

```bash
gnmic capabilities
```

### Replacing the insecure gNMI server

The **insecure** gNMI server (`gnxi server`, listening on the cleartext gRPC
port such as `50052`) is **no longer supported**. If it is enabled, disable it
and use the secure server instead:

```text
conf t
 no gnxi server            ! remove the insecure listener
 gnxi secure-server        ! use the secure server (see enablement above)
end
```

Enabling `gnxi secure-server` replaces the insecure listener; the device then
answers gNMI only on the secure port (TLS, default `9339`). Use `gnxi secure-init`
to generate the self-signed trustpoint, or load your own trustpoint as shown
below.

### Bring your own trustpoint (mutual TLS)

To validate the server properly — or to require client certificates
(`gnxi secure-client-auth`) — load a trustpoint you control instead of the
self-signed one. The certificates and keys are created off the device; a minimal
OpenSSL example:

```bash
# Setting up a CA
openssl genrsa -out rootCA.key 2048
openssl req -subj "/C=US/.../CN=rootCA" -x509 -new -nodes -key rootCA.key \
  -sha256 -out rootCA.pem

# Device certificate and key (CN/SAN must match the gNMI target name)
openssl genrsa -out device.key 2048
openssl req -subj "/C=US/.../CN=<hostnameFQDN>" -new -key device.key -out device.csr
openssl x509 -req -in device.csr -CA rootCA.pem -CAkey rootCA.key \
  -CAcreateserial -out device.crt -sha256

# Client certificate and key (only needed for secure-client-auth / mutual TLS)
openssl genrsa -out client.key 2048
openssl req -subj "/C=US/.../CN=gnmi_client" -new -key client.key -out client.csr
openssl x509 -req -in client.csr -CA rootCA.pem -CAkey rootCA.key \
  -CAcreateserial -out client.crt -sha256
```

Import the CA into a trustpoint on the device, then bind it to the secure
server:

```text
conf t
 crypto pki import trustpoint1 pem terminal password <password>
 ! paste the CA (rootCA.pem) PEM, end with a blank line or "quit"
 gnxi-yang secure-trustpoint trustpoint1
 gnxi-yang secure-server
end
```

Connect with gNMIc, validating the server against your CA and (for mutual TLS)
presenting the client certificate and key:

```bash
gnmic --address "$GNMIC_ADDRESS" --username "$GNMIC_USERNAME" --password "$GNMIC_PASSWORD" \
  --tls-ca rootCA.pem --tls-cert client.crt --tls-key client.key \
  get --path '/Cisco-IOS-XE-native:native/hostname'
```

See the [Cisco IOS XE Programmability gNMI guide](https://www.cisco.com/c/en/us/td/docs/ios-xml/ios/prog/configuration/26x/26x-programmability-cg/gnmi.html)
for the authoritative configuration reference. Keep all private keys out of the
repository (`*.key`, `*.pem`, `*.crt`, `*.p12` are already in `.gitignore`).

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

Two authentication modes were observed across lab devices:

- **Secure password authentication** (`gnxi secure-password-auth`): the client
  presents username/password over TLS and no client certificate is required.
  This is the mode used for most examples here.
- **Secure client authentication** (`gnxi secure-client-auth`, mutual TLS): the
  server requires a client certificate. If this is enabled **without** a valid
  secure client trustpoint, the TLS handshake completes but the gRPC stream is
  reset immediately (`error reading server preface: EOF`). Either configure a
  client trustpoint and connect with `--tls-cert`/`--tls-key` (see
  [Bring your own trustpoint](#bring-your-own-trustpoint-mutual-tls)), or switch
  the device to `secure-password-auth`.

Keep any client certificate and private key private; never commit those files.
See [limitations and gotchas](limitations.md) and the connection notes in the
primary README if a secure connection fails.

## References

- [Cisco IOS XE 26.x gNMI Protocol](https://www.cisco.com/c/en/us/td/docs/ios-xml/ios/prog/configuration/26x/26x-programmability-cg/gnmi.html)
- [gNMIc TLS options](https://gnmic.openconfig.net/commands/global_flags/)
