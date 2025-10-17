import Combine
import Foundation
import NearbyInteraction
import simd

enum MeasurementSupportState {
  case unknown
  case supported
  case unsupported
}

struct HTTPResponseBody: Decodable {
  let id: Int
  let token: String
  let success: Bool
}

class InteractionManager: NSObject, ObservableObject {
  // Please replace this URL with your Cloudflare Workers URL.
  static let apiURL = "https://interaction.yuuudaiiiiii.workers.dev"

  var distance: AnyPublisher<Float, Never> {
    self.distanceSubject.eraseToAnyPublisher()
  }

  var direction: AnyPublisher<(azimuth: Float, elevation: Float), Never> {
    self.directionSubject.eraseToAnyPublisher()
  }

  private let distanceSubject = PassthroughSubject<Float, Never>()
  private let directionSubject = PassthroughSubject<(azimuth: Float, elevation: Float), Never>()

  @Published var myTokenId: Int = 0
  @Published var preciseDistanceSupported: Bool = false
  @Published var preciseAngleSupportState: MeasurementSupportState = .unknown

  private var session: NISession? = nil
  private var peerToken: NIDiscoveryToken? = nil
  private var directionlessUpdateCount = 0

  override init() {
    super.init()
    self.prepare()
  }
  func prepare() {
    if #available(iOS 16.0, watchOS 9.0, *) {
      let capabilities = NISession.deviceCapabilities
      self.preciseDistanceSupported = capabilities.supportsPreciseDistanceMeasurement
      self.preciseAngleSupportState = self.preciseDistanceSupported ? .unknown : .unsupported
    } else {
      self.preciseDistanceSupported = NISession.isSupported
      self.preciseAngleSupportState = .unsupported
    }

    guard self.preciseDistanceSupported else {
      return
    }

    self.session = NISession()
    session?.delegate = self
    self.directionlessUpdateCount = 0
  }
  func getMyToken() {
    guard let session = self.session else {
      return
    }
    guard let myToken = session.discoveryToken else {
      return
    }
    guard
      let myTokenData = try? NSKeyedArchiver.archivedData(
        withRootObject: myToken, requiringSecureCoding: true)
    else {
      return
    }

    let endpoint = URL(string: InteractionManager.apiURL)!
    let requestBody: [String: String] = [
      "token": myTokenData.base64EncodedString()
    ]

    var request = URLRequest(url: endpoint)

    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    do {
      request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
    } catch {
      print("Failed to set httpBody: \(error)")
      return
    }

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
      if let error = error {
        print("Failed to send HTTP GET request: \(error)")
        return
      }
      if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
        print("Unexpected HTTP status code")
        return
      }
      guard let data = data else {
        print("Response body is empty")
        return
      }
      do {
        let responseBody = try JSONDecoder().decode(HTTPResponseBody.self, from: data)

        if !responseBody.success {
          print("Failed to call API")
          return
        }
        DispatchQueue.main.async {
          self.myTokenId = responseBody.id
        }
      } catch {
        print("Failed to parse response body: \(error)")
      }
    }

    task.resume()
  }
  func getPeerToken(id: Int) {
    let endpoint = URL(string: "\(InteractionManager.apiURL)/\(id)")!

    var request = URLRequest(url: endpoint)

    request.httpMethod = "GET"

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
      if let error = error {
        print("Failed to send HTTP POST request: \(error)")
        return
      }
      if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
        print("Unexpected HTTP status code")
        return
      }
      guard let data = data else {
        print("Response body is empty")
        return
      }
      do {
        let responseBody = try JSONDecoder().decode(HTTPResponseBody.self, from: data)

        if !responseBody.success {
          print("Failed to call API")
          return
        }

        guard let peerTokenData = Data(base64Encoded: responseBody.token) else {
          print("Failed to decode response body")
          return
        }

        let peerToken = try NSKeyedUnarchiver.unarchivedObject(
          ofClass: NIDiscoveryToken.self, from: peerTokenData)

        self.peerToken = peerToken
      } catch {
        print("Failed to set peer token: \(error)")
      }
    }

    task.resume()
  }
  func run() {
    guard let peerToken = self.peerToken else {
      return
    }

    self.directionlessUpdateCount = 0
    if self.preciseDistanceSupported {
      self.preciseAngleSupportState = .unknown
    }

    let configuration = NINearbyPeerConfiguration(peerToken: peerToken)

    if #available(iOS 16.0, *) {
      configuration.isDirectionalMeasurementEnabled = true
    }

    guard let session = self.session else {
      return
    }

    session.run(configuration)
  }
  func invalidate() {
    guard let session = self.session else {
      return
    }

    session.invalidate()
  }
}

extension InteractionManager: NISessionDelegate {
  func sessionDidStartRunning(_ session: NISession) {
    print("The session starts or resumes running")
  }
  func session(_ session: NISession, didUpdate: [NINearbyObject]) {
    print("The session updates nearby objects")
    for update in didUpdate {
      if let distance = update.distance {
        DispatchQueue.main.async {
          self.distanceSubject.send(distance)
        }
      }
      if let direction = update.direction {
        let length = simd_length(direction)
        if length > 0 {
          let azimuth = atan2(direction.x, -direction.z)
          let normalizedY = max(-1, min(1, direction.y / length))
          let elevation = asin(normalizedY)
          DispatchQueue.main.async {
            self.preciseAngleSupportState = .supported
            self.directionlessUpdateCount = 0
            self.directionSubject.send((azimuth, elevation))
          }
        }
      } else {
        self.directionlessUpdateCount += 1
        if self.preciseAngleSupportState == .unknown && self.directionlessUpdateCount > 10 {
          DispatchQueue.main.async {
            if self.preciseAngleSupportState == .unknown {
              self.preciseAngleSupportState = .unsupported
            }
          }
        }
      }
    }
  }
  func session(
    _ session: NISession, didRemove: [NINearbyObject], reason: NINearbyObject.RemovalReason
  ) {
    print("The session removes one or more nearby objects")
  }
  func sessionWasSuspended(_ session: NISession) {
    print("Suspended session")
  }
  func sessionSuspensionEnded(_ session: NISession) {
    print("The end of a session’s suspension")
  }
  func session(_ session: NISession, didInvalidateWith: Error) {
    print("Invalidated session")
  }
}
