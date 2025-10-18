import SwiftUI

struct ContentView: View {
  @EnvironmentObject var interactionManager: InteractionManager

  @State private var peerCode = ""
  @State private var distance: Float = 0.0
  @State private var azimuth: Float = 0.0
  @State private var elevation: Float = 0.0
  @FocusState private var isPeerCodeFocused: Bool

  var body: some View {
    NavigationView {
      Form {
        Section("1. 自分のコード") {
          Text(self.myCodeText)
            .font(.title3)
            .monospacedDigit()
            .padding(.vertical, 4)

          Button(self.interactionManager.myTokenId == 0 ? "コードを取得" : "コードを更新") {
            self.interactionManager.getMyToken()
          }

          Text("表示された 4 桁の数字を相手に伝えましょう。")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }

        Section("2. 相手のコードを入力") {
          TextField("0000", text: $peerCode)
            .keyboardType(.numberPad)
            .focused($isPeerCodeFocused)

          Button("コードを読み込む") {
            self.fetchPeerToken()
          }
          .disabled(!self.isPeerCodeValid)

          Text("相手から共有された 4 桁のコードを入力してボタンを押します。")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }

        Section("3. 計測を開始") {
          Button("計測スタート") {
            self.interactionManager.run()
          }

          Text("両方の端末で 1 と 2 の手順を完了させてから開始してください。")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }

        Section("測定値") {
          Text("距離: \(self.distanceText)")
            .monospacedDigit()

          Text(
            self.interactionManager.preciseDistanceSupported
              ? "距離の詳細測定: 対応"
              : "距離の詳細測定: 非対応"
          )
          .font(.footnote)

          Text(self.angleSupportMessage(self.interactionManager.preciseAngleSupportState))
            .font(.footnote)

          if self.interactionManager.preciseAngleSupportState == .supported {
            Text("方位: \(self.azimuthText) / 仰角: \(self.elevationText)")
              .font(.footnote)
              .monospacedDigit()
          }
        }
      }
      .navigationTitle("Nearby Interaction")
      .toolbar {
        ToolbarItemGroup(placement: .keyboard) {
          Spacer()
          Button("完了") {
            self.isPeerCodeFocused = false
          }
        }
      }
    }
    .navigationViewStyle(StackNavigationViewStyle())
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
  private var myCodeText: String {
    guard self.interactionManager.myTokenId != 0 else {
      return "コード未取得"
    }

    return String(format: "コード: %04d", self.interactionManager.myTokenId)
  }
  private var distanceText: String {
    String(format: "%.1f m", self.distance)
  }
  private var azimuthText: String {
    String(format: "%.1f°", self.azimuth * 180 / .pi)
  }
  private var elevationText: String {
    String(format: "%.1f°", self.elevation * 180 / .pi)
  }
  private var isPeerCodeValid: Bool {
    self.peerCode.count == 4 && Int(self.peerCode) != nil
  }
  private func fetchPeerToken() {
    guard let id = Int(self.peerCode) else {
      return
    }
    self.hideKeyboard()
    self.interactionManager.getPeerToken(id: id)
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
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
      .environmentObject(InteractionManager())
  }
}
