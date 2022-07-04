import CoreLocation
import SwiftUI

struct DestinationDetail: Identifiable {
    var id: Int
    var title: String
    var coordinate: CLLocationCoordinate2D
    var update: ((DestinationDetail) -> Void)?
    var remove: ((DestinationDetail) -> Void)?
    var move: ((DestinationDetail) -> Void)?

    init(_ destination: Destination, at id: Int,
         onUpdate: ((DestinationDetail) -> Void)? = nil,
         onRemove: ((DestinationDetail) -> Void)? = nil,
         onMove: ((DestinationDetail) -> Void)? = nil) {
        self.title = destination.title ?? ""
        self.coordinate = destination.coordinate
        self.id = id
        self.update = onUpdate
        self.remove = onRemove
        self.move = onMove
    }
}

struct DestinationDetailView: View {
    @State var dest: DestinationDetail
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
                        .clearButton(text: $dest.title, focused: $focused)
                    Text("\(dest.coordinate.latitude) \(dest.coordinate.longitude)")
                        .textSelection(.enabled)
                }
                Section {
                    Button {
                        dest.move?(dest)
                        dismiss()
                    } label: {
                        Label("Move", systemImage: "mappin.and.ellipse")
                    }
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
        DestinationDetailView(dest: DestinationDetail(Destination(), at: 0))
    }
}
