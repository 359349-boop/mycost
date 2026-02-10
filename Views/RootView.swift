import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @State private var showingAdd = false
    @State private var isKeyboardVisible = false

    var body: some View {
        ZStack {
            TabView {
                NavigationStack {
                    HomeView()
                }
                .tabItem {
                    Label("账本", systemImage: "list.bullet.rectangle")
                }

                NavigationStack {
                    StatsView()
                }
                .tabItem {
                    Label("统计", systemImage: "chart.bar.xaxis")
                }
            }

            plusButton
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .sheet(isPresented: $showingAdd) {
            AddTransactionView()
        }
        .task {
            CategorySeeder.seedIfNeeded(context: context)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            withAnimation(.easeOut(duration: 0.2)) {
                isKeyboardVisible = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.2)) {
                isKeyboardVisible = false
            }
        }
    }

    private var plusButton: some View {
        VStack {
            Spacer()
            Button {
                showingAdd = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .frame(width: 56, height: 56)
                    .background(Color(.systemGreen))
                    .foregroundStyle(.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 6)
            }
            .buttonStyle(NoHighlightButtonStyle())
            .padding(.bottom, 18)
        }
        .opacity(isKeyboardVisible ? 0 : 1)
        .allowsHitTesting(!isKeyboardVisible)
    }
}

private struct NoHighlightButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(1)
            .scaleEffect(1)
    }
}
