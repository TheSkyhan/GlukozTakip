import SwiftUI

struct PremiumTextField: View {
    let title: String
    @Binding var text: String
    var width: CGFloat? = nil
    var alignment: TextAlignment = .leading
    var isMonospacedDigits: Bool = false

    var body: some View {
        TextField(title, text: $text)
            .textFieldStyle(.plain)
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .multilineTextAlignment(alignment)
            .if(isMonospacedDigits) { view in
                view.monospacedDigit()
            }
            .premiumField()
            .frame(width: width)
    }
}

struct PremiumTextEditor: View {
    let placeholder: String
    @Binding var text: String
    var height: CGFloat = 120

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(placeholder)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 8)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
            }
            TextEditor(text: $text)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(.primary)
                .scrollContentBackground(.hidden)
        }
        .frame(height: height)
        .premiumField()
    }
}

struct PremiumDateField: View {
    let selection: Binding<Date>
    let components: DatePickerComponents

    var body: some View {
        DatePicker("", selection: selection, displayedComponents: components)
#if os(iOS)
            .datePickerStyle(.compact)
#else
            .datePickerStyle(.field)
#endif
            .labelsHidden()
            .premiumField()
    }
}

struct PremiumSegmentedPicker<SelectionValue: Hashable, Content: View>: View {
    let title: String
    let selection: Binding<SelectionValue>
    let content: Content

    init(_ title: String, selection: Binding<SelectionValue>, @ViewBuilder content: () -> Content) {
        self.title = title
        self.selection = selection
        self.content = content()
    }

    var body: some View {
        Picker(title, selection: selection) {
            content
        }
        .pickerStyle(.segmented)
        .controlSize(.large)
    }
}

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
