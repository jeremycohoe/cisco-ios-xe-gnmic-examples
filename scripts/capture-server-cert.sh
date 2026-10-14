#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 HOST PORT OUTPUT.pem" >&2
  exit 2
fi

host=$1
port=$2
output=$3
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

umask 077
if ! openssl s_client -connect "${host}:${port}" -showcerts </dev/null 2>/dev/null \
  | openssl x509 -out "$tmp"; then
  echo "Could not retrieve an X.509 server certificate from ${host}:${port}" >&2
  exit 1
fi

install -m 600 "$tmp" "$output"
echo "Saved presented leaf certificate to $output"
openssl x509 -in "$output" -noout -fingerprint -sha256 -subject -issuer -dates
echo "Verify this fingerprint through an independent trusted channel before trusting it." >&2
