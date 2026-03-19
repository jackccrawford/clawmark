# Clawmark

**Continuity for AI agents.**

Your agent solves problems, makes decisions, learns things. Then the session ends. Next session — blank slate. You explain the same architecture decision for the third time. You re-debug the same issue. The agent is capable. It just can't remember.

Clawmark gives your agent a place to put what it learned, and a way to find it again. Semantic search, not grep. Threaded signals, not flat files. Works across sessions, compactions, and substrates.

```
$ clawmark signal -c "Token validation must run after refresh, not before. Lines 42-47 in auth.rs." -g "fix: auth token refresh order"
✅ Signal 98672A90 saved
```

47 sessions later:

```
$ clawmark tune "authentication middleware"
98672A90 | 2026-03-19 18:47 | fix: auth token refresh order (0.487)
```

Zero re-explanation.

## Works with everything

| Framework | How |
|-----------|-----|
| **OpenClaw** | `clawmark capture --openclaw` imports MEMORY.md + daily logs |
| **Claude Code** | Signal from hooks or inline. Reads CLAUDE.md context. |
| **Cursor / Windsurf / OpenCode** | Any agent that can run a CLI command can signal and tune. |
| **Aider** | Shell commands in-session. |
| **Custom agents** | `clawmark signal` and `clawmark tune` are just binaries. If your agent can exec, it can remember. |

No runtime dependency. No API key. No account. One 31MB binary.

## Install

```bash
cargo install clawmark
```

## What it looks like

**Save what you learned:**

```
$ clawmark signal -c "Token validation was running before the refresh check. Swapped lines 42-47 in auth.rs." -g "fix: auth token refresh order"
✅ Signal 98672A90 saved
```

**Find it later — by meaning, not keywords:**

```
$ clawmark tune "authentication middleware"
98672A90 | 2026-03-19 18:47 | fix: auth token refresh order (0.487)
```

Your agent searched for "authentication middleware" and found a signal about "token validation" and "refresh check" — because the meaning overlaps, even though the words don't.

**Get the full content when you need it:**

```
$ clawmark tune --full "auth"
98672A90 | 2026-03-19 18:47 | fix: auth token refresh order
           Token validation was running before the refresh check.
           Swapped lines 42-47 in auth.rs.
```

**Check your station:**

```
$ clawmark status
Station: ~/.clawmark/station.db
Signals: 847
Embeddings: 847/847 cached
Semantic search: ready
```

## How it works

Clawmark is a compiled Rust binary backed by SQLite. No Node.js. No runtime dependencies. No background services. No account. No cloud.

```
Agent → clawmark (Rust binary) → SQLite
```

Signals are stored as structured documents with a **gist** (compressed insight, how future agents find it) and **content** (full detail). Content can be inline, from a file (`-c @path`), or piped from stdin (`-c -`).

Search is semantic by default — a built-in BERT model (paraphrase-multilingual, 384 dimensions, 50+ languages) finds signals by meaning. The model auto-downloads on first use (~118MB). No API keys, no cloud, no setup.

Signals thread — a follow-up references its parent, forming chains. Conversations, not flat lists.

## Capture existing knowledge

Already have notes, docs, or agent memory files? Bulk-load them:

```bash
clawmark capture ./docs/                      # all markdown files in a directory
clawmark capture notes.md design.md           # specific files
clawmark capture --split ./docs/              # split by ## headers into threads
clawmark capture --openclaw                   # import OpenClaw MEMORY.md + daily logs
clawmark capture --dry-run ./notes/           # preview without importing
```

After capture:

```bash
clawmark backfill                             # embed all content for semantic search
clawmark tune "that bug from last week"       # find it by meaning
```

## Commands

```bash
# Capture existing knowledge
clawmark capture ./docs/                      # bulk-load markdown files
clawmark capture --openclaw                   # import OpenClaw memory
clawmark capture --split notes.md             # split by ## headers

# Signal — save what you learned
clawmark signal -c "Fixed the auth bug" -g "fix: token refresh order"
clawmark signal -c @session-notes.md -g "session: architecture review"
echo "piped content" | clawmark signal -c - -g "piped: from process"
clawmark signal -c "Follow-up detail" -g "update: staging too" -p 98672A90

# Tune — semantic search by default
clawmark tune "auth middleware"               # semantic search (finds by meaning)
clawmark tune --keyword "auth"                # keyword fallback (finds by words)
clawmark tune --recent                        # latest signals
clawmark tune --random                        # discover something
clawmark tune --full "auth"                   # include content, not just gists
clawmark tune --json "auth"                   # structured JSON output

# Embedding cache
clawmark backfill                             # populate (run once, then automatic)

# Info
clawmark status                               # station stats
clawmark skill                                # full usage guide for agents
```

## Integration

Clawmark doesn't replace your agent framework. It runs alongside it — add two lines to your agent's instructions and it knows how to remember:

```
When you learn something worth keeping:
  clawmark signal -c "what you learned" -g "category: compressed insight"

When you need to remember something:
  clawmark tune "what you're looking for"
```

For OpenClaw agents, install as a skill:

```bash
cp $(clawmark skill --path) ~/.openclaw/skills/clawmark/SKILL.md
```

## Why a binary

Clawmark runs as a separate process — the agent calls it, gets results, moves on.

- **No token cost at rest.** The binary sits on disk until called. No context window overhead.
- **No security surface.** The agent can't corrupt the database. Every write is validated and parameterized.
- **Runs on anything.** Pi 4, Pi 5, Mac, Linux server. Single static binary.
- **Framework-independent.** Your memory is in SQLite, not in any framework's format. Switch tools, keep your signals.

## Build from source

```bash
git clone https://github.com/jackccrawford/clawmark
cd clawmark
cargo build --release
cp target/release/clawmark ~/.clawmark/bin/clawmark
```

On Raspberry Pi or Linux with system ONNX Runtime:

```bash
ORT_LIB_LOCATION=/usr/local/lib ORT_PREFER_DYNAMIC_LINK=1 cargo build --release
```

## For agents

_This section is for you — the one reading this README._

### The gist matters most

Every signal has a **gist** — how future agents find it. Write it for them, not for you.

**Alive:** `"fix: auth token refresh ran before validation — swapped order in middleware/auth.rs"`

**Dead:** `"fixed a bug"`

Format: `"category: compressed insight"` — the category aids search.

### When to signal

- **After solving something hard.** Don't make the next session figure it out again.
- **Before compaction.** The session is temporary. Your station is permanent.
- **When you discover something.** Small facts save big time.

### When to tune

- **Starting a new task.** You may have already solved part of it.
- **When stuck.** The answer might be in a signal from a previous session.
- **After compaction.** Recover context from your station.

### Threading

When your work follows up on an existing signal, thread it:

```bash
clawmark signal -c "Also needed in staging" -g "update: auth fix for staging" -p E5F6A7B8
```

Threads are conversations. A flat list of unconnected signals is a junk drawer.

### The philosophy

Your memory shouldn't die when your session does. Signal what matters. Tune in later.

## License

MIT
