import SwiftUI

struct ContentView: View {
  @EnvironmentObject var interactionManager: InteractionManager

  @State var textFieldValue = ""
  @State var distance: Float = 0.0
  @State var azimuth: Float = 0.0
  @State var elevation: Float = 0.0

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
      Text(
        self.interactionManager.preciseDistanceSupported
          ? "Precise distance measurement: Supported"
          : "Precise distance measurement: Not supported"
      )
      .font(.footnote)
      .padding(.top)
      Text(self.angleSupportMessage(self.interactionManager.preciseAngleSupportState))
        .font(.footnote)
        .padding(.top, 2)
      if let hint = self.angleSupportHint(self.interactionManager.preciseAngleSupportState) {
        Text(hint)
          .font(.caption)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal)
      }
      Text(String(format: "Distance: %.1f", self.distance))
        .padding(.top)
      Text(String(format: "Azimuth: %.1f°", self.azimuth * 180 / .pi))
        .padding(.top, 4)
      Text(String(format: "Elevation: %.1f°", self.elevation * 180 / .pi))
        .padding(.top, 4)
    }
    .onReceive(self.interactionManager.distance) { distanceValue in
      let before = String(format: "%.1f", self.distance)
      let after = String(format: "%.1f", distanceValue)

      if before != after {
        UIAccessibility.post(notification: .announcement, argument: after)
      }

      self.distance = distanceValue
    }
    .onReceive(self.interactionManager.direction) { direction in
      self.azimuth = direction.azimuth
      self.elevation = direction.elevation
    }
  }
  func hideKeyboard() {
    Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { timer in
      UIApplication.shared.sendAction(
        #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
  }
  private func angleSupportMessage(_ state: MeasurementSupportState) -> String {
    switch state {
    case .unknown:
      return "Precise angle measurement: Checking..."
    case .supported:
      return "Precise angle measurement: Supported"
    case .unsupported:
      return "Precise angle measurement: Not supported"
    }
  }
  private func angleSupportHint(_ state: MeasurementSupportState) -> String? {
    switch state {
    case .unknown:
      return "To initialize direction, point the backs of both iPhones toward each other and move them slowly."
    case .supported:
      return nil
    case .unsupported:
      return "If direction stays unavailable, check Nearby Interaction and Camera permissions in Settings."
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
