import MapKit
import SwiftUI

struct PlaceSearchResult: Equatable {
    enum Action {
        case show, pin
    }

    fileprivate(set) var mapItem: MKMapItem
    fileprivate(set) var action: Action
}

struct PlaceSearchView: View {
    @StateObject var vm = PlaceSearchViewModel()
    @State var searchWord: String = ""
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool
    @Binding var result: PlaceSearchResult?
    var region: MKCoordinateRegion?
    @State private var searchesInMap = true

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                TextField("Search", text: $searchWord)
                    .submitLabel(.done)
                    .textFieldStyle(.roundedBorder)
                    .focused($focused)
                    .onAppear {
                        // Focusing needs some wait.
                        Task {
                            for _ in 0..<7 where !focused {
                                focused = true
                                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 secs
                            }
                        }
                    }
                    .onChange(of: searchWord) {
                        vm.search(for: $0, in: searchesInMap ? region : nil)
                    }
                    // Use "delete.left" to avoid lining up two "xmark.circle.fill".
                    .clearButton(text: $searchWord, focused: $focused, imageName: "delete.left")

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title)
                }
            }
            .padding()

            Toggle(isOn: $searchesInMap) {
                Text("Prefer This Area")
            }
            .padding([.leading, .trailing, .bottom])
            .onChange(of: searchesInMap) {
                vm.search(for: searchWord, in: $0 ? region : nil)
            }

            List(vm.results, id: \.self) { e in
                HStack {
                    VStack(alignment: .leading) {
                        Text(e.title).bold()
                        Text(e.subtitle).font(.footnote).foregroundColor(.secondary)
                    }
                    Spacer()

                    Button {
                        vm.fetchDetail(of: e) {
                            result = PlaceSearchResult(mapItem: $0, action: .pin)
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "mappin.circle")
                            .font(.largeTitle)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    vm.fetchDetail(of: e) {
                        result = PlaceSearchResult(mapItem: $0, action: .show)
                        dismiss()
                    }
                }
            }
        }
    }
}

class PlaceSearchViewModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    let comp = MKLocalSearchCompleter()
    @Published var results: [MKLocalSearchCompletion] = []

    override init() {
        super.init()

        comp.delegate = self
        comp.resultTypes = [.address, .pointOfInterest]
    }

    func search(for word: String, in region: MKCoordinateRegion? = nil) {
        // queryFragment is capable of updating in real time.
        comp.queryFragment = word

        if let region = region {
            comp.region = region
        } else {
            // The default value; seems to search near the current location.
            comp.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 180, longitudeDelta: 360))
        }

        if word.isEmpty {
            results = []
        }
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results
    }

    typealias CompletionHandler = (MKMapItem) -> Void

    func fetchDetail(of completion: MKLocalSearchCompletion, onComplete: @escaping CompletionHandler) {
        let req = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: req)
        Task { @MainActor in
            do {
                let response = try await search.start()
                if let mapItem = response.mapItems.first {
                    onComplete(mapItem)
                }
            } catch {
                // Ignore an error.
            }
        }
    }
}

struct PlaceSearchView_Previews: PreviewProvider {
    static var previews: some View {
        PlaceSearchView(result: .constant(nil), region: nil)
    }
}
