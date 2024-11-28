import SwiftUI

struct ContentView: View {
  @EnvironmentObject var interactionManager: InteractionManager

  @State var textFieldValue = ""
  @State var distance: Float = 0.0

  var body: some View {
    VStack {
      Text(
        self.interactionManager.myTokenId == 0
          ? "Please get your code"
          : String(format: "Your code: %04d", self.interactionManager.myTokenId)
      )
      .font(.title)
      .padding()
      Button(action: {
        self.interactionManager.getMyToken()
      }) {
        Text(
          self.interactionManager.myTokenId == 0
            ? "Get my code"
            : "Refresh my code"
        )
        .padding()
      }
      Text("Peer code")
        .font(.title)
        .padding()
      TextField("Please set the peer code", text: $textFieldValue)
        .keyboardType(.numberPad)
        .onChange(of: textFieldValue) { newValue in
          self.textFieldValue = newValue

          guard let id = Int(newValue) else {
            return
          }
          if newValue.count >= 4 {
            self.hideKeyboard()
            self.interactionManager.getPeerToken(id: id)
          }
        }
        .padding()
      Button(action: {
        self.interactionManager.run()
      }) {
        Text("Start")
          .padding()
      }
      Text(String(format: "Distance: %.1f", self.distance))
        .padding()
    }
    .onReceive(self.interactionManager.distance) { distanceValue in
      let before = String(format: "%.1f", self.distance)
      let after = String(format: "%.1f", distanceValue)

      if before != after {
        UIAccessibility.post(notification: .announcement, argument: after)
      }

      self.distance = distanceValue
    }
  }
  func hideKeyboard() {
    Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { timer in
      UIApplication.shared.sendAction(
        #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
