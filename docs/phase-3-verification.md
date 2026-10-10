# Phase 3 — 投剣戦闘

2026-10-02。Phase 3完了（ユーザー「動作OK」の実機確認済み）。AUTO初期設定とMOUSE切替を維持。以下は当時の実装・検証記録。現在Phaseはphase-4-verification.mdを参照。
正本: [Game 002](https://app.notion.com/p/3ec32305966281aab50fe218f60b533b)。Phase 2はユーザーの次Phaseへの移行指示により確認済みとした。

## 実装と操作

- Space／左クリックで投剣。押し続けると0.4秒間隔で連投し、離すと止まる。
- TabでAUTO／MOUSEを切り替える。AUTOは射程内で地形に遮られない最寄りの敵へ照準。敵がいなければ最後の移動方向へ投げる。MOUSEはカーソル方向へ投げ、方向マーカーを表示する。カメラ移動中も画面のマウス座標をマップ座標に投影し直す。
- 銀色の刃・鍔・柄を持つ仮ドット剣は直進する。追尾・戻り・貫通はなく、命中・地形衝突・射程端で消える。
- 投剣はmove_and_collideによる掃引で移動し、高速時のすり抜けを防ぐ。地形と敵を検出し、プレイヤーには衝突しない。
- 敵HP20、剣ダメージ10。命中時に短い色変化とHPバー、HP0で消滅。撃破数をHUDへ表示する。敵の出現を継続する。
- Player/SwordThrowerのexport値で速度320px/秒、間隔0.4秒、射程400px、ダメージ10を調整可能。敵Max Hpも調整可能。数値は試遊用の仮値。
- 屋根・木・鳥居などの半透明表示を維持し、投剣も遮蔽物の範囲では薄く表示する。

## 変更ファイル

- 新規: scenes/thrown_sword.tscn、scripts/thrown_sword.gd、scripts/sword_thrower.gd、tests/phase_3_verify.gd。
- 更新: project.godot、scenes/player.tscn、scenes/main.tscn、scripts/main.gd、scripts/enemy.gd、scripts/enemy_spawner.gd、README.md、docs/phase-2-verification.md。
- 記録: 本文書、phase-3-preview.png、phase-3-test-output.log、phase-3-test-errors.log、phase-3-startup-output.log、phase-3-startup-errors.log。エンジン生成の.gd.uidも保持する。

## 検証結果

Godot 4.7.2 stable、Windows、Compatibility／OpenGL 3.3、GeForce GTX 1050 Ti。

- Phase 3の投剣・入力・照準検証はheadlessでPASS。撃破カウンター・スポーン復帰を加えた最終通常描画検証は全項目PASS、0 failures、終了コード0。標準エラーログは空。
- 実際の物理シーンで最寄りの敵への自動照準、壁越しの敵の除外、マウス座標による手動照準、地形停止、命中で1回だけHP減少、2発で撃破、死亡後の照準対象除外を確認。
- 高速検証値12000px/秒でも敵に命中。空振りは射程到達で消える。
- Space保持で規定間隔の連投、解除で停止、Tab切替、左クリックでの投剣を入力イベントから確認。
- 撃破信号がHUDへ1回だけ反映され、出現枠が解放され、その後も敵が追加出現することを確認。
- 初期の手動照準テストでマウス座標取得の問題を発見し、画面入力座標を保持・毎フレームマップ座標へ投影する形に修正。最終テスト成功。
- Phase 1・2の既存統合テストは各PASS、0 failures、終了コード0。
- 投剣、敵のHPバー、HUDを保存PNGで視覚確認。F5と同じMainシーンを通常描画で120フレーム起動し、Outputエラーなし。
- git diffの空白チェック成功。

## ユーザー実機確認

F5で起動し、敵から距離を取りつつSpace／左クリックで投げる。TabでAUTO／MOUSEを比較し、岩・木の周りや橋の近くでも照準と命中を確認する。命中時のHP減少、撃破数と継続出現、Output／Debuggerを確認する。

自動／手動照準の正式採用は試遊後に決める。戦闘の手触り、投剣の見やすさ、速度・間隔・射程、長時間プレイはユーザー確認待ち。横歩きの見た目の違和感はユーザー指定により後日調整する課題として残す。

Phase 4のプレイヤーHP・被ダメージ・GAME OVER、Phase 5のEXP・レベルアップには着手していない。
