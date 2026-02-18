---
name: add-output-style
description: "Output Styleをインポートする。コミュニティ共有スタイルの一覧からも選択可能。「スタイルを追加」「add output style」で呼び出される。"
disable-model-invocation: true
---

# Output Style インポート

## 入力

`$ARGUMENTS` にインポート元が指定される。

- `/add-output-style` — 引数なし: コミュニティ一覧から選択
- `/add-output-style https://example.com/style.md` — URLからインポート
- `/add-output-style /path/to/style.md` — ローカルファイルからインポート

## 実行手順

### 1. インポート元の特定

**`$ARGUMENTS` が空の場合: コミュニティ一覧を表示**

`${CLAUDE_PLUGIN_ROOT}/registry.json` を Read で読み取り、`styles` 配列をパースする。

各エントリには以下のフィールドがある:
- `name` — スタイル名
- `description` — スタイルの説明
- `gist_id` — Gist ID（null の場合は同梱スタイル）
- `author` — 作成者
- `bundled` — 同梱スタイルかどうか

**同梱スタイル（`bundled: true`）は一覧から除外する**（これらは既にインストール済み）。

コミュニティスタイル（`bundled: false`）を AskUserQuestion でユーザーに提示する:
- 各選択肢の label にスタイル名、description にスタイルの説明と作成者を設定
- 「URLを直接指定」も選択肢に含める

ユーザーが選択したスタイルの `gist_id` を使って手順2に進む（`gh gist view <gist_id> --raw`）。

**コミュニティスタイルが見つからない場合:**
- 「コミュニティスタイルはまだ登録されていません。URLまたはファイルパスを直接指定してください。」と案内
- AskUserQuestion でインポート元を質問する

**`$ARGUMENTS` がURLまたはファイルパスの場合:**
そのまま手順2に進む。

### 2. スタイルファイルの取得

**URLの場合（http:// または https:// で始まる）:**

GitHub Gist の URL の場合、raw コンテンツURLに変換する必要がある:
- `https://gist.github.com/user/id` → `gh gist view <id> --raw` で内容を取得（Bash）
- それ以外のURL → WebFetch でURLの内容を取得する

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

### 6. スタイルの有効化を提案

AskUserQuestion で確認する:
- 「インポートしたスタイルを今すぐ有効化しますか？（次回セッションから適用）」
- 選択肢: 「有効化する」「あとで」

**「有効化する」の場合:**

```bash
echo "<スタイル名>" > ~/.claude/output-style-active
```

### 7. 結果の案内

以下の情報をユーザーに伝える:
- インポートしたスタイル名
- 保存先パス
- 有効化した場合: 「次回セッション開始時から適用されます」
- 有効化しなかった場合: 「`/set-output-style <スタイル名>` で有効化できます」
