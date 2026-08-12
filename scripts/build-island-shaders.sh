#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

SOURCE="${REPO_ROOT}/island/shaders/dynamic_island.frag"
OUTPUT="${REPO_ROOT}/island/shaders/dynamic_island.frag.qsb"

if [[ -n "${QSB:-}" ]]; then
    QSB_BIN="${QSB}"
elif command -v qsb-qt6 >/dev/null 2>&1; then
    QSB_BIN="qsb-qt6"
elif command -v qsb >/dev/null 2>&1; then
    QSB_BIN="qsb"
else
    cat >&2 <<'MSG'
Could not find Qt's qsb shader baker.

On Fedora, install Qt Shader Tools first, then rerun this script:
  sudo dnf install qt6-qtshadertools
MSG
    exit 1
fi

"${QSB_BIN}" --qt6 -o "${OUTPUT}" "${SOURCE}"
printf 'Built %s\n' "${OUTPUT}"
