import SwiftUI

struct ContentView: View {
    var body: some View {
        NMEAViewControllerRepresentable()
            .ignoresSafeArea()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
