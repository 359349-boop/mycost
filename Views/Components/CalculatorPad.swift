import SwiftUI

struct CalculatorPad: View {
    @Binding var expression: String
    let isCompleteEnabled: Bool
    let onComplete: () -> Void

    @State private var isDivideMode = false
    @State private var isSubtractMode = false

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                calcButton("7") { append("7") }
                calcButton("8") { append("8") }
                calcButton("9") { append("9") }
                opToggleButton(isDivideMode ? "÷" : "×") {
                    appendOperator(isDivideMode ? "÷" : "×")
                } onDoubleTap: {
                    isDivideMode.toggle()
                    appendOperator(isDivideMode ? "÷" : "×")
                }
            }

            HStack(spacing: 12) {
                calcButton("4") { append("4") }
                calcButton("5") { append("5") }
                calcButton("6") { append("6") }
                opToggleButton(isSubtractMode ? "−" : "+") {
                    appendOperator(isSubtractMode ? "-" : "+")
                } onDoubleTap: {
                    isSubtractMode.toggle()
                    appendOperator(isSubtractMode ? "-" : "+")
                }
            }

            HStack(spacing: 12) {
                calcButton("1") { append("1") }
                calcButton("2") { append("2") }
                calcButton("3") { append("3") }
                funcButton("C") { clearAll() }
            }

            HStack(spacing: 12) {
                funcButton("⌫") { deleteLast() }
                calcButton("0") { append("0") }
                calcButton(".") { appendDot() }
                completeButton
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(18)
        .padding([.horizontal, .bottom])
    }

    private func calcButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.title3)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(.systemBackground))
                .cornerRadius(14)
        }
    }

    private func opToggleButton(
        _ title: String,
        onTap: @escaping () -> Void,
        onDoubleTap: @escaping () -> Void
    ) -> some View {
        let gesture = TapGesture(count: 2)
            .exclusively(before: TapGesture(count: 1))
            .onEnded { value in
                switch value {
                case .first:
                    onDoubleTap()
                case .second:
                    onTap()
                }
            }

        return Text(title)
            .font(.title3)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.accentColor.opacity(0.15))
            .foregroundStyle(Color.accentColor)
            .cornerRadius(14)
            .contentShape(Rectangle())
            .gesture(gesture)
    }

    private func funcButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.title3)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(.systemBackground))
                .foregroundStyle(.secondary)
                .cornerRadius(14)
        }
    }

    private var completeButton: some View {
        Button {
            onComplete()
        } label: {
            Text("完成")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isCompleteEnabled ? Color.accentColor : Color.gray.opacity(0.3))
                .foregroundStyle(isCompleteEnabled ? .white : .secondary)
                .cornerRadius(14)
        }
        .disabled(!isCompleteEnabled)
    }

    private func append(_ value: String) {
        if expression == "0" {
            expression = value
        } else {
            expression.append(value)
        }
    }

    private func appendDot() {
        let current = currentNumber()
        guard !current.contains(".") else { return }
        if current.isEmpty {
            expression.append("0.")
        } else {
            expression.append(".")
        }
    }

    private func appendOperator(_ op: String) {
        guard !expression.isEmpty else {
            if op == "-" { expression = "-" }
            return
        }
        if let last = expression.last, isOperator(last) {
            expression.removeLast()
        }
        expression.append(op)
    }

    private func clearAll() {
        expression = ""
    }

    private func deleteLast() {
        guard !expression.isEmpty else { return }
        expression.removeLast()
    }

    private func currentNumber() -> String {
        let ops = "+-×÷"
        if let idx = expression.lastIndex(where: { ops.contains($0) }) {
            let next = expression.index(after: idx)
            return String(expression[next..<expression.endIndex])
        }
        return expression
    }

    private func isOperator(_ char: Character) -> Bool {
        "+-×÷".contains(char)
    }
}

enum CalculatorEngine {
    static func evaluate(_ expression: String) -> Double? {
        let cleaned = expression.replacingOccurrences(of: "×", with: "*")
            .replacingOccurrences(of: "÷", with: "/")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleaned.isEmpty else { return nil }

        var tokens: [Token] = []
        var current = ""
        var lastWasOperator = true

        for char in cleaned {
            if char.isNumber || char == "." {
                current.append(char)
                lastWasOperator = false
            } else if isOperator(char) {
                if char == "-" && lastWasOperator {
                    current.append(char)
                    lastWasOperator = false
                    continue
                }
                if !current.isEmpty {
                    if let number = Double(current) {
                        tokens.append(.number(number))
                    } else {
                        return nil
                    }
                    current = ""
                }
                tokens.append(.op(char))
                lastWasOperator = true
            }
        }

        if !current.isEmpty {
            if let number = Double(current) {
                tokens.append(.number(number))
            } else {
                return nil
            }
        }

        // Remove trailing operator if any
        if case .op = tokens.last {
            tokens.removeLast()
        }

        return evaluateTokens(tokens)
    }

    static func formatForInput(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    private static func evaluateTokens(_ tokens: [Token]) -> Double? {
        var values: [Double] = []
        var ops: [Character] = []

        for token in tokens {
            switch token {
            case .number(let value):
                values.append(value)
            case .op(let op):
                while let last = ops.last, precedence(of: last) >= precedence(of: op) {
                    guard apply(&values, op: ops.removeLast()) else { return nil }
                }
                ops.append(op)
            }
        }

        while let op = ops.popLast() {
            guard apply(&values, op: op) else { return nil }
        }

        return values.count == 1 ? values[0] : nil
    }

    private static func apply(_ values: inout [Double], op: Character) -> Bool {
        guard values.count >= 2 else { return false }
        let rhs = values.removeLast()
        let lhs = values.removeLast()
        let result: Double
        switch op {
        case "+": result = lhs + rhs
        case "-": result = lhs - rhs
        case "*": result = lhs * rhs
        case "/":
            guard rhs != 0 else { return false }
            result = lhs / rhs
        default:
            return false
        }
        values.append(result)
        return true
    }

    private static func precedence(of op: Character) -> Int {
        switch op {
        case "*", "/": return 2
        case "+", "-": return 1
        default: return 0
        }
    }

    private static func isOperator(_ char: Character) -> Bool {
        "+-*/".contains(char)
    }

    private enum Token {
        case number(Double)
        case op(Character)
    }
}
