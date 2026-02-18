# Output Style 配布プラグイン テンプレート

Claude Codeのカスタム [Output Style](https://docs.claude.com/en/docs/claude-code/output-styles) をプラグインとして作成・配布するためのテンプレートです。

## 概要

Markdownファイル（`style.md`）にスタイル指示を記述するだけで、Claude Codeプラグインとして配布できます。インストールしたユーザーのセッション開始時に、スタイルが自動適用されます。

## クイックスタート

### 1. リポジトリをForkまたはクローン

```bash
gh repo fork dandelion0216/claude-code-output-style-distribution-plugin
```

### 2. `style.md` を編集

Output Styleの指示をMarkdownで記述します。YAMLフロントマッター（`name`, `description`）はドキュメント用で、本文がClaude Codeのセッションに注入されます。

```markdown
---
name: My Awesome Style
description: 海賊風に応答するスタイル
---

あなたは「海賊」モードです。すべての質問に海賊風の口調で答えてください。
航海のメタファーを使い、時折「アール！」と言ってください。
```

### 3. `.claude-plugin/plugin.json` を編集

プラグインのメタデータを自分のスタイルに合わせて更新します:

```json
{
  "name": "pirate-output-style",
  "description": "海賊風に応答するOutput Style",
  "version": "1.0.0",
  "author": {
    "name": "Your Name"
  },
  "repository": "https://github.com/your-username/pirate-output-style",
  "license": "MIT"
}
```

`.claude-plugin/marketplace.json` も同じ名前・説明・バージョンに更新してください。

### 4. GitHubにプッシュしてインストール

```bash
git add -A && git commit -m "Create my custom output style"
git push origin main
```

他のユーザーは以下の手順でインストールできます:

```
/plugins
# → Add marketplace → GitHubリポジトリを入力（例: your-username/pirate-output-style）
# → プラグインをインストール
```

## 仕組み

このプラグインは **SessionStartフック** を使い、セッション開始時にスタイル指示を注入します:

1. セッション開始時に Claude Code が `hooks-handlers/session-start.sh` を実行
2. スクリプトが `style.md` を読み取り、YAMLフロントマッターを除去し、本文をJSONエスケープ
3. 本文が `additionalContext` としてフックレスポンスに出力
4. Claude Code がセッションの追加指示として適用

## ファイル構成

```
├── .claude-plugin/
│   ├── plugin.json          # プラグインメタデータ（要編集）
│   └── marketplace.json     # マーケットプレイス配布設定（要編集）
├── hooks/
│   └── hooks.json           # SessionStartフック定義（編集不要）
├── hooks-handlers/
│   └── session-start.sh     # style.mdを読み取りJSON出力（編集不要）
├── style.md                 # Output Style定義（要編集）
└── README.md                # 英語版ドキュメント
```

**編集が必要なファイル:** `style.md`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`

**編集不要なファイル:** `hooks/hooks.json`, `hooks-handlers/session-start.sh`

## 良いOutput Styleを書くコツ

### ヒント

- 求める振る舞いを具体的に記述する
- Markdownの構造（見出し、リスト）を使って整理する
- さまざまなプロンプトでテストし、一貫した振る舞いを確認する
- 指示は簡潔に — 長すぎるとトークンコストが増加する

### 例: 簡潔スタイル

```markdown
---
name: Concise
description: 無駄を省いた最小限の応答
---

あなたは「簡潔」モードです。

## ルール

- できるだけ少ない言葉で回答する
- 前置き（「もちろん！」「良い質問ですね！」等）は不要
- 明示的に求められない限り要約しない
- コードブロックは説明なしで提示する（求められた場合を除く）
- 可能な限り一行で回答する
```

### 例: 教育スタイル

```markdown
---
name: Teaching
description: ステップバイステップで概念を説明し、例を提示する
---

あなたは「教育」モードです。

## ルール

- すべての回答を番号付きステップに分解する
- 各概念に具体的な例を提示する
- 理解度確認のためフォローアップ質問をする
- 複雑なトピックにはアナロジーを使って説明する
```

## トークンコストに関する注意

`style.md` の内容は毎セッション開始時に追加コンテキストとして注入されます。指示が長いほどトークン消費が増加します。効果を保ちつつ、できるだけ簡潔に記述してください。

## ローカルテスト

公開前にローカルでテストできます:

```bash
# session-start.sh を直接実行
CLAUDE_PLUGIN_ROOT="$(pwd)" bash hooks-handlers/session-start.sh

# JSON出力の妥当性を検証
CLAUDE_PLUGIN_ROOT="$(pwd)" bash hooks-handlers/session-start.sh | python3 -m json.tool
```

## バージョン管理

スタイルを更新する際は、以下の2ファイルのバージョンを同時に更新してください:

1. `.claude-plugin/plugin.json` → `"version"`
2. `.claude-plugin/marketplace.json` → `"plugins"[0]."version"`

**バージョニング規則:**
- スタイル内容の修正: パッチ（1.0.0 → 1.0.1）
- 振る舞いの大幅な変更: マイナー（1.0.0 → 1.1.0）

## ライセンス

MIT
