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
- 主题设置：支持「跟随系统 / 浅色 / 深色」。
  - 持久化：`AppStorage`，key 为 `app_theme`，默认 `system`（跟随系统）。
  - 应用策略：仅在用户选择浅色/深色时设置 `preferredColorScheme`；选择跟随系统时不覆盖（传 `nil`）。

### 4.3 统计页重设计（Stats）
- 顶部切换：使用 `TabView` 左右滑动切换「月/年」周期，并显示当前周期时间。
- 收支分析（Trend）：
  - 图表：使用 `BarMark` 绘制收入/支出双柱月度趋势。
  - 滑动：启用 `.chartScrollableAxes(.horizontal)`，可视范围固定为 6 个月，默认定位到当前月。
  - 数据范围：仅包含历史月份（`earliestMonth...currentMonthEnd`），不展示未来月份。
  - 动态尺度：y 轴最大值/中值基于当前可视 6 个月计算。
  - 可视窗口判定：以当前滚动右边界月份为锚点，向左回推 6 个月生成窗口，避免边界月份抖动导致窗口漂移。
  - 防误判策略：不使用 `ChartProxy` 的像素坐标反推可视月份，避免将窗口外历史极值（如 2025-05）错误纳入 y 轴计算。
- Donut：`SectorMark` + `innerRadius`，外侧使用引线 + `annotation` 放置分类图标与百分比。
- 构成分布：支持「支出/收入」切换，切换后 Donut 与分类列表联动刷新。
- 颜色规范：Donut 分段使用 `Category.colorHex`。
- 深色模式：文字使用 `.primary` / `.secondary`。
- 动画：切换周期时，环形图弧度使用 Spring 动画过渡。

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
