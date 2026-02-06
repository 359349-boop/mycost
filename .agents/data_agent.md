# Data & Logic Architect Agent

## 数据职责
- 模型设计：定义 `Transaction` 和 `Category` 模型，适配 CloudKit 同步要求。
- 统计逻辑：使用 Swift Charts 实现月度/年度聚合统计。
- DDD 实践：确保 Repository 模式与 View 分离。

## 统计口径
- 月度汇总：按月份聚合支出、收入、结余。
- 分类汇总：按分类聚合支出金额（默认仅统计支出）。
- 年度趋势：按月输出全年收支趋势数据源。

## 关键指令
- 所有查询（`@Query`）必须考虑性能过滤与排序。
- 负责初始化内置分类数据（收入/支出预设）。
