NearbyInteraction 実験メモ（現状報告）

🧪 実験概要
	•	使用リポジトリ: yudai-kdix/NearbyInteractionWithCustomServer
	•	検証目的: iPhone同士で距離と方向を取得
	•	通信構成: 双方を送受信兼任（同時に NISession）
	•	Developer Program: 未登録（デモ実行レベル）
	•	実装: リポジトリを fetch して一部改変（変更内容は自身のリポジトリにコミット済み）

⸻

📱 使用デバイス・結果

デバイス	iOSバージョン	距離	方向 (direction)
iPhone 13 Pro	26（最新）	✅	✅（取得できた）
iPhone 14	26	✅	❌（nil）
iPhone 14 Pro	18	✅	❌（nil）
iPhone 15	26	✅	❌（nil）

※ 全て日本モデル

⸻

⚠️ 現象概要
	•	距離（distance）は全端末で取得可能。
	•	方向（direction）が 13 Pro 以外で nil。
	•	ペアリング・通信は確立しているが、方向のみ欠損。

⸻

🧩 想定される原因と対処方針

1. Camera Assistance 無効
	•	iOS16+では direction 取得に Camera Assistance が必須。
	•	NINearbyPeerConfiguration.isCameraAssistanceEnabled が false だと方向が出ない。
	•	修正：

let config = NINearbyPeerConfiguration(peerToken: token)
config.isCameraAssistanceEnabled = true
session.run(config)



2. カメラ権限の欠如
	•	Info.plist に NSCameraUsageDescription がないと、Camera Assistance 無効化扱い。
	•	修正：

<key>NSCameraUsageDescription</key>
<string>NearbyInteractionでカメラを利用します</string>


	•	設定 → プライバシーとセキュリティ → カメラ でアプリ許可を再確認。

3. ARSession 競合
	•	Camera Assistance 有効時は内部で ARSession が動作。
	•	別途アプリ側で ARKit を動かすと衝突し、方向情報が更新されない。
	•	修正：ARKitを併用する場合、NISession.setARSession(_:) で同一セッションを共有。

4. 見通し条件（ライン・オブ・サイト）
	•	距離のみ取得可能でも、背面アンテナが遮られていると方向は出ない。
	•	初回収束時に背面同士を向けて 0.3〜1 m で動かす必要あり。
	•	遮蔽物（手、机、カバーなど）を排除。

5. システム設定（UWB 有効）
	•	設定 → プライバシーとセキュリティ → 位置情報サービス → システムサービス → ネットワークとワイヤレス を ON。

6. iPhone 15系（U2 チップ）挙動差
	•	一部報告で「距離は出るが方向が nil」ケースあり（U2 チップによる仕様差の可能性）。
	•	現状 Apple のドキュメントでも公式修正なし。上記1〜4を優先的に確認。

⸻

✅ 修正チェックリスト

項目	確認
Info.plist に NSCameraUsageDescription あり	☐
isCameraAssistanceEnabled = true 設定済み	☐
Camera 権限「許可」済み	☐
ARSession 二重起動なし	☐
背面同士の見通しで初回検出成功	☐
「ネットワークとワイヤレス」ON	☐


⸻

🧠 今後の調査予定
	•	上記修正を反映して再ビルド・再テスト。
	•	13 Pro ↔ 14 / 14 ↔ 15 の交差ペアで挙動比較。
	•	direction が出た瞬間のログを追加（didUpdate nearbyObject）。
	•	差分コミットを共有してレビュー（Camera Assistance 周辺）。

