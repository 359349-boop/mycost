import SwiftUI
import SwiftData

struct CategoryListView: View {
    @Query(sort: \Category.name) private var categories: [Category]

    var body: some View {
        List {
            ForEach(categories, id: \.id) { category in
                HStack(spacing: 12) {
                    Image(systemName: category.iconName)
                        .frame(width: 24, height: 24)
                    Text(category.name)
                    Spacer()
                    Text(category.type == "Expense" ? "支出" : "收入")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("分类管理")
    }
}
