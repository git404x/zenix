#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

echo "[*] Polling upstream Zen Beta releases..."
BETA_RELEASE=$(curl -s https://api.github.com/repos/zen-browser/desktop/releases?per_page=10 | jq -r '[.[] | select(.prerelease == false or (.tag_name | test("^[0-9.]+b$")))] | .[0]')
BETA_VERSION=$(echo "$BETA_RELEASE" | jq -r '.tag_name')
BETA_ASSET=$(echo "$BETA_RELEASE" | jq -r '[.assets[] | select(.name == "zen.linux-x86_64.tar.xz")] | .[0]')
BETA_URL=$(echo "$BETA_ASSET" | jq -r '.browser_download_url')

echo "[*] Calculating Beta SRI hash ($BETA_VERSION)..."
BETA_HASH=$(nix-hash --to-sri --type sha256 "$(nix-prefetch-url --unpack "$BETA_URL")")

echo "[*] Polling upstream Zen Twilight releases..."
TWILIGHT_RELEASE=$(curl -s https://api.github.com/repos/zen-browser/desktop/releases/tags/twilight-1)
TWILIGHT_NAME=$(echo "$TWILIGHT_RELEASE" | jq -r '.name')
TWILIGHT_VERSION=$(echo "$TWILIGHT_NAME" | grep -oP '\b[0-9.]+t\b' || echo "twilight")
TWILIGHT_ASSET=$(echo "$TWILIGHT_RELEASE" | jq -r '[.assets[] | select(.name == "zen.linux-x86_64.tar.xz")] | .[0]')
TWILIGHT_URL=$(echo "$TWILIGHT_ASSET" | jq -r '.browser_download_url')

echo "[*] Calculating Twilight SRI hash ($TWILIGHT_VERSION)..."
TWILIGHT_HASH=$(nix-hash --to-sri --type sha256 "$(nix-prefetch-url --unpack "$TWILIGHT_URL")")

cat > versions.json <<EOF
{
  "beta": {
    "version": "$BETA_VERSION",
    "url": "$BETA_URL",
    "hash": "$BETA_HASH"
  },
  "twilight": {
    "version": "$TWILIGHT_VERSION",
    "url": "$TWILIGHT_URL",
    "hash": "$TWILIGHT_HASH"
  }
}
EOF

echo "[+] Zen versions updated successfully (Beta: $BETA_VERSION, Twilight: $TWILIGHT_VERSION)"
