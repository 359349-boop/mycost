import SwiftUI

struct ICloudSyncStatusCard: View {
    let state: CloudSyncState
    let onRefresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: iconName)
                    .font(.title3)
                    .foregroundStyle(iconColor)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(titleText)
                        .font(.headline)
                    Text(detailText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if showsActivityIndicator {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if showsRefreshButton {
                Button("重新检测") {
                    onRefresh()
                }
                .buttonStyle(.borderedProminent)
                .tint(iconColor)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .listRowBackground(Color.clear)
    }

    private var iconName: String {
        switch state {
        case .checking:
            return "icloud"
        case .syncing:
            return "arrow.triangle.2.circlepath.icloud"
        case .ready:
            return "checkmark.icloud.fill"
        case .unavailable:
            return "icloud.slash"
        case .error:
            return "exclamationmark.icloud"
        }
    }

    private var iconColor: Color {
        switch state {
        case .checking, .syncing:
            return .blue
        case .ready:
            return .green
        case .unavailable:
            return .orange
        case .error:
            return .red
        }
    }

    private var titleText: String {
        switch state {
        case .checking:
            return "正在检查 iCloud 状态"
        case .syncing:
            return "iCloud 同步中"
        case .ready:
            return "iCloud 自动同步已开启"
        case .unavailable:
            return "iCloud 当前不可用"
        case .error:
            return "iCloud 同步异常"
        }
    }

    private var detailText: String {
        switch state {
        case .checking:
            return "将自动检测账号与同步能力。"
        case .syncing:
            return "正在上传或下载账目变更，请稍候。"
        case .ready(let lastSyncAt):
            if let lastSyncAt {
                return "最近同步：\(Self.dateFormatter.string(from: lastSyncAt))"
            }
            return "已启用自动同步，删除 App 后重装可自动恢复。"
        case .unavailable(let reason):
            switch reason {
            case .noAccount:
                return "未登录 iCloud。请在系统设置登录 Apple ID 并开启 iCloud Drive。"
            case .restricted:
                return "iCloud 被系统策略限制，当前无法同步。"
            case .temporarilyUnavailable:
                return "iCloud 服务暂时不可用，请稍后重试。"
            case .couldNotDetermine:
                return "暂时无法确认 iCloud 状态，请检查网络后重试。"
            case .notConfigured:
                return "当前为本地存储模式，请检查 CloudKit 容器与签名配置。"
            }
        case .error(let message):
            return "错误信息：\(message)"
        }
    }

    private var showsActivityIndicator: Bool {
        switch state {
        case .checking, .syncing:
            return true
        default:
            return false
        }
    }

    private var showsRefreshButton: Bool {
        switch state {
        case .checking, .syncing:
            return false
        default:
            return true
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}
