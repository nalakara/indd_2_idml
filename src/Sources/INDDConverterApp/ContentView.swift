import SwiftUI

struct ContentView: View {
    @StateObject private var state = AppState()

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(state: state)

            Divider()

            if state.items.isEmpty {
                DropZoneView(state: state)
            } else {
                QueueListView(state: state)
            }
        }
        .frame(minWidth: 580, minHeight: 480)
        .sheet(isPresented: $state.showSearchSheet) {
            FileSearchView(state: state)
        }
    }
}
