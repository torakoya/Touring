import SwiftUI

struct SpeedPanel: View {
    @EnvironmentObject private var vm: ContentViewModel

    var body: some View {
        HStack {
            HStack(alignment: .lastTextBaseline) {
                Text(vm.speedNumber)
                    .font(.largeTitle.bold())
                    .foregroundColor(vm.isSpeedValid ? Color(uiColor: .label) : .gray)
                Text(vm.speedUnit)
                    .font(.footnote)
            }

            Image(systemName: vm.compassType == .north ? "location.north.circle" : "arrow.up.circle")
                .font(.largeTitle)
                .rotationEffect(vm.course)
                .foregroundColor(vm.isCourseValid ? Color(uiColor: .label) : .gray)
                .padding(.trailing)

            VStack(spacing: 0) {
                Text(vm.loggingState == .started ? "Rec" : vm.loggingState == .paused ? "Pause" : "")
                    .font(.caption2.smallCaps().bold())
                    .foregroundColor(vm.loggingState == .paused ? .gray : .red)

                MenuButton()
            }
        }
        .panel()
    }
}

struct SpeedPanel_Previews: PreviewProvider {
    static var previews: some View {
        SpeedPanel()
            .environmentObject(ContentViewModel())
    }
}
