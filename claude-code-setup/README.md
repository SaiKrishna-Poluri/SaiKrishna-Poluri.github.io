# Claude Code — the 3-skill setup

> Decision. Execution. Research. One job each. Zero overlap.

This folder reproduces a minimal, high-leverage Claude Code setup built on just
three skills. Each does one thing and they don't overlap.

| Skill | What it does | Repo |
|-------|--------------|------|
| **gstack** | Turns Claude Code into a virtual engineering team that questions what you're building *before* code starts. | https://github.com/garrytan/gstack |
| **superpowers** | Forces `spec → plan → test-driven development`, so you ship solid code instead of vibe-coded slop. | https://github.com/obra/superpowers |
| **last30days** | Finds what's working *now* across Reddit, X, YouTube, HN, and the open web. | https://github.com/mvanhorn/last30days-skill |

## Quick install

Run this **on your laptop** (not in a cloud/CI container — these install into
your personal `~/.claude` and use Claude Code's interactive `/plugin` system):

```bash
bash claude-code-setup/install.sh
```

The script installs **gstack** automatically, then prints the two `/plugin`
commands to finish **superpowers** and **last30days** inside Claude Code.

## Manual install (copy-paste)

**1. gstack** (terminal — needs [Bun](https://bun.sh) v1.0+):

```bash
git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git \
  ~/.claude/skills/gstack && cd ~/.claude/skills/gstack && ./setup
```

**2. superpowers** (inside Claude Code):

```
/plugin install superpowers@claude-plugins-official
```

**3. last30days** (inside Claude Code):

```
/plugin marketplace add mvanhorn/last30days-skill
/plugin install last30days
```

Restart Claude Code after installing so all three skills load.

## Notes

- **gstack** requires Git, Bun v1.0+, and (on Windows) Node.js.
- **last30days** works out of the box for Reddit/HN/Polymarket/GitHub; the first
  run launches a 30-second wizard to unlock X, YouTube, and TikTok.
- All three are free / open source.
