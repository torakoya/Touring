import SwiftUI

struct DestinationListView: View {
    struct Result: Equatable {
        private(set) var destination: Destination
    }

    @Binding var result: Result?
    @Environment(\.dismiss) private var dismiss
    // To avoid intermittent edit mode, give this view its own EditMode variable.
    @State private var editMode: EditMode = .inactive
    @State private var name = DestinationSet.current.name ?? ""
    @FocusState private var focused

    var body: some View {
        NavigationView {
            Form {
                Section {
                    if editMode != .active {
                        Text(name).font(.title).bold()
                    } else {
                        TextField("Name", text: $name)
                            .submitLabel(.done)
                            .font(.title)
                            .focused($focused)
                            .clearButton(text: $name, focused: $focused)
                    }
                } header: {
                    Text("Destination Set")
                }
                .onDisappear {
                    let name = name.isEmpty ? nil : name
                    if name != DestinationSet.current.name {
                        DestinationSet.current.name = name
                        try? DestinationSet.saveAll()
                    }
                }

                Section {
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
                } header: {
                    Text("Destinations")
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(NavigationBarItem.TitleDisplayMode.inline)
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
            .environment(\.editMode, $editMode)
        }
    }
}

struct DestinationListView_Previews: PreviewProvider {
    static var previews: some View {
        DestinationListView(result: .constant(nil))
    }
}
