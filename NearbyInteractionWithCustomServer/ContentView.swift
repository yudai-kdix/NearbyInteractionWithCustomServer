import AVFoundation
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

        Section("診断") {
          self.diagnosticRow(label: "カメラ権限", value: self.cameraAuthorizationText)
          if let hint = self.cameraAuthorizationHint {
            Text(hint)
              .font(.footnote)
              .foregroundStyle(.secondary)
          }

          self.diagnosticRow(label: "自端末の対応", value: self.localCapabilityText)
          if let hint = self.localCapabilityHint {
            Text(hint)
              .font(.footnote)
              .foregroundStyle(.secondary)
          }

          if #available(iOS 17.0, *) {
            self.diagnosticRow(label: "相手端末の対応", value: self.peerCapabilityText)
            if let hint = self.peerCapabilityHint {
              Text(hint)
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
          }

          if let error = self.interactionManager.lastSessionErrorDescription {
            Text("セッションエラー: \(error)")
              .font(.footnote)
              .foregroundStyle(.secondary)
          }

          if let coaching = self.angleSupportHint(self.interactionManager.preciseAngleSupportState) {
            Text(coaching)
              .font(.footnote)
              .foregroundStyle(.secondary)
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
      return "方角の詳細測定: 確認中"
    case .supported:
      return "方角の詳細測定: 利用可能"
    case .unsupported:
      return "方角の詳細測定: 利用不可"
    }
  }
  private func angleSupportHint(_ state: MeasurementSupportState) -> String? {
    switch state {
    case .unknown:
      return "背面同士を向けて 0.3〜1 m の距離でゆっくり動かし、方角が収束するまで待ってください。"
    case .supported:
      return nil
    case .unsupported:
      if self.interactionManager.cameraAuthorizationStatus == .denied
        || self.interactionManager.cameraAuthorizationStatus == .restricted
      {
        return "設定アプリの「プライバシーとセキュリティ > カメラ」で本アプリのカメラ利用を許可してください。"
      }

      if #available(iOS 16.0, *),
        let capability = self.interactionManager.localCapabilities,
        !capability.supportsDirectionMeasurement
      {
        return "この端末はハードウェア仕様上、方角測定に対応していません。対応端末でお試しください。"
      }

      if #available(iOS 17.0, *),
        let peerCapability = self.interactionManager.peerCapabilities,
        !peerCapability.supportsDirectionMeasurement
      {
        return "相手端末が方角測定に対応していない可能性があります。別の端末で確認してください。"
      }

      return "カメラを遮らず、周囲に十分な明るさがある状態で再度計測を開始してください。"
    }
  }
  private func diagnosticRow(label: String, value: String) -> some View {
    HStack {
      Text(label)
      Spacer()
      Text(value)
        .foregroundStyle(.secondary)
    }
  }
  private var cameraAuthorizationText: String {
    switch self.interactionManager.cameraAuthorizationStatus {
    case .authorized:
      return "許可済み"
    case .denied:
      return "拒否"
    case .restricted:
      return "制限中"
    case .notDetermined:
      return "未確認"
    @unknown default:
      return "不明"
    }
  }
  private var cameraAuthorizationHint: String? {
    switch self.interactionManager.cameraAuthorizationStatus {
    case .authorized:
      return nil
    case .notDetermined:
      return "「計測スタート」を押すとカメラ利用の確認ダイアログが表示されます。"
    case .denied, .restricted:
      return "設定アプリからカメラの利用を許可しない限り方角は取得できません。"
    @unknown default:
      return nil
    }
  }
  private var localCapabilityText: String {
    if #available(iOS 16.0, *), let capability = self.interactionManager.localCapabilities {
      if capability.supportsAngleEstimation {
        return "距離・方角に対応"
      }
      if capability.supportsPreciseDistanceMeasurement {
        return "距離のみ対応"
      }
      return "未対応"
    }

    return self.interactionManager.preciseDistanceSupported ? "距離のみ対応" : "未対応"
  }
  private var localCapabilityHint: String? {
    if #available(iOS 16.0, *), let capability = self.interactionManager.localCapabilities,
      !capability.supportsAngleEstimation
    {
      return "ハードウェア仕様により方角測定が提供されません。"
    }
    return nil
  }
  @available(iOS 17.0, *)
  private var peerCapabilityText: String {
    guard let capability = self.interactionManager.peerCapabilities else {
      return "未取得"
    }
    if capability.supportsAngleEstimation {
      return "距離・方角に対応"
    }
    if capability.supportsPreciseDistanceMeasurement {
      return "距離のみ対応"
    }
    return "未対応"
  }
  @available(iOS 17.0, *)
  private var peerCapabilityHint: String? {
    guard let capability = self.interactionManager.peerCapabilities else {
      return "相手端末からトークンを取得後に情報が表示されます。"
    }
    if !capability.supportsAngleEstimation {
      return "相手端末が方角測定に対応していない場合、方角は取得できません。"
    }
    return nil
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
      .environmentObject(InteractionManager())
  }
}
