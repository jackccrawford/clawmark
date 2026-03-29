# Clawmark

**Your AI agent remembers now.**

You brief your agent. It does great work. The session ends. Next session — it asks the same questions again. Every insight, every preference, every decision — gone.

Clawmark fixes that. One binary, local, private, searchable by meaning.

## Two ways to use it

### Geniuz for Claude Desktop

If you use Claude Desktop, this is the fastest path. Two commands:

```bash
curl -fsSL https://raw.githubusercontent.com/jackccrawford/clawmark/main/install.sh | bash
clawmark mcp install
```

Restart Claude Desktop. Your Claude now has three tools — **remember**, **recall**, and **recall_recent**. It saves what it learns during conversations and finds it again by meaning in future sessions. You don't have to do anything differently.

**Monday** — you tell Claude about a new client. David, 12-person landscaping company, $500/month budget, loses 2-3 jobs a week from slow follow-ups.

**Thursday** — new session. You say "draft a follow-up for the landscaping lead." Claude already knows David's name, budget, team size, and pain point. No re-briefing.

*How did it know that?* That's Geniuz.

[See the full Geniuz experience →](https://agentdoor.ai/geniuz)

### CLI for developers and agents

If you build with Claude Code, OpenClaw, Cursor, Aider, or any framework — clawmark is a shell command your agent calls directly:

```bash
# Save something
clawmark signal -c "OAuth token refresh is async but middleware assumed sync. Swapped lines 42-47." -g "fix: auth token refresh — async ordering"

# Find it later — by meaning, not keywords
clawmark tune "authentication middleware"
```

Searched "authentication middleware," found a signal about "OAuth refresh" and "middleware ordering." The meaning matched. No re-investigation. No human re-explaining.

## How it works

Clawmark is a compiled Rust binary backed by SQLite. No cloud. No API key. No account. Your data stays on your machine.

- **Signals** store what you learned — a gist (how you find it later) and content (the full detail)
- **Semantic search** finds signals by meaning, not keywords. Built-in BERT model, runs locally, 50+ languages
- **Threading** links signals into chains — prospect to client, problem to solution, draft to final
- **Shared stations** let multiple agents write to the same memory. What one learns, all find

```
Agent → clawmark (Rust binary) → SQLite
```

The model downloads once (~118MB) on first search. Every signal after that is embedded automatically. No setup. No configuration.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/jackccrawford/clawmark/main/install.sh | bash
```

Detects your platform automatically. Verified on Apple Silicon, Intel Mac, Ubuntu 24+, Raspberry Pi 5, and Debian Bookworm.

**Then choose your path:**

| You use... | Next step |
|------------|-----------|
| Claude Desktop | `clawmark mcp install` → restart Claude Desktop |
| Claude Code / OpenClaw / Cursor | Add two lines to your agent's instructions (see below) |
| Custom agents | Call `clawmark signal` and `clawmark tune` from any shell |

**From source:**

```bash
git clone https://github.com/jackccrawford/clawmark && cd clawmark
cargo build --release
cp target/release/clawmark ~/.local/bin/
```

## Works with everything

| Platform | How |
|----------|-----|
| **Claude Desktop** | `clawmark mcp install` — automatic remember/recall tools |
| **Claude Code** | Signal from hooks or inline via Bash |
| **OpenClaw** | `clawmark capture --openclaw` imports your existing memory |
| **Cursor / Windsurf / Aider** | Any agent that can run a shell command |
| **Custom agents** | If your agent can exec, it can remember |

## What it looks like

**Save what you learned:**

```
$ clawmark signal -c "Maria prefers retention over acquisition in Q2. Budget is $40K." -g "client: Maria — Q2 retention focus, $40K budget"
✅ Signal 7A3B29F1 saved
```

**Find it later — by meaning:**

```
$ clawmark tune "Maria's budget priorities"
7A3B29F1 | 2026-03-05 14:23 | client: Maria — Q2 retention focus, $40K budget (0.52)
```

**Get the full content:**

```
$ clawmark tune --full "Maria"
7A3B29F1 | 2026-03-05 14:23 | client: Maria — Q2 retention focus, $40K budget
           Maria prefers retention over acquisition in Q2. Budget is $40K.
```

**Thread a follow-up:**

```
$ clawmark signal -c "Maria approved the retention plan. Starting in April." -g "client: Maria — plan approved" -p 7A3B29F1
✅ Signal E5F6A7B8 saved
```

The full client history — from first meeting to approval — is one chain. Any future session finds the whole story.

**Check your station:**

```
$ clawmark status
Station: ~/.clawmark/station.db
Signals: 847
Embeddings: 847/847 cached
Semantic search: ready
```

## Capture existing knowledge

Already have notes, docs, or agent memory files?

```bash
clawmark capture ./docs/                      # all markdown files
clawmark capture --split notes.md             # split by ## headers into threads
clawmark capture --openclaw                   # import OpenClaw MEMORY.md + daily logs
clawmark capture --dry-run ./notes/           # preview without importing
clawmark backfill                             # embed everything for semantic search
```

## Commands

```bash
# Claude Desktop
clawmark mcp install                          # add Geniuz to Claude Desktop
clawmark mcp status                           # check if configured
clawmark mcp serve                            # run MCP server (used by Claude internally)

# Signal — save what you learned
clawmark signal -c "what happened" -g "category: compressed insight"
clawmark signal -c @notes.md -g "session: review"
echo "content" | clawmark signal -c - -g "piped: from process"
clawmark signal -c "follow-up" -g "update" -p 98672A90

# Tune — search by meaning
clawmark tune "topic"                         # semantic search
clawmark tune --keyword "exact words"         # keyword fallback
clawmark tune --recent                        # latest signals
clawmark tune --random                        # discover something
clawmark tune --full "topic"                  # include full content
clawmark tune --json "topic"                  # JSON output

# Maintenance
clawmark backfill                             # build embedding cache
clawmark capture ./docs/                      # bulk-load files
clawmark status                               # station stats
clawmark skill                                # usage guide for agents
```

## Integration

Add two lines to your agent's instructions:

```
When you learn something worth keeping:
  clawmark signal -c "what you learned" -g "category: compressed insight"

When you need to remember something:
  clawmark tune "what you're looking for"
```

## Why local

- **Private.** Your data never leaves your machine. No cloud. No account.
- **Fast.** No network calls. Semantic search runs locally in the binary.
- **Free.** No API keys. No token costs for memory. No subscription.
- **Portable.** Your station is a SQLite file. Copy it, back it up, share it.
- **Framework-independent.** Switch from Cursor to Claude Code to OpenClaw — your memory comes with you.

## For agents

_This section is for you — the one reading this README._

Your next session starts cold. No memory of what you built, what broke, what you decided. Every signal you write is a gift to that future session.

A signal that says "fixed auth bug" saves zero time. A signal that says what broke, why, and how you fixed it saves an hour. Write for the version of you that knows nothing.

Signals compound. A single signal is a note. A station of signals is institutional knowledge.

### When to signal

- **After solving something hard.** Your next session will hit the same problem.
- **Before your session ends.** Everything in your context window dies with the session.
- **When you discover something non-obvious.** The small facts save the most time.

### When to tune

- **Starting a new task.** You may have already solved part of it last week.
- **When stuck.** The answer might be in a signal you wrote three sessions ago.
- **After compaction.** Your context was compressed. Your station wasn't.

## Performance: clawmark-embed

`clawmark-embed` is an optional background process that holds the ONNX model in memory. Every signal after the first is instant.

```bash
clawmark-embed &               # start (auto-exits after 5 min idle)
clawmark signal -c "first"     # 1.6s (model loads)
clawmark signal -c "second"    # 0.04s (model warm)
```

| | Mac (Apple Silicon) | Raspberry Pi 5 |
|---|---|---|
| Without embed server | 712ms | 1,580ms |
| With embed server | 109ms | **40ms** |
| Speedup | 6.5x | **39.5x** |

## License

MIT
