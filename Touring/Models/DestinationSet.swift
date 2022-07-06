import Combine
import Foundation

class DestinationSet: Codable {
    var name: String?

    var note: String?

    var destinations: [Destination] = [] {
        didSet {
            let oldTarget = targetIndex.map { oldValue[$0] }

            if oldValue != destinations {
                destinationsSubject.send(destinations)
            }

            // If the previously aimed-at target still exists, it
            // should be kept aimed at.
            if let oldTarget = oldTarget, let index = destinations.firstIndex(of: oldTarget), targetIndex != index {
                targetIndex = index
                return
            }

            // If the old and the new destinations[targetIndex] aren't
            // the same, send targetIndex's notification.
            if let index = targetIndex,
                !oldValue.indices.contains(index) ||
                (destinations.indices.contains(index) && oldValue[index] != destinations[index]) {
                targetIndexSubject.send(targetIndex)
                targetSubject.send(target)
                return
            }

            trimTargetIndex()
        }
    }

    var isEmpty: Bool {
        (name.map { $0.isEmpty } ?? true) &&
        (note.map { $0.isEmpty } ?? true) &&
        destinations.isEmpty
    }

    var routeSummary: String? {
        let s = destinations.reversed().compactMap { $0.title }.joined(separator: "\u{2190}")
        return s.isEmpty ? nil : s
    }

    // MARK: - Manipulating the Target

    var targetIndex: Int? {
        didSet {
            trimTargetIndex()
            if oldValue != targetIndex {
                targetIndexSubject.send(targetIndex)
                targetSubject.send(target)
            }
        }
    }

    /// The destination currently headed for.
    var target: Destination? {
        targetIndex.map { destinations.indices.contains($0) ? destinations[$0] : nil } ?? nil
    }

    private func trimTargetIndex() {
        var newValue = destinations.isEmpty ? nil : (targetIndex ?? destinations.startIndex)

        if let index = newValue {
            if index >= destinations.endIndex {
                newValue = destinations.endIndex - 1
            } else if index < destinations.startIndex {
                newValue = destinations.startIndex
            }
        }

        if targetIndex != newValue {
            targetIndex = newValue
        }
    }

    private func circulateTargetIndex(_ delta: Int = 0) {
        if let index = targetIndex.map({ $0 + delta }) {
            let index2 = index % (destinations.endIndex - destinations.startIndex) + destinations.startIndex
            let index3 = (index2 >= 0) ? index2 : (destinations.endIndex + index2)
            if targetIndex != index3 {
                targetIndex = index3
            }
        }
    }

    func goForward() {
        circulateTargetIndex(1)
    }

    func goBackward() {
        circulateTargetIndex(-1)
    }

    // MARK: - Notifying Modification

    private let destinationsSubject = PassthroughSubject<[Destination], Never>()
    private let targetIndexSubject = PassthroughSubject<Int?, Never>()
    private let targetSubject = PassthroughSubject<Destination?, Never>()

    var destinationsPublisher: AnyPublisher<[Destination], Never> {
        Just(destinations).merge(with: destinationsSubject).eraseToAnyPublisher()
    }

    var targetIndexPublisher: AnyPublisher<Int?, Never> {
        Just(targetIndex).merge(with: targetIndexSubject).eraseToAnyPublisher()
    }

    var targetPublisher: AnyPublisher<Destination?, Never> {
        Just(target).merge(with: targetSubject).eraseToAnyPublisher()
    }

    // MARK: - Saving and Loading

    enum CodingKeys: String, CodingKey {
        case name
        case note
        case destinations
    }

    enum Error: Swift.Error {
        case fileIOError(original: Swift.Error?)
        case jsonCodingError
    }

    static var destinationFileUrl: URL {
        FileManager.default.documentURL(of: "destinations.json")
    }

    static func save(_ destsets: [DestinationSet]) throws {
        guard let json = try? JSONEncoder().encode(destsets) else {
            throw Error.jsonCodingError
        }

        if !FileManager.default.createFile(atPath: destinationFileUrl.path, contents: json) {
            throw Error.fileIOError(original: nil)
        }
    }

    static func load() throws -> [DestinationSet] {
        guard let json = FileManager.default.contents(atPath: destinationFileUrl.path) else {
            return []
        }

        guard let destsets = try? JSONDecoder().decode([DestinationSet].self, from: json) else {
            throw Error.jsonCodingError
        }

        return destsets
    }

    // MARK: - Shared Objects

    /// The DestinationSet that is currently selected.
    static var current = DestinationSet() {
        didSet {
            if oldValue !== current {
                currentSubject.send(current)

                // Invoke didSet.
                current.destinations = current.destinations
                current.targetIndex = current.targetIndex
            }
        }
    }

    /// All the DestinationSets except `current`.
    static var others: [DestinationSet] = [] {
        // This is only required to determine whether the menu item
        // [Switch Destination Set] should be enabled. And it would be
        // better to use the existing property currentPublisher rather
        // than create a new property like othersPublisher.
        didSet {
            if oldValue != others {
                currentSubject.send(current)
            }
        }
    }

    static var all: [DestinationSet] {
        [current] + others
    }

    private static let currentSubject = PassthroughSubject<DestinationSet, Never>()

    static var currentPublisher: AnyPublisher<DestinationSet, Never> {
        Just(current).merge(with: currentSubject).eraseToAnyPublisher()
    }

    static func saveAll() throws {
        try save(all)
    }

    static func loadAll() throws {
        let all = try? load()

        if let all = all, !all.isEmpty {
            current = all[0]
            others = Array(all.dropFirst())
        } else {
            current = DestinationSet()
            others = []
        }
    }

    /// Assigns the destination set in `others` to `current`.
    @discardableResult
    static func select(_ destset: DestinationSet) -> Bool {
        if let index = DestinationSet.others.firstIndex(of: destset) {
            select(at: index)
            return true
        } else {
            return false
        }
    }

    /// Assigns the destination set in `others` at the specified position to `current`.
    static func select(at: Int) {
        let newCurrent = DestinationSet.others[at]
        DestinationSet.others.remove(at: at)
        if !DestinationSet.current.isEmpty {
            DestinationSet.others.insert(DestinationSet.current, at: 0)
        }
        DestinationSet.current = newCurrent
    }
}

// MARK: - Conforming to Hashable

extension DestinationSet: Hashable {
    static func == (lhs: DestinationSet, rhs: DestinationSet) -> Bool {
        lhs === rhs
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(note)
        hasher.combine(destinations)
    }
}
