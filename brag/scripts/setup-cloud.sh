#!/usr/bin/env bash
# Prepare a sandboxed/cloud container so /brag can render.
# Usage: bash setup-cloud.sh [composition-dir]
set -euo pipefail

node -e 'process.exit(+process.versions.node.split(".")[0] >= 22 ? 0 : 1)' || { echo "Node 22+ required"; exit 1; }
command -v ffmpeg >/dev/null || { echo "ffmpeg missing (apt-get install -y ffmpeg)"; exit 1; }

# Headless Chrome used by Hyperframes for rendering
npx -y hyperframes browser ensure

# Hyperframes domain skills that /brag reads (hyperframes-core, -animation, ...)
npx -y hyperframes skills

# Sandboxes often block cdn.jsdelivr.net, which compositions load GSAP from.
# If a composition dir is given, vendor GSAP locally and rewrite the script tags.
if [ "${1:-}" ]; then
  cd "$1"
  npm i gsap@3.14.2 --no-audit --no-fund >/dev/null
  mkdir -p vendor && cp node_modules/gsap/dist/gsap.min.js vendor/
  grep -rl 'cdn.jsdelivr.net/npm/gsap@[^"]*/gsap.min.js' --include='*.html' . \
    | xargs -r sed -i -E 's#https://cdn.jsdelivr.net/npm/gsap@[^"]*/gsap.min.js#vendor/gsap.min.js#g'
  echo "GSAP vendored in $1/vendor"
fi
echo "brag environment ready"
