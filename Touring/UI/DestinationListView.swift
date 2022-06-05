import SwiftUI

struct DestinationListView: View {
    struct Result: Equatable {
        private(set) var destination: Destination
    }

    @Binding var result: Result?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(DestinationSet.current.destinations, id: \.self) { dest in
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
                    DestinationSet.current.destinations.move(fromOffsets: from, toOffset: to)
                    try? DestinationSet.saveAll()
                }
                .onDelete { offsets in
                    DestinationSet.current.destinations.remove(atOffsets: offsets)
                    try? DestinationSet.saveAll()
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
        DestinationListView(result: .constant(nil))
    }
}
