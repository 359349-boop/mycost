import SwiftUI
import SwiftData

struct CategoryListView: View {
    @Query(sort: \Category.name) private var categories: [Category]
    @Environment(\.modelContext) private var context

    @State private var showingAdd = false
    @State private var editingCategory: Category?
    @State private var filterType: String = "Expense"

    var body: some View {
        List {
            Section {
                Picker("类型", selection: $filterType) {
                    Text("支出").tag("Expense")
                    Text("收入").tag("Income")
                }
                .pickerStyle(.segmented)
            }

            ForEach(filtered, id: \.id) { category in
                HStack(spacing: 12) {
                    CategoryIcon(iconName: category.iconName, colorHex: category.colorHex, size: 28, cornerRadius: 10)
                    Text(category.name)
                    Spacer()
                    Text(category.type == "Expense" ? "支出" : "收入")
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    editingCategory = category
                }
            }
            .onDelete(perform: delete)
        }
        .navigationTitle("分类管理")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAdd = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            CategoryEditorView(type: filterType)
        }
        .sheet(item: $editingCategory) { category in
            CategoryEditorView(category: category, type: category.type)
        }
    }

    private var filtered: [Category] {
        categories.filter { $0.type == filterType }
    }

    private func delete(at offsets: IndexSet) {
        let items = offsets.map { filtered[$0] }
        items.forEach { context.delete($0) }
    }
}
