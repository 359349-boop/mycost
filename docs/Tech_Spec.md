# Technical Specification (Tech Spec)

## 1. 技术栈
- 语言：Swift 5.10+
- 框架：SwiftUI
- 持久化：SwiftData（iOS 17+）
- 图表：Swift Charts
- 云服务：CloudKit（iCloud）

## 2. 架构设计（MVVM + DDD）
采用领域驱动设计（DDD）的思想，将业务逻辑与 UI 解耦。
- Domain Layer：定义 `Transaction` 和 `Category` 实体。
- Data Layer：SwiftData 容器管理与 CRUD。
- Presentation Layer：SwiftUI Views 与 ViewModel（`@Observable`）。

## 3. 数据模型（Schema）
为 CloudKit 同步提供默认值，避免不必要的可选属性。

### 3.1 Transaction (Entity)
- `id: UUID`
- `amount: Decimal`
- `type: String` (Income / Expense)
- `category: Category?`
- `date: Date`
- `note: String?`

### 3.2 Category (Entity)
- `id: UUID`
- `name: String`
- `iconName: String` (SF Symbols)
- `colorName: String`（语义色或资源名）
- `type: String` (Income / Expense)

## 4. 关键技术实现
### 4.1 iCloud 同步
- 在 Xcode Capabilities 中开启 CloudKit。
- 使用 `ModelConfiguration(cloudKitDatabase: .private("iCloud.com.yourname.ledger"))`。
- 冲突策略：最后写入为准（Last-Write-Wins）。

### 4.2 外观适配
- 使用系统语义色与资产色，默认跟随系统深浅色。
- 不强制设置 `preferredColorScheme`。

## 5. 项目目录结构
```text
/Models      - SwiftData Entities
/ViewModels  - Business Logic
/Views       - SwiftUI Components
  /Home
  /Stats
  /Settings
/Services    - iCloud Sync Services
/Resources   - Assets, Localization
```
