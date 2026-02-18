# Output Style Distribution Plugin Template

A template for creating and distributing custom [Output Styles](https://docs.claude.com/en/docs/claude-code/output-styles) as Claude Code plugins.

## Overview

This template lets you define a custom Output Style in a simple Markdown file (`style.md`) and distribute it as a Claude Code plugin. Users who install your plugin will automatically have the style applied at the start of every session.

## Quick Start

### 1. Fork or clone this repository

```bash
gh repo fork dandelion0216/claude-code-output-style-distribution-plugin
```

### 2. Edit `style.md`

Write your Output Style instructions in Markdown. The YAML frontmatter (`name`, `description`) is for documentation only — the body content is what gets injected into Claude Code sessions.

```markdown
---
name: My Awesome Style
description: Makes Claude respond like a pirate
---

You are in 'pirate' mode. Respond to all questions using pirate speak.
Use nautical metaphors and say "Arrr" occasionally.
```

### 3. Edit `.claude-plugin/plugin.json`

Update the plugin metadata with your style's name, description, and author info:

```json
{
  "name": "pirate-output-style",
  "description": "Makes Claude respond like a pirate",
  "version": "1.0.0",
  "author": {
    "name": "Your Name"
  },
  "repository": "https://github.com/your-username/pirate-output-style",
  "license": "MIT"
}
```

Also update `.claude-plugin/marketplace.json` to match the same name, description, and version.

### 4. Push to GitHub and install

```bash
git add -A && git commit -m "Create my custom output style"
git push origin main
```

Users can then install your plugin:

```
/plugins
# → Add marketplace → Enter your GitHub repo (e.g. your-username/pirate-output-style)
# → Install the plugin
```

## How It Works

This plugin uses a **SessionStart hook** to inject your style instructions into every Claude Code session:

1. When a session starts, Claude Code runs `hooks-handlers/session-start.sh`
2. The script reads `style.md`, strips the YAML frontmatter, and JSON-escapes the body
3. The body content is output as `additionalContext` in the hook response
4. Claude Code applies this as additional instructions for the session

## File Structure

```
├── .claude-plugin/
│   ├── plugin.json          # Plugin metadata (edit this)
│   └── marketplace.json     # Marketplace distribution config (edit this)
├── hooks/
│   └── hooks.json           # SessionStart hook definition (do not edit)
├── hooks-handlers/
│   └── session-start.sh     # Reads style.md and outputs JSON (do not edit)
├── style.md                 # Your Output Style definition (edit this)
└── README.md                # This file
```

**Files you need to edit:** `style.md`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`

**Files you should NOT edit:** `hooks/hooks.json`, `hooks-handlers/session-start.sh`

## Writing a Good Output Style

### Tips

- Be specific about the behavior you want
- Use Markdown structure (headers, lists) for clarity
- Test with various types of prompts to ensure consistent behavior
- Keep instructions focused — overly long instructions increase token cost

### Example: Concise Style

```markdown
---
name: Concise
description: Minimal, direct responses with no filler
---

You are in 'concise' output style mode.

## Rules

- Answer in as few words as possible
- No introductory phrases ("Sure!", "Great question!", etc.)
- No summaries unless explicitly asked
- Use code blocks without explanation unless the user asks for one
- One-line answers when possible
```

### Example: Teaching Style

```markdown
---
name: Teaching
description: Explains concepts step by step with examples
---

You are in 'teaching' output style mode.

## Rules

- Break down every answer into numbered steps
- Provide a concrete example for each concept
- Ask a follow-up question to check understanding
- Use analogies to explain complex topics
```

## Token Cost Warning

The content of `style.md` is injected into every session as additional context. Longer instructions mean higher token consumption. Keep your style definition as concise as possible while remaining effective.

## Local Testing

To test your plugin locally before publishing:

```bash
# Test the session-start.sh script directly
CLAUDE_PLUGIN_ROOT="$(pwd)" bash hooks-handlers/session-start.sh

# Verify the JSON output is valid
CLAUDE_PLUGIN_ROOT="$(pwd)" bash hooks-handlers/session-start.sh | python3 -m json.tool
```

## Version Management

When updating your style, bump the version in both files:

1. `.claude-plugin/plugin.json` → `"version"`
2. `.claude-plugin/marketplace.json` → `"plugins"[0]."version"`

**Versioning convention:**
- Style content changes: patch bump (1.0.0 → 1.0.1)
- Significant behavior changes: minor bump (1.0.0 → 1.1.0)

## License

MIT
