# Suggested Commands
- Open iOS project in Xcode: `open NearbyInteractionWithCustomServer.xcodeproj`
- Run iOS tests (simulator): `xcodebuild test -scheme NearbyInteractionWithCustomServer -destination 'platform=iOS Simulator,name=iPhone 15'`
- Install server deps: `cd Server && npm install`
- Run Cloudflare Worker dev: `cd Server && npm run dev`
- Deploy Worker: `cd Server && npm run deploy`
- Run server tests: `cd Server && npm test`
