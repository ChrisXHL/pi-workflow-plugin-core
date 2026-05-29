# Workflow Plugin Core

全局预归档插件层（底层）

## 组成
- `pre_archive_gate.sh`：归档前统一入口（读取每个 workflow 的 plugin-config）
- `default-plugin-config.json`：默认配置模板
- `enable_workflow_plugin.sh`：为指定 workflow 启用插件
- `plugin_status.sh`：查看所有 workflow 的插件启用状态
- `bootstrap_all_workflows.sh`：为所有 workflow 生成默认 plugin-config.json（不自动启用）

## 工作方式
1. 每个 workflow 的 `archive_task.sh` 在归档前调用本目录 `pre_archive_gate.sh`。
2. 若 workflow 不存在 `workflow/plugin-config.json`，默认跳过（兼容旧流程）。
3. 若存在且 `enabled=true`，将执行：
   - 必需工件检查（`requiredArtifacts`，支持 glob，可用 `runBaseChecks=false` 关闭）
   - 可选新鲜度检查（`freshMinutes`，避免旧产物误通过）
   - gateScript（如 `workflow/scripts/plugin_check.sh`）
4. 任一失败会写入 `workflow/artifacts/revision-todo.md` 并阻断归档。

## 启用示例
```bash
# 假设当前目录是 workflows/
bash .workflow-plugin-core/enable_workflow_plugin.sh \
  ./mimeng-post-rewrite \
  workflow/scripts/plugin_check.sh
```

## 查看状态
```bash
# 默认扫描 .workflow-plugin-core 的上级目录
bash .workflow-plugin-core/plugin_status.sh
# 或显式指定 workflows 根目录
bash .workflow-plugin-core/plugin_status.sh ./
```
