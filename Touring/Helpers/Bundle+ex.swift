import Foundation

extension Bundle {
    var name: String? {
        object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String
    }

    var version: String? {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }

    var build: String? {
        object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String
    }

    var fullVersion: String? {
        var ver = ""
        if let version = version {
            ver = version
        }
        if let build = build {
            if ver.isEmpty {
                ver = build
            } else {
                ver += " (\(build))"
            }
        }
        return ver.isEmpty ? nil : ver
    }
}
