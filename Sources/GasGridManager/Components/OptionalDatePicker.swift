import SwiftUI

struct OptionalDatePicker: View {
    let title: String
    @Binding var date: Date?
    @State private var hasDate: Bool

    init(title: String, date: Binding<Date?>) {
        self.title = title
        self._date = date
        self._hasDate = State(initialValue: date.wrappedValue != nil)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.paddingS) {
            Toggle("\(title)", isOn: $hasDate)
                .toggleStyle(.checkbox)
            if hasDate {
                DatePicker(title, selection: Binding(
                    get: { date ?? Date() },
                    set: { date = $0 }
                ), displayedComponents: .date)
                .labelsHidden()
            }
        }
        .onChange(of: hasDate) { _, newValue in
            if !newValue { date = nil }
            else if date == nil { date = Date() }
        }
    }
}
