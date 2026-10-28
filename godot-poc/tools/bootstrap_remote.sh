#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
missing=()
for package in python3 libfontconfig1 fonts-dejavu-core; do
  if ! dpkg -s "$package" >/dev/null 2>&1; then
    missing+=("$package")
  fi
done
if (( ${#missing[@]} )); then
  sudo apt-get update -qq
  sudo apt-get install -y --no-install-recommends "${missing[@]}"
fi
bash godot-poc/tools/install_godot.sh
bash godot-poc/tools/build_web.sh
