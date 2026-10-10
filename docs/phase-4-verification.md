# Phase 4 — プレイヤーHP・被ダメージ・GAME OVER

2026-10-02。ユーザーの「動作確認OK」でPhase 4完了。Phase 5の実装へ進む。以下はPhase 4実装時点の検証記録。
正本: [Game 002](https://app.notion.com/p/3ec32305966281aab50fe218f60b533b)。

## 実装

- プレイヤーHP100。HUDに数値とバーを表示し、被弾時・死亡時に更新する。
- 足元のArea2D（半径16px）で敵の足元ボディを検出。接触ダメージ10。地形・投剣ではダメージを受けない。
- 被弾後は1秒の無敵時間。同じ敵に触れ続ける場合も、無敵時間後に再度ダメージを受ける。複数の敵の同時接触でも1回分に制限し、死亡・削除予定の敵からは被弾しない。
- 被弾直後の赤色変化、無敵時間中の明暗変化とINVULNERABLE表示を追加。既存の遮蔽物による半透明と独立させる。
- HP0で死亡を1回通知、速度を0にし、GAME OVERを表示してSceneTreeをpauseする。移動、投剣、既存の剣、敵追跡、出現タイマー、マップ表示の更新を停止。直接の投剣・スポーン・ダメージ関数にも停止中のガードを追加。
- HUDだけはAlwaysで入力を受け付け、GAME OVER後のRでシーンを読み直す。HP、無敵時間、撃破数、敵、投剣を初期化。通常プレイ中のRは何もしない。
- 調整値はPlayerのMax Hp／Invulnerability Duration、EnemyのContact Damageから変更可能。接触範囲を含め、正式バランスではない。

## 変更ファイル

- 新規: scripts/game_over_ui.gd、tests/phase_4_verify.gd。
- 更新: scripts/player.gd、scripts/enemy.gd、scripts/sword_thrower.gd、scripts/thrown_sword.gd、scripts/enemy_spawner.gd、scripts/main.gd、scenes/player.tscn、scenes/main.tscn、project.godot、README.md、docs/phase-3-verification.md。
- 記録: 本文書、phase-4-health-preview.png、phase-4-game-over-preview.png、phase-4-test-output.log、phase-4-test-errors.log、phase-4-startup-output.log、phase-4-startup-errors.log。

## 検証結果

Godot 4.7.2 stable、Windows、Compatibility／OpenGL 3.3、GeForce GTX 1050 Ti。

- Phase 4統合テストはheadless・通常描画ともPASS、0 failures、終了コード0。最終通常描画の標準エラーログは空。
- HPとHUDの初期値、実際の敵追跡からの被弾、接触を離れた後の被弾停止、複数敵の同時接触、1秒の無敵、接触持続時の再被弾、死亡敵の除外を確認。
- 実際の接触でHP0にし、GAME OVER・HP0表示・SceneTree停止を確認。停止中に移動・攻撃入力を入れ、プレイヤー、敵、飛行中の剣、出現数・タイマーが変わらないことを確認。
- 停止中の直接攻撃・スポーン要求を拒否し、敵HPが変わらず死亡通知も1回であることを確認。
- Rの入力で実際にシーンを再読込し、HP100、無敵0、撃破0、初期敵4体、古い剣なし、移動再開を確認。通常プレイ中のRでは再起動しない。
- Phase 1、2、3の既存統合テストは各PASS、0 failures、終了コード0。
- 通常描画のHP／無敵表示とGAME OVER画面をPNGへ保存して視覚確認。F5で使用するMainシーンを通常描画で120フレーム起動し、Outputエラーなし。
- git diffの空白チェック成功。

## 実機確認手順・未確認事項

READMEのRun／Verifyを参照。F5後に敵へ近づき、HP減少と1秒の保護を確認。接触を継続してHP0にし、画面とゲーム全体が止まることを確認。Rで最初から再開できることとOutput／Debuggerを確認する。

被弾判定の広さ、ダメージ量・無敵時間の手触り、見た目、長時間プレイ、ユーザーのF5→死亡→R再開セッションは実機確認待ち。AUTO初期設定／MOUSE切替を維持。横歩きの違和感は後日調整のまま。

Phase 5のEXP・レベルアップ・能力選択は未実装。ユーザー確認前に次Phaseへ進まない。
