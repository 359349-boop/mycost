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
- `colorHex: String`（Hex 格式，e.g. "#RRGGBB"）
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

## 6. Icon Color System (图标颜色规范)

### 6.1 存储格式
- 所有的 Category 颜色统一使用 Hex 格式存储：`String` (e.g., "#RRGGBB")。

### 6.2 预设色值 (App Preset Palette)
系统应内置至少 10 种预设色值，采用 iOS System Colors 的广色域标准：
- Red: #FF453A, Orange: #FF9F0A, Yellow: #FFD60A, Green: #32D74B, Mint: #63E6E2, Teal: #64D2FF, Blue: #0A84FF, Indigo: #5E5CE6, Purple: #BF5AF2, Pink: #FF375F.

### 6.3 渲染逻辑 (Dark Mode Adaptation)
- 浅色模式：图标背景使用 `Color(hex)`（100% 不透明度），图标本身使用白色。
- 深色模式：图标背景使用 `Color(hex)`（100% 不透明度），图标本身保持白色。
- 通过“彩色底 + 白色图标”形成清晰对比。
