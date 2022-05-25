import SwiftUI

struct DestinationListView: View {
    struct Result: Equatable {
        private(set) var destination: Destination
    }

    @Binding var list: [Destination]
    @Binding var result: Result?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(list, id: \.self) { dest in
                    VStack(alignment: .leading) {
                        Text(dest.title ?? "")
                            .bold()
                        Text("\(dest.coordinate.latitude),\(dest.coordinate.longitude)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .onTapGesture {
                        result = Result(destination: dest)
                        dismiss()
                    }
                }
                .onMove { from, to in
                    list.move(fromOffsets: from, toOffset: to)
                    try? Destination.save(list)
                }
                .onDelete { offsets in
                    list.remove(atOffsets: offsets)
                    try? Destination.save(list)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    EditButton()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.title)
                    }
                }
            }
        }
    }
}

struct DestinationListView_Previews: PreviewProvider {
    static var previews: some View {
        DestinationListView(list: .constant([]), result: .constant(nil))
    }
}
