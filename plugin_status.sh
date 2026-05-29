#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${1:-$(cd "${SCRIPT_DIR}/.." && pwd)}"

echo "workflow,has_archive,has_plugin_config,enabled,gateScript,freshMinutes"
for wf in "$ROOT"/*; do
  [[ -d "$wf/workflow" ]] || continue
  name="$(basename "$wf")"
  has_archive="no"
  [[ -f "$wf/workflow/scripts/archive_task.sh" ]] && has_archive="yes"
  cfg="$wf/workflow/plugin-config.json"
  if [[ -f "$cfg" ]]; then
    IFS=$'\t' read -r enabled gate fresh <<<"$(python3 - "$cfg" <<'PY'
import json,sys
obj=json.load(open(sys.argv[1],encoding='utf-8'))
val_enabled = str(obj.get('enabled',False)).lower()
val_gate = obj.get('gateScript','') or '-'
fresh = obj.get('freshMinutes', None)
val_fresh = '-' if fresh in (None, '') else str(fresh)
print(f"{val_enabled}\t{val_gate}\t{val_fresh}")
PY
)"
    echo "$name,$has_archive,yes,$enabled,$gate,$fresh"
  else
    echo "$name,$has_archive,no,false,,"
  fi
done
