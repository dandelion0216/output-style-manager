---
name: add-output-style
description: |
  Output Styleをインポートする。
  「スタイルを追加」「output styleをインポート」「add output style」で呼び出される。
disable-model-invocation: true
---

# Output Style インポート

## 入力

`$ARGUMENTS` にインポート元が指定される。

- `/add-output-style https://example.com/style.md` — URLからインポート
- `/add-output-style /path/to/style.md` — ローカルファイルからインポート
- `/add-output-style` — 引数なし: ソースを質問

## 実行手順

### 1. インポート元の特定

**`$ARGUMENTS` が空の場合:**
AskUserQuestion で以下を質問する:
- 「インポート元を指定してください（URLまたはファイルパス）」

**`$ARGUMENTS` が指定されている場合:**
そのまま使用する。

### 2. スタイルファイルの取得

**URLの場合（http:// または https:// で始まる）:**
- WebFetch でURLの内容を取得する
- レスポンスからMarkdownの内容を抽出する

**ローカルファイルパスの場合:**
- Read でファイルの内容を読み取る

### 3. スタイルファイルの検証

取得した内容が有効なOutput Styleファイルか検証する:
- YAMLフロントマッター（`---` で囲まれたセクション）が存在するか
- フロントマッターに `name` フィールドがあるか
- フロントマッター以降に本文（スタイル指示）が存在するか

検証に失敗した場合:
- 何が不足しているかをユーザーに伝える
- 正しいフォーマットの例を提示する:

```markdown
---
name: style-name
description: スタイルの説明
---

スタイルの指示内容をここに記述
```

### 4. 保存先の決定

ファイル名はフロントマッターの `name` フィールドをケバブケース化して使用する。
（例: name: "My Cool Style" → my-cool-style.md）

保存先: `~/.claude/custom-output-styles/<ファイル名>.md`

ディレクトリが存在しない場合は作成する:
```bash
mkdir -p ~/.claude/custom-output-styles
```

同名ファイルが既に存在する場合:
- AskUserQuestion で上書きするか確認する

### 5. ファイルの保存

取得した内容をそのまま保存先に書き込む（Write ツールを使用）。

### 6. 結果の案内

以下の情報をユーザーに伝える:
- インポートしたスタイル名
- 保存先パス
- 「`/set-output-style <スタイル名>` で有効化できます」と案内
- 現在アクティブなスタイルがあれば、その情報も表示する
