import Foundation
import SwiftData

enum CategorySeeder {
    private struct PresetCategory {
        let id: UUID
        let name: String
        let iconName: String
        let colorHex: String
        let type: String
        let sortIndex: Int
    }

    private static let presets: [PresetCategory] = [
        .init(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111001")!,
            name: "餐饮",
            iconName: "fork.knife",
            colorHex: "#FF9F0A",
            type: "Expense",
            sortIndex: 0
        ),
        .init(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111002")!,
            name: "交通",
            iconName: "tram",
            colorHex: "#0A84FF",
            type: "Expense",
            sortIndex: 1
        ),
        .init(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111003")!,
            name: "购物",
            iconName: "bag",
            colorHex: "#FF375F",
            type: "Expense",
            sortIndex: 2
        ),
        .init(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111004")!,
            name: "娱乐",
            iconName: "gamecontroller",
            colorHex: "#BF5AF2",
            type: "Expense",
            sortIndex: 3
        ),
        .init(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111005")!,
            name: "医疗",
            iconName: "cross",
            colorHex: "#FF453A",
            type: "Expense",
            sortIndex: 4
        ),
        .init(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111006")!,
            name: "居家",
            iconName: "house",
            colorHex: "#32D74B",
            type: "Expense",
            sortIndex: 5
        ),
        .init(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111007")!,
            name: "教育",
            iconName: "book",
            colorHex: "#5E5CE6",
            type: "Expense",
            sortIndex: 6
        ),
        .init(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222001")!,
            name: "工资",
            iconName: "banknote",
            colorHex: "#32D74B",
            type: "Income",
            sortIndex: 0
        ),
        .init(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222002")!,
            name: "奖金",
            iconName: "gift",
            colorHex: "#64D2FF",
            type: "Income",
            sortIndex: 1
        ),
        .init(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222003")!,
            name: "理财收入",
            iconName: "chart.line.uptrend.xyaxis",
            colorHex: "#0A84FF",
            type: "Income",
            sortIndex: 2
        ),
        .init(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222004")!,
            name: "其他",
            iconName: "sparkles",
            colorHex: "#FF453A",
            type: "Income",
            sortIndex: 3
        )
    ]

    static func seedIfNeeded(context: ModelContext) {
        let fetch = FetchDescriptor<Category>()
        let existing = (try? context.fetch(fetch)) ?? []

        for preset in presets {
            if let category = existing.first(where: { $0.id == preset.id }) {
                category.name = preset.name
                category.iconName = preset.iconName
                category.colorHex = preset.colorHex
                category.type = preset.type
                category.sortIndex = preset.sortIndex
                continue
            }

            // Old builds seeded random UUIDs; guard by name+type to avoid duplicates after sync.
            if existing.contains(where: { $0.name == preset.name && $0.type == preset.type }) {
                continue
            }

            context.insert(
                Category(
                    id: preset.id,
                    name: preset.name,
                    iconName: preset.iconName,
                    colorHex: preset.colorHex,
                    type: preset.type,
                    sortIndex: preset.sortIndex
                )
            )
        }
    }
}
