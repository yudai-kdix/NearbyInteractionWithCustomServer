# NearbyInteractionWithCustomServer Overview
- Purpose: Sample iOS app demonstrating Nearby Interaction peer-to-peer distance/direction sharing, backed by a Cloudflare Workers API for discovery token exchange.
- Key Components: SwiftUI client (`ContentView.swift`, `InteractionManager.swift`, `NearbyInteractionWithCustomServerApp.swift`) plus Worker server (`Server/src/index.ts`, `Server/schema.sql`).
- Requirements: Two iPhones (iPhone 11+), iOS 15+. Uses Cloudflare D1 for token storage.
- Structure: iOS app under `NearbyInteractionWithCustomServer/`; Cloudflare Worker under `Server/`; Xcode project file `NearbyInteractionWithCustomServer.xcodeproj` at root.
