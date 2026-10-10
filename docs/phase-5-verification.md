# Phase 5 — EXP・レベルアップ・能力選択

2026-10-02。Phase 4はユーザーの「動作確認OK」で完了。Phase 5はユーザーの「動作確認OK」で完了。Phase 6の実装へ進む。以下はPhase 5実装時点の検証記録。
正本: [Game 002](https://app.notion.com/p/3ec32305966281aab50fe218f60b533b)。

## 実装と仮の調整値

- 雑兵撃破で10 EXP。非致死ダメージ、重複した死亡処理、遠距離退場はEXPを与えない。
- Level 1 / EXP 0開始。最初の必要EXP30、以後レベルごとに10増加。必要EXPを消費し、余剰は次へ繰り越す。HUDにLevel、EXP数値、ゲージを表示。
- 閾値に到達した撃破の通知中にSceneTreeを一時停止。移動、敵、既存投剣、攻撃・出現タイマー、無敵時間を停止。HUDのみAlwaysで操作を受け付ける。[Godotのpause仕様](https://docs.godotengine.org/en/stable/tutorials/scripting/pausing_games.html)に沿う。
- 3択は固定のPOWER（攻撃力+5）、QUICK THROW（攻撃間隔×0.85）、SWIFT FEET（移動速度+10px/s）。ボタンに現在値と変更後を表示。クリックまたは数字1/2/3で1つ選択。強化を即時適用し、攻撃間隔変更は残りクールダウンにも反映する。移動速度が変わっても斜め入力を正規化。
- 同じ能力を繰り返し選択可能。レアリティ・取得上限は設けない。候補種類・EXP値・強化量はプロトタイプの仮選定であり、正式なバランス決定ではない。投剣数・貫通等は今回の候補に含めない。
- 一度に複数レベル上がる場合は選択回数を保持。対応するLevelと残り回数を表示して順番に処理し、最後の選択が終わってから再開。
- Space保持で選択されないようボタンのキーボードフォーカスを無効化。キーリピート・同一選択の多重処理を防止。RはGAME OVER時のみ有効。
- GAME OVERを優先して選択画面を閉じ、死亡後のEXP・選択は受け付けない。R再開でEXP、Level、未選択回数、攻撃力・間隔・移動速度をすべて初期化。
- Phase 6の目的アイテム・ラウンド終了EXP・クリア処理は実装していない。

## 変更ファイル

- 新規: `scripts/level_progression.gd`、`scripts/level_up_ui.gd`、`tests/phase_5_verify.gd`、対応するGodot生成の`.gd.uid`、本記録、確認画像・ログ。
- 更新: `scripts/main.gd`、`scripts/player.gd`、`scripts/enemy.gd`、`scripts/enemy_spawner.gd`、`scenes/main.tscn`、`README.md`、`docs/phase-4-verification.md`。

## 検証結果

Godot 4.7.2 stable / Windows / Compatibility OpenGL 3.3 / GeForce GTX 1050 Ti。

- headless・通常描画のPhase 5統合検証: `PHASE_5_VERIFY: PASS (0 failures)`、終了コード0。
- 実投剣による非致死命中・撃破・閾値到達、撃破ごとのEXPと重複防止、Level・数値・ゲージの更新、即時停止、停止中の移動・敵・剣・攻撃・出現・無敵タイマー、ダメージ拒否を確認。
- 数字キーと実ButtonへのGUIマウス入力、現在／変更後数値、強化された剣の実ダメージ値、攻撃間隔・移動速度の適用、最後の選択後の再開を確認。
- Level 2 / EXP0から125 EXPを1回加算し、40+50を消費してLevel 4 / EXP35・2回選択になることを確認。両選択の間に再開しない。同じ攻撃力強化を再取得し、速度110の斜め移動も確認。
- 遠距離退場のEXPなし、選択中Rで再開しないこと、死亡後のEXP／選択拒否、実際のRシーン再読込によるすべての成長値の初期化を確認。
- Phase 1〜4回帰検証: 全PASS、0 failures。ログは `phase-5-regression-1.log`〜`phase-5-regression-4.log`。
- `phase-5-upgrade-preview.png`、`phase-5-exp-preview.png`を視覚確認。3択と数値の文字切れなし。F5相当のMain通常描画120フレーム起動成功。最終通常描画・起動の標準エラーログは空。
- 初回マウス検証の入力座標にウィンドウ拡大率が混ざったため、既にゲーム画面座標であるイベントをViewportへ送る形にテストを修正。最終headless・通常描画とも実GUIクリック成功。

## 手動確認・未確認事項

F5で開始し、3体撃破して最初のレベルアップを確認。停止中に敵・剣が動かないことを見て、クリック／1・2・3の両方で選択。次のレベルでも同じ強化を選択し、威力・連射・移動速度の変化を比較。GAME OVER→RでLevel1・EXP0と基本能力へ戻ること、Output／Debuggerにエラーがないことを確認。

未確認: ユーザー実機での成長のテンポ、3択の見やすさ、強化量・必要EXPのバランス、長時間プレイ。横歩きの違和感はユーザー指示どおり後日調整のまま。Phase 5の実機確認を待ち、Phase 6には進まない。
