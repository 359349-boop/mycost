import SwiftUI

struct StatSummaryCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let systemImage: String?
    let tint: Color?

    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        systemImage: String? = nil,
        tint: Color? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tint = tint
    }

    var body: some View {
        HStack(spacing: 12) {
            if let systemImage, let tint {
                Image(systemName: systemImage)
                    .foregroundStyle(tint)
                    .frame(width: 28, height: 28)
                    .background(tint.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title3)
                    .bold()
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}
