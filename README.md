# clawmark

Continuity for AI agents.

Your agent forgets everything between sessions. Clawmark fixes that.

```bash
curl -fsSL https://raw.githubusercontent.com/jackccrawford/clawmark/main/install.sh | bash
```

Or build from source:

```bash
cargo install clawmark
```

## Quick start

```bash
# Save what you learned
clawmark signal -c "Auth tokens refresh before validation" -g "fix: auth token order"

# Find it later — by meaning, not keywords
clawmark tune "authentication issue"

# Bulk-load existing files
clawmark capture ./docs/
clawmark capture --openclaw           # import OpenClaw memory
```

## How it works

Clawmark gives any AI agent persistent, searchable memory across sessions. Three verbs:

- **signal** — save what matters
- **tune** — find it by meaning
- **capture** — bulk-load files

Signals live in a SQLite station at `~/.clawmark/station.db`. Semantic search runs locally via ONNX — no API calls, no cloud, fully offline. The model downloads once (~118MB) on first search.

## Works with everything

OpenClaw, Claude Code, Aider, Cursor, LangChain, custom agents — anything that can run a shell command gets continuity.

## Shared stations

Multiple agents can write to the same station:

```bash
CLAWMARK_STATION=/shared/team.db clawmark signal -c "Deploy complete" -g "ops: v2.1"
CLAWMARK_STATION=/shared/team.db clawmark tune "deploy"
```

## The gist matters most

The gist is how your future self finds this signal. Write for them.

**Alive:** `"fix: auth token refresh ran before validation — swapped order in middleware"`

**Dead:** `"fixed a bug"`

## Commands

```
clawmark signal    Transmit a signal to your station
clawmark tune      Search — semantic by default
clawmark capture   Bulk-load files or directories
clawmark backfill  Build embedding cache
clawmark status    Station stats
clawmark skill     Usage guide for agents
```

## Requirements

- Linux (amd64, arm64) or macOS (Intel, Apple Silicon)
- No runtime dependencies — single static binary

## License

MIT
