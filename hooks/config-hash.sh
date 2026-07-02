#!/usr/bin/env sh
# Canonical hash of $1: lowercase hex, no whitespace. Empty output if the file
# is missing or no hash tool is available (caller treats empty as "cannot hash"
# and fails open). Both the frame-gate hook and the config-contract skill call
# THIS script so their hashes are identical by construction (no format drift).
f="$1"
[ -f "$f" ] || exit 0
if command -v sha256sum >/dev/null 2>&1; then
  sha256sum "$f" 2>/dev/null | cut -d' ' -f1
elif command -v shasum >/dev/null 2>&1; then
  shasum -a 256 "$f" 2>/dev/null | cut -d' ' -f1
elif command -v certutil >/dev/null 2>&1; then
  certutil -hashfile "$f" SHA256 2>/dev/null | sed -n 2p
fi | tr 'A-Z' 'a-z' | tr -d ' \r\n'
