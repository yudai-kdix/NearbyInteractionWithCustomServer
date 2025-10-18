# Repository Guidelines

## プロジェクト構成とモジュール
- `NearbyInteractionWithCustomServer/` が SwiftUI クライアント本体で、`ContentView.swift` は UI、`InteractionManager.swift` が Nearby Interaction と Cloudflare API の連携を担当します。
- `Server/` には Cloudflare Workers 実装 (`src/index.ts`) と設定 (`wrangler.toml`, `schema.sql`, `worker-configuration.d.ts`) がまとまっており、D1 データベースを前提としています。
- ルートには `NearbyInteractionWithCustomServer.xcodeproj`, `buildServer.json`, `README.md`, `LICENSE` があり、Xcode でのビルドや配布条件を管理します。

## ビルド・テスト・開発コマンド
- iOS クライアントは `open NearbyInteractionWithCustomServer.xcodeproj` で Xcode を開き、スキーム `NearbyInteractionWithCustomServer` を `Cmd+B` (ビルド) / `Cmd+U` (テスト) で実行します。CI では `xcodebuild -scheme NearbyInteractionWithCustomServer -configuration Debug build` を使用してください。
- サーバー側は初回に `cd Server && npm install` を行い、`npm run dev` でローカル実行、`npm run deploy` で本番デプロイします。型同期は `npm run cf-typegen` を用います。
- D1 の初期化は `wrangler d1 execute <DB_NAME> --file ./schema.sql` を推奨し、`.dev.vars` にシークレットを置いて `wrangler.toml` と整合させます。

## コーディングスタイルと命名
- Swift ファイルは 2 スペースインデント、型は `UpperCamelCase`、プロパティとメソッドは `lowerCamelCase`、定数は先頭に `k` を付けず `let` 名で表現します。
- `InteractionManager` へネットワーク処理を集約し、Combine の `PassthroughSubject` で UI へ流す既存パターンを踏襲してください。非同期処理は `URLSession` の `async/await` 化を優先します。
- TypeScript は既存ファイルに合わせてタブインデントを維持し、`tsconfig.json` の `strict` 設定を崩さないよう `Env` 型へフィールドを追加してから使用します。

## テスト指針
- iOS 側には自動テストが未導入です。距離計算や API ラッパーを変更する場合は `NearbyInteractionWithCustomServerTests` ターゲットを追加し、XCTest で単体テストを用意してからマージしてください。
- サーバー側は `vitest` を使用します。ファイル名は `src/*.test.ts` とし、`npm run test` / `npm run test -- --coverage` を PR 前に実行して成功ログを残します。
- 実機検証として 2 台の iPhone で `wrangler dev --local` に接続し、トークン交換と距離更新が期待通りかを手動確認してください。

## コミットとプルリクエスト
- 現在の履歴は短い日本語・英語メッセージが混在しているため、今後は `feat:`, `fix:`, `chore:` など Conventional Commits を採用し、必要に応じて `[iOS]`, `[Server]` のスコープを付与してください。
- プルリクエスト本文には概要、背景、テスト結果 (`xcodebuild`, `npm run test` など) をチェックリスト形式で記載し、UI 変更時はスクリーンショット、API 変更時はサンプルリクエストとレスポンスを添付します。
- D1 スキーマ変更を含む場合は `schema.sql` と `wrangler.toml` を同時に更新し、移行手順とロールバック方法を PR 説明に追記してください。

## セキュリティと設定の注意
- `InteractionManager.apiURL` はプレースホルダーです。各環境固有の Cloudflare Workers URL に差し替え、公開リポジトリへ認証情報を書き込まないでください。
- ログには位置情報が含まれるため、本番ビルドでは不要な `print` を削除し、必要なものは `os_log` でレベルを分けて扱ってください。
