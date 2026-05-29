#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${1:-$(cd "${SCRIPT_DIR}/.." && pwd)}"

for wf in "$ROOT"/*; do
  [[ -d "$wf/workflow" ]] || continue
  cfg="$wf/workflow/plugin-config.json"
  if [[ ! -f "$cfg" ]]; then
    cp "$ROOT/.workflow-plugin-core/default-plugin-config.json" "$cfg"
    echo "[bootstrap] created $cfg"
  else
    echo "[bootstrap] exists  $cfg"
  fi
done

echo "[bootstrap] done"
