---
name: create-output-style
description: "Output Styleを作成してアップロード・共有する。「スタイルを作成」「create output style」で呼び出される。"
disable-model-invocation: true
---

# Output Style 作成

ユーザーと対話しながらカスタムOutput Styleを作成し、ローカル保存・Gistアップロード・コミュニティ登録までを行う。

## 実行手順

### 1. スタイルの要件をヒアリング

AskUserQuestion を使い、以下を質問する:

**質問1: スタイル名**
- 「スタイル名を教えてください（英語、kebab-case推奨。例: formal-japanese, pirate-speak）」

**質問2: スタイルの方向性**
- 「どのようなスタイルにしたいですか？（例: 丁寧な日本語で応答する、簡潔に答える、先生のように教える、など）」

### 2. スタイルファイルの生成

ヒアリング内容をもとに、以下のフォーマットでスタイル定義を生成する:

```markdown
---
name: <スタイル名>
description: <スタイルの簡潔な説明>
---

<Claudeへの振る舞い指示>
```

**生成時のガイドライン:**
- 指示は具体的かつ簡潔に（トークンコスト削減のため）
- `You are in '<スタイル名>' output style mode.` で始める
- `## Rules` セクションで箇条書きのルールを列挙する
- 必要に応じて `## Formatting` や `## Tone` などのセクションを追加

### 3. ユーザーに確認

生成したスタイル定義の全文をユーザーに表示し、AskUserQuestion で確認する:
- 「この内容でよろしいですか？」
- 選択肢: 「このまま保存」「修正したい」

「修正したい」の場合は修正点を聞いて再生成する。

### 4. ローカルに保存

```bash
mkdir -p ~/.claude/custom-output-styles
```

ファイル名はスタイル名をそのまま使用（例: `formal-japanese.md`）。
Write ツールで `~/.claude/custom-output-styles/<スタイル名>.md` に保存する。

### 5. Gistアップロード & コミュニティ共有

AskUserQuestion で確認する:
- 「コミュニティに共有しますか？（Gistにアップロードし、共有URLを取得できます）」
- 選択肢: 「共有する」「ローカルのみ」

**「共有する」の場合:**

**ステップ5a: Gistにアップロード**

```bash
gh gist create ~/.claude/custom-output-styles/<スタイル名>.md --desc "<スタイルの説明>" --public
```

出力からGist URLとGist IDを取得する。

**ステップ5b: レジストリ登録の案内**

以下の情報をユーザーに伝える:
- Gist URL
- 「コミュニティの `/add-output-style` 一覧に表示するには、output-style-manager リポジトリの `registry.json` にエントリを追加するPRを送ってください。」
- 追加するエントリの例を提示:

```json
{
  "name": "<スタイル名>",
  "description": "<スタイルの説明>",
  "gist_id": "<Gist ID>",
  "author": "<GitHubユーザー名>",
  "bundled": false
}
```

- 「PRが不要な場合は、Gist URLを直接共有すれば `/add-output-style <URL>` でインポートできます。」

### 6. スタイルの有効化を提案

AskUserQuestion で確認する:
- 「作成したスタイルを今すぐ有効化しますか？（次回セッションから適用）」
- 選択肢: 「有効化する」「あとで」

**「有効化する」の場合:**

```bash
echo "<スタイル名>" > ~/.claude/output-style-active
```

「次回セッション開始時から '<スタイル名>' スタイルが適用されます。」と案内する。

### 7. 完了メッセージ

以下の情報をまとめて表示する:
- 保存先: `~/.claude/custom-output-styles/<スタイル名>.md`
- Gist URL（アップロードした場合）
- 現在のアクティブスタイル
- `/set-output-style <スタイル名>` でいつでも有効化できる旨
- 共有した場合: Gist URL と「`/add-output-style <Gist URL>` で他のユーザーもインポートできます」
