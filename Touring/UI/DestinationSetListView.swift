import SwiftUI

struct DestinationSetListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var editMode: EditMode = .inactive
    @State private var rootShouldClose = false

    var body: some View {
        NavigationView {
            Form {
                List {
                    ForEach(DestinationSet.all, id: \.self) { destset in
                        NavigationLink {
                            DestinationSetListDetailView(of: destset, rootShouldClose: $rootShouldClose)
                        } label: {
                            DestinationSetListRow(of: destset) {
                                DestinationSet.select($0)
                                try? DestinationSet.saveAll()
                                dismiss()
                            }
                        }
                    }
                    .onDelete { offsets in
                        var list = DestinationSet.all
                        list.remove(atOffsets: offsets)
                        if list.isEmpty {
                            DestinationSet.current = DestinationSet()
                            DestinationSet.others = []
                        } else {
                            DestinationSet.current = list[0]
                            DestinationSet.others = Array(list.dropFirst())
                        }
                        try? DestinationSet.saveAll()

                        if DestinationSet.current.isEmpty {
                            // Now this sheet can do nothing.
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        DestinationSet.others = DestinationSet.all
                        DestinationSet.current = DestinationSet()
                        try? DestinationSet.saveAll()
                        dismiss()
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                    .disabled(DestinationSet.current.isEmpty)
                }
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
        .onChange(of: rootShouldClose) {
            if $0 { dismiss() }
        }
    }
}

struct DestinationSetListRow: View {
    typealias SelectHandler = (DestinationSet) -> Void

    private var destset: DestinationSet
    private var onSelect: SelectHandler?

    init(of destset: DestinationSet, onSelect: SelectHandler? = nil) {
        self.destset = destset
        self.onSelect = onSelect
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(destset.name ?? "")
                    .bold()
                (Text("Destinations") + Text(": (\(destset.destinations.count)) \(destset.routeSummary ?? "")"))
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            if destset != DestinationSet.current {
                Spacer()
                Button {
                    onSelect?(destset)
                } label: {
                    Image(systemName: "square.and.arrow.up.on.square")
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
    }
}

struct DestinationSetListDetailView: View {
    private var destset: DestinationSet
    private var rootShouldClose: Binding<Bool>?
    @Environment(\.dismiss) private var dismiss

    init(of destset: DestinationSet, rootShouldClose: Binding<Bool>? = nil) {
        self.destset = destset
        self.rootShouldClose = rootShouldClose
    }

    private func dismissAll() {
        if let rootShouldClose = rootShouldClose {
            rootShouldClose.wrappedValue = true
        } else {
            dismiss()
        }
    }

    var body: some View {
        Form {
            Section {
                Text(destset.name ?? "")
                    .font(.title).bold()
            } header: {
                Text("Destination Set")
            }
            Section {
                List(destset.destinations, id: \.self) { dest in
                    VStack(alignment: .leading) {
                        Text(dest.title ?? "")
                            .bold()
                        Text("\(dest.coordinate.latitude),\(dest.coordinate.longitude)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Destinations")
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    DestinationSet.select(destset)
                    try? DestinationSet.saveAll()
                    dismissAll()
                } label: {
                    Image(systemName: "square.and.arrow.up.on.square")
                }
                .disabled(destset == DestinationSet.current)

                Button {
                    dismissAll()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title)
                }
            }
        }
    }
}

struct DestinationSetListView_Previews: PreviewProvider {
    static var previews: some View {
        DestinationSetListView()
    }
}
