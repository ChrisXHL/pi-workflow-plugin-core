#!/usr/bin/env bash
set -euo pipefail

# Usage: bash pre_archive_gate.sh <workflow_root>
WORKFLOW_ROOT="${1:-}"
if [[ -z "${WORKFLOW_ROOT}" ]]; then
  echo "[plugin-core] usage: pre_archive_gate.sh <workflow_root>" >&2
  exit 2
fi

CONFIG_PATH="${WORKFLOW_ROOT}/workflow/plugin-config.json"
ARTIFACTS_DIR="${WORKFLOW_ROOT}/workflow/artifacts"
REVISION_TODO="${ARTIFACTS_DIR}/revision-todo.md"

if [[ "${ALLOW_ARCHIVE_WITH_FAIL:-0}" == "1" ]]; then
  echo "[plugin-core] WARNING: bypassed by ALLOW_ARCHIVE_WITH_FAIL=1" >&2
  exit 0
fi

if [[ ! -f "${CONFIG_PATH}" ]]; then
  echo "[plugin-core] no plugin-config.json, skip" 
  exit 0
fi

python3 - "$CONFIG_PATH" "$WORKFLOW_ROOT" "$ARTIFACTS_DIR" "$REVISION_TODO" <<'PY'
import json, os, subprocess, sys
from pathlib import Path

cfg_path = Path(sys.argv[1])
wf_root = Path(sys.argv[2])
artifacts = Path(sys.argv[3])
revision = Path(sys.argv[4])

cfg = json.loads(cfg_path.read_text(encoding='utf-8'))
enabled = bool(cfg.get('enabled', False))
if not enabled:
    print('[plugin-core] plugin disabled, skip')
    sys.exit(0)

errors = []
run_base_checks = bool(cfg.get('runBaseChecks', True))
required = cfg.get('requiredArtifacts', [])
fresh_minutes = cfg.get('freshMinutes')
if run_base_checks and required:
    missing = []
    now = __import__('time').time()

    def is_fresh(path: Path) -> bool:
        if fresh_minutes is None:
            return True
        try:
            age_sec = now - path.stat().st_mtime
            return age_sec <= float(fresh_minutes) * 60
        except Exception:
            return False

    for pat in required:
        # 支持 glob 模式（如 */final.md 或 **/final.md）
        if any(ch in pat for ch in ['*', '?', '[']):
            matches = [m for m in artifacts.glob(pat) if m.is_file()]
            if not matches:
                missing.append(pat)
            elif fresh_minutes is not None and not any(is_fresh(m) for m in matches):
                missing.append(f"{pat} (存在但都不在 freshMinutes 窗口内)")
        else:
            target = artifacts / pat
            if not target.exists() or not target.is_file():
                missing.append(pat)
            elif fresh_minutes is not None and not is_fresh(target):
                missing.append(f"{pat} (不在 freshMinutes 窗口内)")
    if missing:
        errors.append('缺少必要工件（支持 glob）:\n- ' + '\n- '.join(missing))

gate_script = cfg.get('gateScript')
if gate_script:
    gate_path = (wf_root / gate_script).resolve()
    if not gate_path.exists():
        errors.append(f'gateScript 不存在: {gate_path}')
    else:
        proc = subprocess.run(['bash', str(gate_path)], cwd=str(wf_root))
        if proc.returncode != 0:
            errors.append(f'gateScript 执行失败: {gate_path} (exit {proc.returncode})')

if errors:
    artifacts.mkdir(parents=True, exist_ok=True)
    revision.write_text(
        '# revision-todo\n\n## Plugin Core Gate FAIL\n\n' +
        '\n\n'.join(f'{i+1}. {e}' for i,e in enumerate(errors)) +
        '\n\n请修复后重试归档。\n',
        encoding='utf-8'
    )
    print('[plugin-core] FAIL', file=sys.stderr)
    for e in errors:
        print(f'- {e}', file=sys.stderr)
    sys.exit(1)

print('[plugin-core] PASS')
PY
