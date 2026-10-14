#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 HOST PORT EXPECTED_SHA256_WITHOUT_COLONS" >&2
  exit 2
fi

host=$1
port=$2
expected=${3//:/}
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

if ! openssl s_client -connect "${host}:${port}" -showcerts </dev/null 2>/dev/null \
  | openssl x509 -out "$tmp"; then
  echo "Could not retrieve an X.509 server certificate from ${host}:${port}" >&2
  exit 1
fi

actual=$(openssl x509 -in "$tmp" -noout -fingerprint -sha256 \
  | sed 's/^[^=]*=//' | tr -d ':')
if [[ "${actual,,}" != "${expected,,}" ]]; then
  echo "Certificate fingerprint mismatch for ${host}:${port}" >&2
  echo "Expected: $expected" >&2
  echo "Presented: $actual" >&2
  exit 1
fi

echo "Certificate fingerprint matches the approved value for ${host}:${port}."
