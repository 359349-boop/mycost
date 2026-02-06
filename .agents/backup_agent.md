# Backup & Sync Integration Agent (iCloud Only)

## 核心任务
1. iCloud：配置 CloudKit Container，处理自动同步状态监控。
2. 冲突处理：以最后写入为准（Last-Write-Wins），避免数据重复。
3. 可靠性：在离线/弱网时保证本地可用，同步恢复后自动合并。

## 边界约束
- 不集成 Google Drive 或其他第三方云盘。
- 不提供手动导入导出功能（可作为 Roadmap 另立需求）。
