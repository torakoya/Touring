import SwiftUI

struct SpeedPanel: View {
    @EnvironmentObject private var vm: ContentViewModel

    var body: some View {
        HStack {
            HStack(alignment: .lastTextBaseline) {
                Text(vm.speedNumber)
                    .font(.largeTitle.bold())
                    .foregroundColor(vm.isSpeedValid ? .primary : .gray)
                Text(vm.speedUnit)
                    .font(.footnote)
            }

            Image(systemName: vm.compassType == .north ? "location.north.circle" : "arrow.up.circle")
                .font(.largeTitle)
                .rotationEffect(vm.course)
                .foregroundColor(vm.isCourseValid ? .primary : .gray)
                .padding(.trailing)

            VStack(spacing: 0) {
                Text(vm.loggingState == .started ? "Rec" : vm.loggingState == .paused ? "Pause" : "")
                    .font(.caption2.smallCaps().bold())
                    .foregroundColor(vm.loggingState == .paused ? .gray : .red)

                MenuButton()
            }

            if vm.showsRecordButton && vm.loggingState != .started {
                Button(role: .destructive) {
                    vm.location.logger.start()
                } label: {
                    Image(systemName: "record.circle.fill")
                        .font(.title)
                }
                .padding(.leading)
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
