import SwiftUI
import SwiftData

struct CategoryListView: View {
    @Query(sort: \Category.sortIndex) private var categories: [Category]
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
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    editingCategory = category
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        delete(category)
                    } label: {
                        Text("删除")
                    }
                }
            }
            .onMove(perform: move)
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
        .environment(\.editMode, .constant(.active))
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

    private func delete(_ category: Category) {
        context.delete(category)
        normalizeSortIndex()
    }

    private func move(from source: IndexSet, to destination: Int) {
        var items = filtered
        items.move(fromOffsets: source, toOffset: destination)
        for (index, item) in items.enumerated() {
            item.sortIndex = index
        }
    }

    private func normalizeSortIndex() {
        let items = filtered
        for (index, item) in items.enumerated() {
            item.sortIndex = index
        }
    }
}
