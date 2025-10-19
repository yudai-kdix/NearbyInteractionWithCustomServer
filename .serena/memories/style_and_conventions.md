# Style and Conventions
- Swift: 2-space indent, types UpperCamelCase, functions/properties lowerCamelCase, prefer early returns, group config constants (e.g., `InteractionManager.apiURL`) as static constants.
- TypeScript: ES2022 modules, 2-space indent per Prettier, provide explicit types for Cloudflare worker `env` argument.
- Testing: Swift `XCTestCase` classes named `<TargetClass>Tests`; server uses Vitest with mocked D1 bindings; test request/response helpers.
- Permissions: Ensure `Info.plist` includes `NSNearbyInteractionUsageDescription` and `NSCameraUsageDescription` when using camera assistance.
