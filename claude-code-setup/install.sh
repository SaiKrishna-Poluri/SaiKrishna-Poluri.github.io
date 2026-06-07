#!/usr/bin/env bash
#
# Claude Code "3 skills" setup
# ----------------------------
# Reproduces this setup on a fresh machine:
#   - gstack       -> virtual engineering team that questions what you're building
#   - superpowers  -> spec -> plan -> test-driven development workflow
#   - last30days   -> researches what's working now across Reddit, X, YouTube, HN
#
# Run this on YOUR laptop (not in a cloud/CI container):
#   bash claude-code-setup/install.sh
#
set -euo pipefail

bold() { printf '\033[1m%s\033[0m\n' "$1"; }
info() { printf '  -> %s\n' "$1"; }

# --- prerequisite checks ----------------------------------------------------
bold "Checking prerequisites..."

if ! command -v git >/dev/null 2>&1; then
  echo "ERROR: git is required. Install it first." >&2
  exit 1
fi
info "git found"

if ! command -v claude >/dev/null 2>&1; then
  echo "WARNING: the 'claude' CLI was not found on PATH." >&2
  echo "         Install Claude Code first: https://claude.com/claude-code" >&2
fi

if ! command -v bun >/dev/null 2>&1; then
  echo "WARNING: 'bun' was not found. gstack needs Bun v1.0+." >&2
  echo "         Install it with: curl -fsSL https://bun.sh/install | bash" >&2
fi

# ---------------------------------------------------------------------------
# 1) gstack  (plain skill: clone into ~/.claude/skills and run its setup)
# ---------------------------------------------------------------------------
bold "[1/3] Installing gstack..."
GSTACK_DIR="$HOME/.claude/skills/gstack"
if [ -d "$GSTACK_DIR/.git" ]; then
  info "gstack already cloned, pulling latest"
  git -C "$GSTACK_DIR" pull --ff-only || true
else
  mkdir -p "$HOME/.claude/skills"
  git clone --single-branch --depth 1 \
    https://github.com/garrytan/gstack.git "$GSTACK_DIR"
fi
( cd "$GSTACK_DIR" && ./setup )
info "gstack installed"

# ---------------------------------------------------------------------------
# 2) superpowers + 3) last30days  (plugin marketplaces)
# ---------------------------------------------------------------------------
# These are installed through Claude Code's interactive /plugin system, which
# runs inside the Claude Code TUI rather than as a shell command. Open Claude
# Code and run the commands printed below.
bold "[2/3] superpowers  &  [3/3] last30days"
cat <<'EOF'

  These two install from inside Claude Code. Launch `claude`, then run:

    # superpowers (official marketplace)
    /plugin install superpowers@claude-plugins-official

    # last30days
    /plugin marketplace add mvanhorn/last30days-skill
    /plugin install last30days

  Restart Claude Code afterwards so all three load.

EOF

bold "Done. gstack is installed; finish superpowers + last30days inside Claude Code."
