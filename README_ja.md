# Output Style Manager

Claude Codeの [Output Style](https://docs.claude.com/en/docs/claude-code/output-styles) を管理・切り替えするプラグインです。インストールしてスタイルを選ぶだけで、自動的に適用されます。

## クイックスタート

### 1. プラグインをインストール

```
/plugins
# → Add marketplace → dandelion0216/output-style-manager
# → "output-style-manager" をインストール
```

### 2. スタイルを選択

```
/set-output-style
```

一覧から選択するか、スタイル名を直接指定できます:

```
/set-output-style concise
```

### 3. 新しいセッションを開始

選択したスタイルは次回のセッション開始時から適用されます。

スタイルを無効化するには:

```
/set-output-style off
```

## カスタムスタイルの作成

対話形式でスタイルを作成し、共有URLを取得できます:

```
/create-output-style
```

Claudeがスタイルの定義をガイドし、ローカルに保存した後、Gistにアップロードして共有できます。

## コミュニティスタイルのブラウズ & インポート

コミュニティが共有したスタイルを `registry.json` の一覧から選んでインストールできます:

```
/add-output-style
```

URLやローカルファイルから直接インポートも可能です:

```
/add-output-style https://example.com/my-style.md
/add-output-style /path/to/my-style.md
```

インポートされたスタイルは `~/.claude/custom-output-styles/` に保存され、`/set-output-style` で選択できます。

### スタイルファイルのフォーマット

```markdown
---
name: My Style
description: スタイルの簡潔な説明
---

スタイルの指示をここに記述します。この内容が毎セッション開始時に
additionalContext として Claude Code に注入されます。
```

## 同梱スタイル

| スタイル | 説明 |
|---------|------|
| `concise` | 無駄を省いた最小限の応答 |
| `teaching` | ステップバイステップの説明と例の提示 |

## 仕組み

1. セッション開始時に `SessionStart` フックが `session-start.sh` を実行
2. スクリプトが `~/.claude/output-style-active` からアクティブスタイル名を読み取り
3. カスタムスタイル（`~/.claude/custom-output-styles/`）を優先し、次に同梱スタイル（`styles/`）を検索
4. スタイルの内容が `additionalContext` として注入

## ファイル構成

```
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── hooks/
│   └── hooks.json
├── hooks-handlers/
│   └── session-start.sh
├── skills/
│   ├── set-output-style/
│   │   └── SKILL.md
│   ├── add-output-style/
│   │   └── SKILL.md
│   └── create-output-style/
│       └── SKILL.md
├── styles/
│   ├── concise.md
│   └── teaching.md
├── registry.json
└── README.md
```

## スタイルの共有

1. `/create-output-style` でスタイルを作成し、Gistにアップロード
2. Gist URLを共有すれば、他のユーザーは `/add-output-style <URL>` でインポート可能
3. コミュニティ一覧に掲載するには、`registry.json` にエントリを追加するPRを送信

## トークンコストに関する注意

アクティブなスタイルの内容は毎セッション開始時に追加コンテキストとして注入されます。トークン消費を最小限にするため、スタイル定義は簡潔に保ってください。

## ライセンス

MIT
