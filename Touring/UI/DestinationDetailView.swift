import MapKit
import SwiftUI

class DestinationDetail: Identifiable {
    var id: Int
    var title: String
    var coordinate: CLLocationCoordinate2D
    var update: ((DestinationDetail) -> Void)?
    var remove: ((DestinationDetail) -> Void)?

    init(_ annotation: MKPointAnnotation, at id: Int,
         onUpdate: ((DestinationDetail) -> Void)? = nil,
         onRemove: ((DestinationDetail) -> Void)? = nil) {
        self.title = annotation.title ?? ""
        self.coordinate = annotation.coordinate
        self.id = id
        self.update = onUpdate
        self.remove = onRemove
    }
}

struct DestinationDetailView: View {
    @Binding var dest: DestinationDetail
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool
    @State private var removeButtonTapped = false

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Destination \(dest.id + 1)").font(.title)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title)
                }
            }.padding()
            List {
                Section {
                    TextField("Name", text: $dest.title)
                        .submitLabel(.done)
                        .focused($focused)
                        .onChange(of: focused) { newValue in
                            if !newValue && !removeButtonTapped {
                                dest.update?(dest)
                            }
                        }
                    Text("\(dest.coordinate.latitude) \(dest.coordinate.longitude)")
                        .textSelection(.enabled)
                }
                Section {
                    Button(role: .destructive) {
                        removeButtonTapped = true
                        dest.remove?(dest)
                        dismiss()
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                }
            }
        }
    }
}

struct DestinationDetailView_Previews: PreviewProvider {
    static var previews: some View {
        DestinationDetailView(dest: .constant(DestinationDetail(MKPointAnnotation(), at: 0)))
    }
}
