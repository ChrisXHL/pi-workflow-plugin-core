# Workflow Plugin Core

A lightweight **quality gate layer** for long skill chains.

It runs right before archive/finalization and prevents weak outputs from being treated as "done".

---

## Why I built this

This came directly from my own practice.

I was running long chains (for example: fetch data with Feishu skill → analyze with a data-analysis skill → send summary back to Feishu group). It worked, but it was fragile:

- context was easy to lose across steps,
- I often forgot something in the middle,
- and most importantly, nodes had no clear acceptance threshold.

So even when each skill "ran successfully", the final result quality was unstable.

I realized the fix was not just chaining skills — it was adding **node-level quality thresholds + feedback loops**.

That became this plugin core:

- each workflow can define required artifacts and optional custom checks,
- each run is validated before archive,
- if it fails, the chain does **not** continue silently.

This simple gate turned unstable chains into reliable pipelines.

---

## What it does

`pre_archive_gate.sh` reads `workflow/plugin-config.json` and enforces checks:

1. **Required artifacts check** (`requiredArtifacts`, supports glob)
2. **Optional freshness check** (`freshMinutes`)
3. **Optional custom gate script** (`gateScript`)

If any check fails:

- archive is blocked,
- `workflow/artifacts/revision-todo.md` is generated,
- your workflow gets explicit feedback instead of false success.

---

## Repository contents

- `pre_archive_gate.sh` — global pre-archive gate entry
- `default-plugin-config.json` — default config template
- `enable_workflow_plugin.sh` — enable plugin for one workflow
- `plugin_status.sh` — inspect plugin status across workflows
- `bootstrap_all_workflows.sh` — create missing plugin-config for all workflows

---

## Installation

### Option A — Recommended (inside a workflows root)

If you already have a directory like:

```text
workflows/
  .workflow-plugin-core/
  workflow-a/
  workflow-b/
```

Place this repo as `.workflow-plugin-core` under your workflows root.

Then bootstrap configs:

```bash
cd /path/to/workflows/.workflow-plugin-core
bash bootstrap_all_workflows.sh
```

---

### Option B — Any repository layout

You can also clone anywhere and pass explicit paths.

```bash
git clone https://github.com/ChrisXHL/pi-workflow-plugin-core.git
cd pi-workflow-plugin-core

# Check status for your custom workflows root
bash plugin_status.sh /path/to/workflows
```

---

### Option C — For Pi users

If you use Pi workflow runtime, keep this structure:

```text
<your-workflows-root>/
  .workflow-plugin-core/
  <workflow-name>/
    workflow/
      scripts/archive_task.sh
      plugin-config.json
      artifacts/
```

Then in each workflow's `archive_task.sh`, call the plugin gate before archive:

```bash
PLUGIN_CORE="${WORKFLOW_ROOT}/../.workflow-plugin-core/pre_archive_gate.sh"
if [[ -x "${PLUGIN_CORE}" ]]; then
  bash "${PLUGIN_CORE}" "${WORKFLOW_ROOT}"
fi
```

This is the key integration point for Pi workflow pipelines.

---

## Quick start

### 1) Bootstrap configs for all workflows

```bash
# from workflows/.workflow-plugin-core
bash bootstrap_all_workflows.sh
```

### 2) Enable one workflow

```bash
bash enable_workflow_plugin.sh \
  ../my-workflow \
  workflow/scripts/plugin_check.sh
```

### 3) Check status

```bash
bash plugin_status.sh
# or
bash plugin_status.sh ../
```

---

## `plugin-config.json` reference

Example:

```json
{
  "enabled": true,
  "runBaseChecks": true,
  "gateScript": "workflow/scripts/plugin_check.sh",
  "requiredArtifacts": [
    "input-summary.md",
    "reference-selection.md",
    "final-post.md",
    "reports/*.json"
  ],
  "freshMinutes": 180
}
```

Fields:

- `enabled` (bool): turn plugin on/off for this workflow
- `runBaseChecks` (bool): enable required artifact checks
- `gateScript` (string): optional script for custom pass/fail logic
- `requiredArtifacts` (string[]): required files/globs under `workflow/artifacts`
- `freshMinutes` (number|null): require artifacts to be recently updated

---

## Failure and feedback model

When checks fail, the plugin writes:

- `workflow/artifacts/revision-todo.md`

This gives the next iteration a concrete fix list, which creates a practical quality feedback loop.

---

## Emergency bypass

For debugging only:

```bash
ALLOW_ARCHIVE_WITH_FAIL=1 bash pre_archive_gate.sh /path/to/workflow-root
```

Use with caution — this bypasses all gate failures.

---

## Design philosophy

- **Chains are not enough. Gates are mandatory.**
- **A node is only complete when it meets a threshold.**
- **No threshold, no reliability.**
- **No feedback, no quality improvement.**

This project exists to make multi-skill automation stable in real-world usage.

---

## License

MIT
