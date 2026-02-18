---
name: set-output-style
description: "Output Styleを切り替える。「スタイルを変更」「set output style」で呼び出される。"
disable-model-invocation: true
---

# Output Style 切り替え

## 入力

`$ARGUMENTS` にスタイル名が指定される場合がある。

- `/set-output-style` — 引数なし: 一覧から選択
- `/set-output-style concise` — スタイル名指定: 即座に設定
- `/set-output-style off` — スタイル無効化

## 実行手順

### 1. 利用可能なスタイルを収集

以下の2箇所から `.md` ファイルを Glob で取得する:

- `${CLAUDE_PLUGIN_ROOT}/styles/*.md` — 同梱スタイル
- `~/.claude/custom-output-styles/*.md` — ユーザーインポートスタイル

各ファイルの先頭10行を Read で読み、フロントマッターから `name` と `description` を抽出する。

### 2. 引数の処理

**`$ARGUMENTS` が "off" の場合:**
- `~/.claude/output-style-active` ファイルを削除する（Bash: `rm -f ~/.claude/output-style-active`）
- 「Output Styleを無効化しました。次回セッションから適用されます。」と案内して終了

**`$ARGUMENTS` にスタイル名が指定されている場合:**
- 収集したスタイル一覧にそのファイル名（拡張子なし）が存在するか確認
- 存在すれば手順3へ進む（選択済みとして扱う）
- 存在しなければ「スタイル '$ARGUMENTS' が見つかりません。」と案内し、一覧を表示

**`$ARGUMENTS` が空の場合:**
- 手順3で一覧を表示して選択させる

### 3. スタイルの選択と設定

AskUserQuestion を使い、収集したスタイル一覧をユーザーに提示する。
各選択肢の label にスタイル名、description にスタイルの説明を設定する。
「無効化 (off)」も選択肢に含める。

ユーザーが選択したスタイル名（ファイル名から .md を除いたもの）を `~/.claude/output-style-active` に書き込む:

```bash
echo "スタイル名" > ~/.claude/output-style-active
```

### 4. 結果の案内

以下の情報をユーザーに伝える:
- 設定したスタイル名
- 「次回セッション開始時から適用されます」
- 現在のセッション中は反映されない旨
