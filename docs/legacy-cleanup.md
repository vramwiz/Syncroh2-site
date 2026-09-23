---
title: 旧版ファイル削除
description: 旧 Inno Setup 版の新旧朗2から AviUtl2 カタログ版へ移行するための削除手順
---

# 旧版ファイル削除ツール

旧 Inno Setup 版が管理者権限で作成したフォルダーを、AviUtl2 カタログから削除できない場合に使用します。
**新旧朗2をインストールするツールではありません。** 通常の更新には必要ありません。

## ダウンロード

- [EXE を直接ダウンロード](files/Syncroh2_LegacyCleanup.exe)
- [ZIP をダウンロード](files/Syncroh2_LegacyCleanup.zip)

SHA-256:

- EXE: `9A4A7ECD104D3BD2CDB087A420630BF222D345A95EE9914F80B580B2916C6B86`
- ZIP: `85C8A4049586CD1B39F4FE619C088065A3E35C1778355AE74FCE54D6BB7F5276`

## 実行手順

1. AviUtl2 と新旧朗2を終了します。
2. カタログ版をインストール済みの場合は、先に AviUtl2 カタログからアンインストールします。
3. EXE を直接ダウンロードするか、ZIP を展開して `Syncroh2_LegacyCleanup.exe` を実行します。Windows が管理者権限を求めたら確認してください。
4. 画面に表示される削除対象を確認して「削除」を押します。
5. 完了後、必要に応じて AviUtl2 カタログから新旧朗2をインストールします。

削除するのは、次の2フォルダーと中身すべてです。追加したファイルがある場合は、実行前に別の場所へ退避してください。

- `%ProgramData%\aviutl2\Plugin\Syncroh2`
- `%ProgramData%\aviutl2\Script\Syncroh2`

旧 Inno Setup の「インストールされているアプリ」への登録や、ほかの場所に置いた Desktop 本体は削除しません。
