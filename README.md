# Output Style Manager

A Claude Code plugin for managing and switching [Output Styles](https://docs.claude.com/en/docs/claude-code/output-styles). Install the plugin, pick a style, and it's applied automatically.

## Quick Start

### 1. Install the plugin

```
/plugins
# → Add marketplace → dandelion0216/output-style-manager
# → Install "output-style-manager"
```

### 2. Choose a style

```
/set-output-style
```

Select from the list of available styles, or specify one directly:

```
/set-output-style concise
```

### 3. Start a new session

The selected style takes effect from the next session start.

To disable the active style:

```
/set-output-style off
```

## Importing Custom Styles

You can import styles from URLs or local files:

```
/add-output-style https://example.com/my-style.md
/add-output-style /path/to/my-style.md
```

Imported styles are saved to `~/.claude/custom-output-styles/` and can be selected with `/set-output-style`.

### Style File Format

```markdown
---
name: My Style
description: Brief description of the style
---

Your style instructions here. This content is injected as
additionalContext at the start of every Claude Code session.
```

## Bundled Styles

| Style | Description |
|-------|-------------|
| `concise` | Minimal, direct responses with no filler |
| `teaching` | Step-by-step explanations with examples |

## How It Works

1. On session start, the `SessionStart` hook runs `session-start.sh`
2. The script reads the active style name from `~/.claude/output-style-active`
3. It looks for the style file in custom styles (`~/.claude/custom-output-styles/`) first, then bundled styles (`styles/`)
4. The style content is injected as `additionalContext`

## File Structure

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
│   └── add-output-style/
│       └── SKILL.md
├── styles/
│   ├── concise.md
│   └── teaching.md
└── README.md
```

## Sharing Styles

Created a useful style? Share it with others:

- Upload the `.md` file to a GitHub Gist, blog post, or any URL
- Others can import it with `/add-output-style <URL>`

No repository or Pull Request needed.

## Token Cost Warning

The active style content is injected into every session as additional context. Keep style definitions concise to minimize token consumption.

## License

MIT
