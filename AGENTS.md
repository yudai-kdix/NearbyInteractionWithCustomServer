# Repository Guidelines

## プロジェクト構成とモジュール構成
iOSクライアントは`NearbyInteractionWithCustomServer`にまとまり、`ContentView.swift`と`InteractionManager.swift`がUIとNearby Interactionの主要ロジックを担当します。UIリソースは`Assets.xcassets`と`Preview Content`で管理し、`NearbyInteractionWithCustomServerApp.swift`がアプリエントリです。Cloudflare Workersで動作するトークン交換APIは`Server`配下にあり、`src/index.ts`がエンドポイント、`schema.sql`がD1テーブル定義です。

## ビルド・テスト・開発コマンド
iOS側は`open NearbyInteractionWithCustomServer.xcodeproj`でXcodeを開き、`Cmd+R`で実機またはシミュレータにビルドします。CIや自動化には`xcodebuild test -scheme NearbyInteractionWithCustomServer -destination 'platform=iOS Simulator,name=iPhone 15'`を推奨します。サーバーは初回に`cd Server && npm install`を実行し、ローカル開発は`npm run dev`、本番デプロイは`npm run deploy`を使用します。

## コーディングスタイルと命名規約
Swiftコードは2スペースインデントを維持し、型はUpperCamelCase、プロパティやメソッドはlowerCamelCaseで統一してください。早期returnを活用し、`InteractionManager.apiURL`など設定値は静的定数としてまとめます。TypeScript側はES2022モジュール構文とPrettier準拠の2スペースインデントを守り、Cloudflare特有の`env`引数は明示的な型注釈を付けてください。

## テストガイドライン
サーバーは`npm test`でVitestが走る想定です。HTTPハンドラはリクエストとレスポンスのシリアライズを切り出した関数単位でテストし、モックしたD1バインディングを使用します。iOS側はUIテストよりも`XCTestCase`によるNearby Interactionフローのモック検証に重点を置き、テストクラスは`<対象クラス名>Tests`という命名に統一してください。

## コミットとプルリクエストガイドライン
`git log`に倣い、コミットメッセージは英語の命令形で短くまとめます（例: `Add server implementation`）。プルリクエストでは概要、主な変更点、テスト結果、関連Issueを明記し、UIが変わる場合はスクリーンショットを添付してください。サーバーURLや秘密情報を差し込む変更はレビュアーが再現できるよう`.env`や`wrangler.toml`の設定手順を説明します。

## セキュリティと構成のヒント
`InteractionManager.apiURL`は公開WorkerのURLに更新し、テスト用と本番用でブランチを分ける運用を推奨します。Cloudflare D1のスキーマ変更時は`schema.sql`を更新し、マイグレーション段階をPR本文に記録してください。実機テスト時はiOSのNearby Interaction権限文言（`Info.plist`の`NSNearbyInteractionUsageDescription`）が最新か確認します。
