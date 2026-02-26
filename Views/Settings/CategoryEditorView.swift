import SwiftUI
import SwiftData
import UIKit

struct CategoryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let category: Category?
    let type: String

    @State private var name: String
    @State private var iconName: String
    @State private var colorHex: String
    @State private var duplicateAlertMessage: String = ""
    @State private var showingDuplicateAlert = false

    private let icons: [String] = [
        "fork.knife", "tram", "bag", "gamecontroller", "cross", "house", "book",
        "banknote", "gift", "chart.line.uptrend.xyaxis", "sparkles",
        "cart", "car", "fuelpump", "cup.and.saucer", "tshirt", "heart",
        "airplane", "leaf", "pawprint", "ticket", "popcorn"
    ]

    private let palette: [String] = [
        "#FF453A", "#FF9F0A", "#FFD60A", "#32D74B", "#63E6E2",
        "#64D2FF", "#0A84FF", "#5E5CE6", "#BF5AF2", "#FF375F"
    ]

    init(category: Category? = nil, type: String) {
        self.category = category
        self.type = type
        _name = State(initialValue: category?.name ?? "")
        _iconName = State(initialValue: category?.iconName ?? "tag")
        _colorHex = State(initialValue: category?.colorHex ?? "#0A84FF")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("名称") {
                    TextField("分类名称", text: $name)
                }

                Section("图标") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(icons, id: \.self) { icon in
                                let isSelected = icon == iconName
                                Image(systemName: icon)
                                    .foregroundStyle(Color(hex: colorHex))
                                    .frame(width: 32, height: 32)
                                    .background(Color(hex: colorHex).opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(isSelected ? Color(hex: colorHex) : Color.clear, lineWidth: 2)
                                    )
                                    .onTapGesture { iconName = icon }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("颜色") {
                    HStack(spacing: 10) {
                        ForEach(palette, id: \.self) { hex in
                            let isSelected = hex == colorHex
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(hex: hex))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 2)
                                )
                                .onTapGesture { colorHex = hex }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(category == nil ? "添加分类" : "编辑分类")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("分类已存在", isPresented: $showingDuplicateAlert) {
                Button("知道了", role: .cancel) {}
            } message: {
                Text(duplicateAlertMessage)
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if hasDuplicateCategory(named: trimmed) {
            duplicateAlertMessage = "“\(trimmed)”已存在于当前\(type == "Expense" ? "支出" : "收入")分类中。"
            showingDuplicateAlert = true
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            return
        }

        if let existing = category {
            existing.name = trimmed
            existing.iconName = iconName
            existing.colorHex = colorHex
        } else {
            let nextIndex = (try? context.fetch(
                FetchDescriptor<Category>(predicate: #Predicate { $0.type == type })
            ).count) ?? 0
            let newCategory = Category(
                name: trimmed,
                iconName: iconName,
                colorHex: colorHex,
                type: type,
                sortIndex: nextIndex
            )
            context.insert(newCategory)
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        dismiss()
    }

    private func hasDuplicateCategory(named candidate: String) -> Bool {
        let fetch = FetchDescriptor<Category>(predicate: #Predicate { $0.type == type })
        let categoriesOfType = (try? context.fetch(fetch)) ?? []
        let normalizedCandidate = normalizedName(candidate)

        return categoriesOfType.contains { item in
            if let editing = category, item.persistentModelID == editing.persistentModelID {
                return false
            }
            return normalizedName(item.name) == normalizedCandidate
        }
    }

    private func normalizedName(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
    }
}
