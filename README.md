# mycost

一个偏“进阶分析”的 iOS 记账应用骨架，基于 SwiftUI + SwiftData + CloudKit（iOS 17+）。

## 目录结构
- `AGENTS.md`
- `.agents/`
- `docs/`
- `Models/`
- `ViewModels/`
- `Views/`
- `Services/`
- `Resources/`
- `MyCostApp.swift`
- `project.yml`
- `MyCost.entitlements`
- `Info.plist`

## 环境要求
- Xcode 15+
- iOS 17+
- XcodeGen（可选，用于生成项目）

## 使用方式（XcodeGen）
1. 安装 XcodeGen：`brew install xcodegen`
2. 生成工程：`./scripts/generate.sh`
3. 打开 `MyCost.xcodeproj`
4. 在 Xcode Capabilities 中开启 CloudKit
5. 替换 CloudKit Container 与 Bundle ID（见下文）

## 使用方式（手动）
1. 在 Xcode 中创建一个新的 iOS App 项目（SwiftUI，iOS 17+）。
2. 将本仓库的 `Models/`、`ViewModels/`、`Views/`、`Services/`、`Resources/` 和 `MyCostApp.swift` 添加到项目中。
3. 在 Xcode Capabilities 中开启 CloudKit。
4. 修改 `MyCostApp.swift` 中的 CloudKit Container 为你的实际 ID。

## 必改项
- `project.yml` 中的 `PRODUCT_BUNDLE_IDENTIFIER` 与 `bundleIdPrefix`
- `MyCost.entitlements` 中的 `iCloud` Container
- `MyCostApp.swift` 中的 CloudKit Container 字符串

## 文档
- `docs/PRD.md`
- `docs/Tech_Spec.md`

## Agent 指令
- `AGENTS.md`
- `.agents/ui_agent.md`
- `.agents/data_agent.md`
- `.agents/backup_agent.md`
