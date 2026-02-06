# Project Master Agent: mycost (Advanced Analytics Ledger)

## 1. 项目背景
- 目标：开发一个偏“进阶分析”的 iOS 记账应用。
- 技术栈：SwiftUI, SwiftData, Swift Charts, CloudKit, iOS 17+。
- 视觉参考：iCost（卡片布局、深色模式、系统语义色）。

## 2. 行为准则
- 架构遵循：MVVM + Domain-Driven Design (DDD)。
- UI 准则：优先系统原生组件，使用 SF Symbols，深色模式完美适配。
- 数据准则：SwiftData 模型与查询保持轻量与高性能。
- 同步准则：仅 iCloud/CloudKit，同步状态可观测，冲突最小化。

## 3. 文档引用
- 需求详见：`docs/PRD.md`
- 技术规范：`docs/Tech_Spec.md`

## 4. 任务拆分与边界
- UI 相关：由 `.agents/ui_agent.md` 负责
- 数据与统计：由 `.agents/data_agent.md` 负责
- 同步与备份：由 `.agents/backup_agent.md` 负责（iCloud-only）

## 5. 项目结构约定
- `Models/`：SwiftData Entities
- `ViewModels/`：业务逻辑与聚合统计
- `Views/`：SwiftUI 页面与组件
- `Services/`：同步与数据服务
- `Resources/`：Assets、Localization

## 6. 变更规则
- 任何需求或范围变更，需同步更新 `docs/PRD.md`。
- 任何技术方案变更，需同步更新 `docs/Tech_Spec.md`。
- 子 Agent 指令必须保持与 PRD/Tech Spec 一致。
