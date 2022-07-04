import CoreLocation
import SwiftUI

struct DestinationPanel: View {
    @EnvironmentObject private var vm: ContentViewModel
    @EnvironmentObject private var map: MapViewContext

    var targetImageName: String {
        if let targetIndex = DestinationSet.current.targetIndex, targetIndex < 50 {
            return "\(targetIndex + 1).circle"
        } else {
            return "circle"
        }
    }

    var mapModeImageName: String {
        map.originOnly ?
            (map.following ? "location.square.fill" : "location.square") :
            (map.following ? "mappin.square.fill" : "mappin.square")
    }

    var targetDistance: CLLocationDistance? {
        if let user = vm.location.last,
            let target = DestinationSet.current.target {
            let dest = CLLocation(
                latitude: target.coordinate.latitude,
                longitude: target.coordinate.longitude)
            return MeasureUtil.distance(from: user, to: dest)
        }
        return nil
    }

    var body: some View {
        HStack {
            Button {
                DestinationSet.current.goBackward()
            } label: {
                Image(systemName: "chevron.backward.2")
                    .font(.largeTitle)
                    .padding(15) // Expand the hittable area.
            }
            .padding(-15) // Shrink to the original size.
            .disabled(DestinationSet.current.destinations.count <= 1)
            Image(systemName: targetImageName)
                .font(.title)
                .foregroundColor(DestinationSet.current.destinations.isEmpty ? .gray : .primary)
            Button {
                DestinationSet.current.goForward()
            } label: {
                Image(systemName: "chevron.forward.2")
                    .font(.largeTitle)
                    .padding(15)
            }
            .padding(-15)
            .disabled(DestinationSet.current.destinations.count <= 1)
            .padding(.trailing, 10)

            Button {
                if map.following {
                    if DestinationSet.current.destinations.isEmpty {
                        map.originOnly = true
                    } else {
                        map.originOnly.toggle()
                    }
                } else {
                    map.following.toggle()
                }
            } label: {
                Image(systemName: mapModeImageName)
                    .font(.largeTitle)
                    .padding(15)
            }
            .padding(-15)

            if let dist = targetDistance {
                let diststr = MeasureUtil.distanceString(meters: dist, prefersMile: vm.prefersMile)
                Text(diststr[0]).bold() + Text(diststr[1]).font(.footnote)
            }
        }
        .panel()
    }
}

struct DestinationPanel_Previews: PreviewProvider {
    static var previews: some View {
        DestinationPanel()
            .environmentObject(ContentViewModel())
    }
}
