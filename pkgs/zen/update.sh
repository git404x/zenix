#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

echo "[*] Polling upstream Zen releases..."
RELEASE=$(curl -s https://api.github.com/repos/zen-browser/desktop/releases?per_page=10 | jq -r '[.[] | select(.prerelease == false or (.tag_name | test("^[0-9.]+b$")))] | .[0]')

VERSION=$(echo "$RELEASE" | jq -r '.tag_name')
ASSET=$(echo "$RELEASE" | jq -r '[.assets[] | select(.name == "zen.linux-x86_64.tar.xz")] | .[0]')
URL=$(echo "$ASSET" | jq -r '.browser_download_url')

echo "[*] Found Zen version: $VERSION"
echo "[*] Calculating SRI hash..."
HASH=$(nix-hash --to-sri --type sha256 "$(nix-prefetch-url --unpack "$URL")")

cat > versions.json <<EOF
{
  "version": "$VERSION",
  "url": "$URL",
  "hash": "$HASH"
}
EOF

echo "[+] Zen update complete: $VERSION"
