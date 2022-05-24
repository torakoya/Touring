import SwiftUI
import MapKit

struct DestinationListView: View {
    struct Result: Equatable {
        private(set) var destination: MKPointAnnotation
    }

    @Binding var list: [MKPointAnnotation]
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
                    try? MapUtil.saveDestinations(list)
                }
                .onDelete { offsets in
                    list.remove(atOffsets: offsets)
                    try? MapUtil.saveDestinations(list)
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
