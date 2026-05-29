#!/usr/bin/env bash
set -euo pipefail

# Enable plugin core for a workflow
# Usage:
#   bash .workflow-plugin-core/enable_workflow_plugin.sh <workflows-root>/<workflow-name> [gateScript]

WF_ROOT="${1:-}"
GATE_SCRIPT="${2:-}"

if [[ -z "${WF_ROOT}" ]]; then
  echo "usage: enable_workflow_plugin.sh <workflow-root> [gateScript]" >&2
  exit 2
fi

CONFIG_PATH="${WF_ROOT}/workflow/plugin-config.json"
TEMPLATE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/default-plugin-config.json"

if [[ ! -d "${WF_ROOT}/workflow" ]]; then
  echo "workflow dir not found: ${WF_ROOT}/workflow" >&2
  exit 2
fi

if [[ ! -f "${CONFIG_PATH}" ]]; then
  cp "${TEMPLATE}" "${CONFIG_PATH}"
fi

python3 - "$CONFIG_PATH" "$GATE_SCRIPT" <<'PY'
import json, sys
from pathlib import Path
cfg_path=Path(sys.argv[1])
gate=sys.argv[2]
obj=json.loads(cfg_path.read_text(encoding='utf-8'))
obj['enabled']=True
if gate:
    obj['gateScript']=gate
cfg_path.write_text(json.dumps(obj,ensure_ascii=False,indent=2),encoding='utf-8')
print('enabled plugin config at',cfg_path)
PY

echo "done"
