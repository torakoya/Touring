import SwiftUI

struct DestinationPanel: View {
    @EnvironmentObject private var vm: ContentViewModel
    @EnvironmentObject private var map: MapViewContext

    var targetImageName: String {
        if let targetIndex = DestinationSet.current.targetIndex, targetIndex < 40 {
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

    var body: some View {
        HStack {
            Button {
                DestinationSet.current.goBackward()
            } label: {
                Image(systemName: "chevron.backward.2")
                    .font(.title)
            }
            .disabled(DestinationSet.current.destinations.count <= 1)
            Image(systemName: targetImageName)
                .font(.title)
            Button {
                DestinationSet.current.goForward()
            } label: {
                Image(systemName: "chevron.forward.2")
                    .font(.title)
            }
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
            }

            if let dist = map.targetDistance {
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
