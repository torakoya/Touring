import SwiftUI

struct DestinationPanel: View {
    @EnvironmentObject private var vm: ContentViewModel

    var targetImageName: String {
        if let targetIndex = vm.mapViewContext.targetIndex, targetIndex < 40 {
            return "\(targetIndex + 1).circle"
        } else {
            return "circle"
        }
    }

    var mapModeImageName: String {
        vm.mapViewContext.originOnly ?
            (vm.mapViewContext.following ? "location.square.fill" : "location.square") :
            (vm.mapViewContext.following ? "mappin.square.fill" : "mappin.square")
    }

    var body: some View {
        HStack {
            Button {
                vm.mapViewContext.goBackward()
            } label: {
                Image(systemName: "chevron.backward.2")
                    .font(.title)
            }
            .disabled(vm.mapViewContext.destinations.count <= 1)
            Image(systemName: targetImageName)
                .font(.title)
            Button {
                vm.mapViewContext.goForward()
            } label: {
                Image(systemName: "chevron.forward.2")
                    .font(.title)
            }
            .disabled(vm.mapViewContext.destinations.count <= 1)
            .padding(.trailing, 10)

            Button {
                if vm.mapViewContext.following {
                    if vm.mapViewContext.destinations.isEmpty {
                        vm.mapViewContext.originOnly = true
                    } else {
                        vm.mapViewContext.originOnly.toggle()
                    }
                } else {
                    vm.mapViewContext.following.toggle()
                }
            } label: {
                Image(systemName: mapModeImageName)
                    .font(.largeTitle)
            }

            if let dist = vm.mapViewContext.targetDistance {
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
