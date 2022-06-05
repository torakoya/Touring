import SwiftUI

struct RouteButton: View {
    @EnvironmentObject var vm: ContentViewModel
    @EnvironmentObject var map: MapViewContext

    var isRouteButtonDisabled: Bool {
        map.mapView?.userLocation.location == nil || DestinationSet.current.target == nil
    }

    var isRouteButtonExpanded: Bool {
        map.showingRoutes &&
        (routeDistanceString != nil || routeTimeString != nil)
    }

    var routeDistanceString: [String]? {
        if map.showingRoutes, let routes = map.routes {
            return MeasureUtil.distanceString(meters: routes.distance, prefersMile: vm.prefersMile)
        } else {
            return nil
        }
    }

    var routeTimeString: [String]? {
        if map.showingRoutes, let routes = map.routes {
            return [String(Int(routes.time / 60 / 60)), String(Int(routes.time / 60) % 60)]
        } else {
            return nil
        }
    }

    var body: some View {
        HStack {
            Button {
                map.showingRoutes.toggle()
            } label: {
                Image(systemName: map.showingRoutes ? "eye" : "eye.slash")
                    .font(.largeTitle)
                    .padding(isRouteButtonExpanded ? [.top, .bottom, .leading] : .all)
            }
            .disabled(isRouteButtonDisabled)

            if isRouteButtonExpanded {
                VStack(alignment: .leading) {
                    if let dist = routeDistanceString {
                        Text(dist[0]).bold() + Text(dist[1]).font(.footnote)
                    } else {
                        Text("")
                    }
                    if let time = routeTimeString {
                        Text(time[0]).bold() + Text("h ").font(.footnote) +
                        Text(time[1]).bold() + Text("m").font(.footnote)
                    } else {
                        Text("")
                    }
                }
                .padding(.trailing)
            }
        }
    }
}

struct RouteButton_Previews: PreviewProvider {
    static var previews: some View {
        RouteButton()
    }
}
