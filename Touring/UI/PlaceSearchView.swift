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
                        vm.search(for: $0)
                    }
                    .overlay(alignment: .trailing) {
                        if !searchWord.isEmpty {
                            Button {
                                searchWord = ""
                                vm.results = []
                                focused = true
                            } label: {
                                // "xmark.circle.fill" is generally
                                // used, but lining up two identical
                                // icons should be avoided.
                                Image(systemName: "delete.left")
                                    .foregroundColor(.secondary)
                                    .padding(10)
                            }
                        }
                    }

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title)
                }
            }
            .padding()

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

    func search(for word: String) {
        // queryFragment is capable of updating in real time.
        comp.queryFragment = word

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
        PlaceSearchView(result: .constant(nil))
    }
}
