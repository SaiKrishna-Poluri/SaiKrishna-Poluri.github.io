---
title: "CLI Is All You Need: How I Wired Up Git, Azure, Databricks, and AI Agents in One Terminal"
subtitle: "I spent a decade getting fluent in portals. AI agents sent me back to the terminal, and I'm not going back."
slug: "cli-is-all-you-need"
date: 2026-10-23
publishedAt: 2026-10-23
author: Saikrishna Poluri
canonical_url: "https://saikrishna-poluri.github.io/2026/10/23/cli-is-all-you-need/"
canonicalUrl: "https://saikrishna-poluri.github.io/2026/10/23/cli-is-all-you-need/"
tags:
  - data-engineering
  - ai-agents
  - azure
  - databricks
  - claude-code
  - devops
  - cli
description: "A Lead Data Engineer's practical guide to the four-layer CLI stack (git, az, databricks, and AI coding agents), with install steps, guardrails, and end-to-end workflows from real enterprise work."
layout: post
---

> **A note on names.** Every company name, URL, workspace ID, subscription, resource group, catalog, schema, and table in this article is a placeholder. The commands, the guardrails, and the stories are real.

---

A few weeks ago I watched an AI agent fix a number.

A reconciliation constant in one of our pipelines no longer matched the figure the source system said it should. Across a handful of small branches, the agent found where the constant lived and checked whether our nightly job actually imported that module. It didn't, so a deploy alone wouldn't prove the fix, and the agent told me so. Then it made the change, ran the unit tests, deployed the bundle to our dev workspace, ran the job, ran a set of hard validation checks against real data, and handed me a diff with a one-line result per check.

It never opened a browser. Neither did I, until I approved the pull request.

For someone who came up the way I did, that's a strange sentence to write.

## A Decade of Click-Ops

I started on SQL Server: SSMS, SSIS packages you built by dragging boxes onto a canvas, SQL Agent jobs configured through dialog boxes. Then Azure arrived, and the canvas moved into the browser. Data Factory's pipeline designer. The Azure Portal and its endless blades. Synapse Studio. The Databricks workspace UI. And most recently Microsoft Fabric, which is web-first by design. Every generation of the Microsoft data stack I've worked on over the last nine-plus years pulled us further into the portal.

We called it low-code, and for a while it genuinely helped. Business analysts could read a pipeline. New engineers ramped faster. Certifications rewarded portal fluency, and I collected my share of them.

But it had a cost we stopped noticing: **our knowledge lived in clicks.** Runbooks read like treasure maps ("Storage account → Networking → Firewalls and virtual networks → Resource instances → Add"). Rebuilding an environment meant a person with screenshots and a free afternoon. The JSON behind the canvas was something you exported for CI/CD, not something you actually worked in.

AI agents flipped that in about eighteen months.

## Why Agents Prefer the Terminal

Agents *can* drive a browser. I've done it, and wrote about it in "The Quiet Takeover." But watching an agent use a portal is like watching someone navigate a city by photographing street signs: screenshot, guess, click, screenshot again. It works, slowly, until a blade loads half a second late. Put the same agent in a terminal and it types one command, reads exact text back, and moves on.

That isn't an accident. CLIs were built for scripts, and an agent is essentially a script with judgment. Here's why they fit together:

- **Text in, text out.** That's the agent's native medium. No pixels, no DOM, no guessing which button is "Save."
- **Structured output on demand.** `az ... -o json`, `databricks ... -o json`, and JMESPath `--query` filters mean the agent parses data instead of scraping it.
- **Composability.** Output from `databricks` pipes into `jq`, which feeds an `az` command, which feeds a `git` commit. Portals don't compose.
- **Self-documenting.** Every subcommand has `--help`. An agent can learn a tool it has never seen in the middle of a task.
- **Same identity, same permissions.** The CLI authenticates as *you*. Every RBAC role and Unity Catalog grant still applies. The agent can't do anything you couldn't.
- **An audit trail by default.** Every action is a command string in a transcript and a shell history. You can read it, diff it, replay it, and paste it into a ticket. A portal click leaves an activity-log entry if you're lucky.
- **Same commands in CI.** What the agent runs on my laptop is what the pipeline runs in Azure DevOps. No translation step.

A portal is built for a human with a mouse and patience. A CLI is built for a script. So the agent was always going to prefer the terminal. What surprised me was how much I'd come to prefer it too.

---

## The Four-Layer CLI Stack

This is the stack I work in every day. Each layer is useful on its own, and each one makes the layer above it safer and smarter. The agent at the top is only as good as the three layers underneath it.

```text
 Layer 4  AI agents     claude · codex · cursor-agent    (plans, chains, explains)
 Layer 3  databricks    Unity Catalog · SQL · jobs · bundles
 Layer 2  az            subscriptions · ADLS Gen2 · ADF · Key Vault
 Layer 1  git           branches · diffs · the safety net under everything
```

**Prerequisites**

- **Windows:** `winget` for installs, PowerShell to run installers, and **Git Bash** as the shell the agents actually work in. Install `jq` too (`winget install jqlang.jq`).
- **macOS:** Homebrew (`brew install jq`).
- **Behind a TLS-inspecting corporate proxy?** Half of these installs will fail with certificate errors on day one. Get your proxy's root CA from IT and point each tool at it (I'll show where as we go). Never "fix" it by turning certificate verification off. I'll admit I did exactly that once to get unblocked. It's the wrong habit to hand an agent.

### Layer 1 — Git and Git Bash: The Safety Net

Git is the least glamorous layer and the most important one. Nothing an agent writes is real until it shows up in a diff that a human has read.

**Install**

```bash
# Windows (PowerShell). Includes Git Bash and Git Credential Manager.
winget install --id Git.Git -e --source winget

# macOS
brew install git
```

**Configure**

On Windows, Git Credential Manager signs you in to Azure Repos with your work account, so there's no personal access token to create, rotate, or leak. If your proxy breaks HTTPS, use the Windows certificate store instead of disabling verification:

```bash
git config --global http.sslBackend schannel
```

The config change that mattered most for us was **folder-based identity**. One early surprise: a stray clone in a Downloads folder was committing work code under my personal Git identity. An agent commits as whoever the folder resolves to, so make the folder decide:

```ini
# ~/.gitconfig
[user]
    name  = Your Name
    email = you@personal.example
[includeIf "gitdir/i:C:/Users/<you>/repos/"]
    path = ~/.gitconfig-work
```

```ini
# ~/.gitconfig-work
[user]
    email = you@company.example
```

Every work repo lives under one `repos/` folder, one subfolder per project. Nothing lives in Downloads.

**Branching strategy**

- `main` is protected by an Azure DevOps branch policy: pull request required, build validation required. Nobody pushes to `main`, human or agent.
- Branches are small and single-purpose: `fix/…`, `feat/…`, `docs/…`, `chore/…`. In one recent week the agent and I shipped four branches in a deliberate merge order (a data fix, a CI change, a docs update, and a verification refactor) instead of one sprawling PR.
- **Worktrees for parallel work.** When an agent works on a branch, it gets its own folder, so my working copy is never disturbed:

```bash
git fetch origin
git worktree add ../ops-lakehouse-fix -b fix/sensor-baseline-total origin/main
# ...work happens in ../ops-lakehouse-fix...
git worktree remove ../ops-lakehouse-fix   # after merge
```

**Reviewing diffs: the safety net**

This is the ritual before anything an agent wrote gets committed:

```bash
git status
git diff --stat                 # how much changed? anything unexpected?
git diff -- src/ databricks.yml # read the parts that matter
git diff --cached               # what's actually staged
git log --oneline --graph -15
```

I always read `--stat` first. If a one-line fix touched fourteen files, I stop and ask why before reading a single hunk. That habit paid off when the Databricks VS Code extension silently rewrote our `pyproject.toml`: it pinned the Python version and added a dependency that conflicted with an existing one. No human or agent had asked for that change. It showed up in `git diff --stat`, and we reviewed it on its own branch instead of letting it ride along with a data fix.

**Keep AI config out of the shared repo**

Our committed project docs are tool-neutral: `CONTRIBUTING.md` for workflow and conventions, `docs/ARCHITECTURE.md` for business logic. They're written for human developers. Agent-specific files stay on my machine, excluded locally rather than through a committed `.gitignore`:

```bash
cat >> .git/info/exclude <<'EOF'
CLAUDE.md
.claude/settings.local.json
EOF
```

The repo stays meaningful to the project, and every developer, with or without an AI tool, reads the same source of truth.

### Layer 2 — Azure CLI: The Portal, Minus the Clicking

**Install**

```bash
# Windows (PowerShell)
winget install -e --id Microsoft.AzureCLI

# macOS
brew install azure-cli
```

Behind a proxy, point the CLI's Python runtime at your proxy's CA bundle with the `REQUESTS_CA_BUNDLE` environment variable.

**Sign in and set defaults**

```bash
az login                          # browser SSO with your work account
az login --use-device-code        # when the browser redirect is blocked

az account list -o table
az account set --subscription "sub-data-platform-dev"
az config set defaults.group=rg-data-dev defaults.location=eastus2

az account show --query "{subscription:name, user:user.name}" -o table
```

Setting a default subscription and resource group isn't just convenient. It means an agent's command lands in dev unless someone explicitly says otherwise. Defaults are guardrails.

Data Factory commands live in an extension:

```bash
az extension add --name datafactory
```

**Real command patterns**

*What landed in the lake today?* (Entra identity, no account keys)

```bash
az storage fs file list \
  --account-name stdatalakedev01 --file-system raw \
  --path "vendor_feed/2026/10/22" --auth-mode login \
  --query "[].{name:name, bytes:contentLength, modified:lastModified}" -o table
```

*Which pipelines failed overnight, and why?*

```bash
az datafactory pipeline-run query-by-factory \
  --factory-name adf-ingest-dev \
  --last-updated-after  "2026-10-22T00:00:00Z" \
  --last-updated-before "2026-10-23T00:00:00Z" \
  --filters operand="Status" operator="Equals" values="Failed" \
  --query "value[].{pipeline:pipelineName, runId:runId, start:runStart}" -o table

az datafactory activity-run query-by-pipeline-run \
  --factory-name adf-ingest-dev --run-id <run-id> \
  --last-updated-after  "2026-10-22T00:00:00Z" \
  --last-updated-before "2026-10-23T00:00:00Z" \
  --query "value[?status=='Failed'].{activity:activityName, error:error.message}" -o table
```

*What's in the Key Vault?* Names and metadata only. Never values.

```bash
az keyvault secret list --vault-name kv-data-dev \
  --query "[].{name:name, enabled:attributes.enabled, expires:attributes.expires}" -o table
```

`az keyvault secret show` is on my agent's deny list (more on that in Layer 4). An agent should know a secret *exists* and *when it expires*. It should never see what it *is*.

*Is it RBAC or the firewall?*

```bash
az storage account show -n stdatalakedev01 \
  --query "networkRuleSet.{default:defaultAction, resourceRules:resourceAccessRules}" -o json

az role assignment list --assignee <principal-id> --all \
  --query "[].{role:roleDefinitionName, scope:scope}" -o table
```

**A lesson from the CLI that the portal never taught me.** When I deployed a small chat bot to App Service, `az webapp up` kept failing. The error named the exact permission my account lacked (write access on the App Service plan), which I was never going to get. Zip deploy only needed rights on the web app itself:

```bash
az webapp config appsettings set -n app-chatbot-dev --settings PORT=8000 WEBSITES_PORT=8000
az webapp deployment source config-zip -n app-chatbot-dev --src bot.zip
az webapp restart -n app-chatbot-dev
az webapp log tail -n app-chatbot-dev
```

(Newer CLI versions also offer `az webapp deploy --type zip`.) The port settings came from another CLI-visible failure: the app listened on one port while App Service probed another, and the log tail showed it plainly. Text errors are diagnosable. Spinning portal blades are not.

### Layer 3 — Databricks CLI: Real Data Context for the Agent

**Install**

```bash
# Windows (PowerShell)
winget install Databricks.DatabricksCLI

# macOS
brew tap databricks/tap
brew install databricks

databricks --version
```

Make sure you're on the current CLI, not the legacy `databricks-cli` pip package. And make sure there's only *one* copy on your PATH. We once had two installs, and PowerShell and Git Bash resolved to different versions. Bundle features worked in one shell and failed in the other. `where.exe databricks` on Windows (or `which -a databricks`) settles it in seconds.

**OAuth profiles (`~/.databrickscfg`)**

We run two unrelated Databricks workspaces. I'm admin on both, and each hosts **both dev and prod, separated by Unity Catalog catalogs rather than by workspace**. The mental model that made everything click:

> **Workspace = project. Catalog = environment.**

So each repo uses exactly one CLI profile, forever. Dev versus prod is a bundle target and a catalog, never a different login.

```bash
databricks auth login --host https://adb-1111111111111111.1.azuredatabricks.net --profile OPS
databricks auth login --host https://adb-2222222222222222.2.azuredatabricks.net --profile FIN

databricks auth profiles            # both should show Valid: YES
databricks current-user me -p OPS
```

The resulting config holds no long-lived secret:

```ini
# ~/.databrickscfg
[OPS]
host      = https://adb-1111111111111111.1.azuredatabricks.net
auth_type = databricks-cli

[FIN]
host      = https://adb-2222222222222222.2.azuredatabricks.net
auth_type = databricks-cli
```

Notice there's **no `[DEFAULT]` profile.** That's deliberate. We used to have one, holding a personal access token. Removing it means a command without a profile *fails* instead of quietly hitting whichever workspace DEFAULT happened to point at. Failing loudly is a feature when an agent is typing.

Here's the environment map every agent working in our repos knows:

| Workspace | CLI profile | Dev (writable) | Prod (read-only for humans) | Off-limits |
|---|---|---|---|---|
| Operations analytics | `OPS` | `ops_dev`, `sandbox` | `ops_prd` | `legacy_default` |
| Finance data warehouse | `FIN` | `fin_dev` | `fin_prd` | `shared_analytics` |

One trap worth naming: our operations workspace has a legacy *default catalog*. Any unqualified table name lands there. Our rule is simple: fully qualified `catalog.schema.table`, always.

**Give the agent real data context: Unity Catalog metadata**

This is the single biggest quality upgrade for agent-written SQL and PySpark. Instead of guessing that a column is called `customer_id`, the agent looks it up and learns it's `cust_key`, a `BIGINT`, with a comment explaining the business meaning.

```bash
databricks catalogs list -p OPS -o json | jq -r '.[].name'

databricks schemas list ops_dev -p OPS -o json | jq -r '.[].full_name'

databricks tables list ops_dev gold -p OPS -o json \
  | jq -r '.[] | "\(.name)\t\(.table_type)"'

databricks tables get ops_dev.gold.fact_daily_counts -p OPS -o json \
  | jq '{owner, comment, columns: [.columns[] | {name, type_text, comment}]}'
```

Those column comments matter more now than they ever did. Every hour we spent documenting tables for Databricks Genie paid off a second time when coding agents started reading the same metadata.

**Run SQL from the terminal**

The CLI exposes the SQL Statement Execution API directly:

```bash
databricks warehouses list -p OPS -o json | jq -r '.[] | "\(.id)\t\(.name)\t\(.state)"'

databricks api post /api/2.0/sql/statements -p OPS --json '{
  "warehouse_id": "<warehouse-id>",
  "statement": "SELECT event_date, SUM(entries) AS entries FROM ops_dev.gold.fact_daily_counts WHERE event_date >= current_date() - 7 GROUP BY event_date ORDER BY event_date",
  "wait_timeout": "30s"
}' | jq '{state: .status.state, rows: .result.data_array}'
```

Our standing rule: agents query **aggregates, counts, and metadata**, not raw rows. They need to know whether a total reconciles, not whose record is on line 4,012.

**Jobs**

```bash
databricks jobs list -p OPS -o json | jq -r '.[] | "\(.job_id)\t\(.settings.name)"'

databricks jobs list-runs --job-id <job-id> --limit 5 -p OPS -o json \
  | jq -r '.[] | "\(.run_id)\t\(.state.result_state)\t\(.start_time)"'

databricks jobs get-run <run-id> -p OPS -o json \
  | jq '.tasks[] | {task_key, run_id, result: .state.result_state}'

# For multi-task jobs, pass the *task* run_id from the previous command
databricks jobs get-run-output <task-run-id> -p OPS -o json | jq '{error, error_trace}'
```

**Deploy with Databricks Asset Bundles**

Bundles are where the CLI goes from "handy" to "the way we ship." Here's the shape of our `databricks.yml`:

```yaml
bundle:
  name: ops-analytics-lakehouse

include:
  - resources/*.yml

variables:
  catalog:
    description: Unity Catalog catalog this target writes to

targets:
  dev:
    mode: development
    default: true
    workspace:
      host: https://adb-1111111111111111.1.azuredatabricks.net
    variables:
      catalog: ops_dev

  prod:
    mode: production
    workspace:
      host: https://adb-1111111111111111.1.azuredatabricks.net
    run_as:
      service_principal_name: <prod-deployer-sp-application-id>
    variables:
      catalog: ops_prd
```

Two details are worth calling out:

1. **Same host, different catalog.** Dev and prod differ by a catalog variable, which matches the "catalog = environment" model.
2. **No `profile:` lines.** We added them once, then removed them. Profile names are personal (a teammate might call theirs something else), and CI authenticates without one. When a target only sets `host`, the CLI picks the local profile that matches that host.

Job scripts receive the catalog as a parameter, so the same code runs in either environment:

```yaml
# resources/nightly_refresh.yml
resources:
  jobs:
    nightly_refresh:
      name: nightly_refresh
      tasks:
        - task_key: bronze_to_gold
          spark_python_task:
            python_file: ../jobs/run_pipeline.py
            parameters: ["--catalog", "${var.catalog}"]
          environment_key: default
      environments:
        - environment_key: default
          spec:
            client: "3"
```

The day-to-day loop:

```bash
databricks bundle validate -t dev
databricks bundle summary  -t dev    # what will deploy, with what names, where
databricks bundle deploy   -t dev
databricks bundle run      -t dev nightly_refresh
```

Always pass `-t`, even for dev. In `mode: development`, resource names get a per-user prefix and schedules are paused, so an agent deploying to dev can't trample a teammate's jobs. **Prod is never deployed from a laptop.** It ships from the pipeline, as the service principal, after a merged PR:

```yaml
# azure-pipelines.yml (excerpt; wired to main's branch policy as build validation)
steps:
  - script: pip install -r requirements-dev.txt && pytest -q -m "not e2e"
    displayName: Unit tests
  - script: databricks bundle validate -t prod
    displayName: Validate bundle
  # The prod deploy stage runs only on main, authenticated as the deployer service principal
```

### Layer 4 — The AI Agents: Claude Code, Codex CLI, and Cursor

**Install**

```bash
# Claude Code: native installer (recommended)
curl -fsSL https://claude.ai/install.sh | bash        # macOS / Linux / WSL
irm https://claude.ai/install.ps1 | iex               # Windows PowerShell
# or: brew install --cask claude-code   /   winget install Anthropic.ClaudeCode
claude --version
claude                                                # run inside a repo, sign in on first launch

# Codex CLI
npm install -g @openai/codex                          # any OS with Node.js
brew install --cask codex                             # macOS
codex                                                 # choose "Sign in with ChatGPT"

# Cursor: install the editor from cursor.com, plus its terminal agent
curl https://cursor.com/install -fsS | bash           # macOS / Linux / WSL
brew install --cask cursor-cli                        # or, on macOS
cursor-agent
```

On native Windows, install Git for Windows first so Claude Code has a Bash shell to work in. Behind a TLS-inspecting proxy, Node-based tools need `NODE_EXTRA_CA_CERTS` pointing at your proxy's root certificate. That one setting was the difference between Claude Code half-working and fully working on my corporate laptop.

**How `CLAUDE.md` guides the agent**

Claude Code reads instruction files at the start of every session. We use three layers:

| File | Scope | What's in it |
|---|---|---|
| `~/.claude/CLAUDE.md` | Every project on my machine | Who I am, the two workspaces, universal rules |
| `<repo>/CLAUDE.md` | One repo (local only, excluded from git) | Imports the committed docs, plus this repo's workspace, catalogs, and prod rules |
| `<repo>/.claude/settings.local.json` | One repo (local only) | Enforcement: forced CLI profile and command permission rules |

The global file (sanitized, but this is the real shape):

```markdown
# ~/.claude/CLAUDE.md

## Context
Lead data engineer. Azure, Databricks, Unity Catalog, Power BI. Python first.
Notebooks are .ipynb with outputs stripped; library code, tests, and job scripts stay .py.

## Databricks workspaces
Two workspaces for unrelated projects: OPS and FIN.
Each holds dev AND prod, separated by Unity Catalog catalogs.
Each repo's CLAUDE.md says which workspace it uses. If it doesn't, ask before
running any databricks command.

## Always
- Pass -t explicitly on every bundle command.
- Use fully qualified catalog.schema.table names. Never rely on a default catalog.
- Read before you write: metadata, counts, and aggregates first. Propose any change
  that alters state, and wait for my approval.
- Work on a feature branch. Show `git diff --stat` and the diff before any commit.

## Never
- Deploy, run jobs, or write data to a prod target or prod catalog unless my
  current message says "prod".
- Commit to main, push, or open or merge PRs without my approval.
- Print tokens, secrets, Key Vault values, or raw data rows.
- Edit ~/.databrickscfg, run auth login, or disable TLS verification.
```

The repo-level file is short, because the real knowledge lives in the committed, tool-neutral docs:

```markdown
# CLAUDE.md (local only, listed in .git/info/exclude)
@CONTRIBUTING.md
@docs/ARCHITECTURE.md

## This repo
Workspace OPS (CLI profile OPS). Dev: ops_dev, sandbox. Prod: ops_prd (read-only).
Never write to legacy_default.
Dev deploys are approved: `databricks bundle deploy -t dev` and dev job runs are fine.
Before deploying, confirm the dev target writes only to ops_dev and show the name prefix.
Prod ships only through the pipeline.
Tests: `pytest -q -m "not e2e"` locally; end-to-end verification runs in dev.
```

And the enforcement file. Instructions are a request; this is a rule:

```json
{
  "env": {
    "DATABRICKS_CONFIG_PROFILE": "OPS"
  },
  "permissions": {
    "allow": [
      "Bash(git status)",
      "Bash(git diff *)",
      "Bash(git log *)",
      "Bash(databricks catalogs list *)",
      "Bash(databricks schemas list *)",
      "Bash(databricks tables get *)",
      "Bash(databricks bundle validate -t dev)",
      "Bash(databricks bundle deploy -t dev)"
    ],
    "ask": [
      "Bash(git push *)",
      "Bash(databricks api post *)",
      "Bash(databricks bundle run *)"
    ],
    "deny": [
      "Bash(databricks bundle deploy -t prod*)",
      "Bash(databricks bundle deploy --target prod*)",
      "Bash(databricks bundle run -t prod*)",
      "Bash(databricks bundle destroy *)",
      "Bash(az keyvault secret show *)",
      "Bash(git push --force*)",
      "Read(~/.databrickscfg)"
    ]
  }
}
```

Claude Code evaluates deny first, then ask, then allow, and deny rules hold in every permission mode. The `env` block means every `databricks` command the agent runs in this repo uses the right workspace, even if it forgets to pass `-p`. Be honest with yourself about what pattern rules are, though: a determined command can be phrased in ways a pattern doesn't anticipate. They're a seatbelt, not a wall. The wall is Unity Catalog permissions and a prod that only a service principal can touch (more on that below).

**Codex and Cursor get the same rules**

Codex and Cursor both read `AGENTS.md` (Cursor also has its own project rules in `.cursor/rules/`). Keep that file short and point it at the same `CONTRIBUTING.md`, so three tools don't end up with three versions of the truth. Codex's guardrails live in its config file:

```toml
# ~/.codex/config.toml
approval_policy = "on-request"       # ask before stepping outside the sandbox
sandbox_mode    = "workspace-write"  # edits stay inside the repo
```

**Terminal CLI or VS Code extension?**

Same engine, same `CLAUDE.md`, same permissions, so the choice comes down to how the task ends.

- **Terminal** when the work crosses tools (`git` → `databricks` → `az`), runs long, needs its own worktree, or runs headless (`claude -p "..."`, `codex exec "..."`). I can also approve a waiting prompt from my phone, which is how a long dev validation run keeps going while I'm in a meeting.
- **Editor** (the VS Code extension, or Cursor) when I want to read along: inline diffs, a careful refactor of one module, notebook work where I want rendered `.ipynb` cells, or anything where I'm going to make judgment calls hunk by hunk.

My rule of thumb: **if the task ends in a deploy, it starts in the terminal. If it ends with me reading code, it starts in the editor.**

**Which agent for what**

On work repos, Claude Code is my primary: planning, cross-tool chains, and anything that touches Databricks. On a personal side project (a multi-ERP finance lakehouse), I run three agents as parallel "seats" against one repo:

- Each seat works in its own git worktree, so nobody steps on anybody.
- Each gets a task card with the same headings: *Goal / Allowed paths / Do not modify / Tasks / Acceptance criteria / Deliverables*.
- Shared conventions live in an `AGENTS.md` (which Codex and Cursor both pick up) and in a `contracts/` folder that's the source of truth.
- **Seats never talk to each other.** Every output comes back to me as a pull request, and I adjudicate before anything merges.
- Cross-review goes to a *different* model family than the one that wrote the code. Same-family review tends to approve the same blind spots.

## Three Workflows From Real Work

Here's what it looks like when one prompt chains all three layers below the agent.

### Workflow 1 — The Agent Sets Up Its Own Guardrails

The first real job I gave Claude Code wasn't writing code. It was setting up the environment it would work in. Condensed, the prompt looked like this:

```text
Set up this repo for our Databricks workspaces. Back up any file before editing.

Context: two workspaces (OPS, FIN) for unrelated projects. Each holds dev AND prod,
separated by catalogs. This repo belongs to OPS. OAuth profiles already exist.

1. Run `databricks auth profiles`. Confirm both are valid and show their hosts.
2. Inspect databricks.yml. Don't rewrite it. List every catalog name referenced in
   code and config, and ask me which are dev and which are prod.
3. Merge a Databricks section into CLAUDE.md: workspace, profile, catalogs, prod rules.
4. Create .claude/settings.local.json: DATABRICKS_CONFIG_PROFILE=OPS, plus rules so
   any prod deploy or run needs my approval. Exclude it via .git/info/exclude.
5. Verify `databricks bundle validate -t dev` passes.

Rules: no deploys, no job runs, no writes, no SQL that changes anything.
Don't edit ~/.databrickscfg. Don't commit or push without asking. Never print tokens.
```

It chained `databricks auth profiles`, a full-text search of the repo, `git status`, and `bundle validate`, and it stopped exactly where I told it to: at the catalog list, asking me to label each one. That labeling step is the one thing it had to judge by name, and a wrong label is what could let a prod write through, so it belonged to me.

The config wasn't even the most valuable output. Along the way it surfaced:

- One repo whose notebooks wrote **directly to prod catalogs** through hard-coded catalog constants, with no dev path at all. The agent's rule became "never run these." Fixing the design became its own project.
- The VS Code extension rewrite of `pyproject.toml` I mentioned earlier.
- A duplicate clone pointing at a different remote than our source of truth.

Then came the follow-on: retiring the old personal access token. Revoking a token breaks *everything* that uses it, everywhere, instantly, so the audit comes first and revocation comes last. The audit is a cross-tool chain that reads names and metadata only:

```bash
# Where might the old token still be used? Names only, never values.
git grep -n -i "DATABRICKS_TOKEN" -- . ':!*.md'

az keyvault secret list --vault-name kv-data-dev \
  --query "[?contains(name, 'databricks')].name" -o tsv

az datafactory linked-service list --factory-name adf-ingest-dev \
  --query "[?properties.type=='AzureDatabricks'].name" -o tsv

databricks token-management list -p OPS -o json \
  | jq -r '.[] | "\(.token_id)\t\(.created_by_username)\t\(.comment)"'
```

One thing the CLI made clear: "last used" lives in the audit system tables, and querying those needs account- or metastore-level grants. Being workspace admin isn't enough. Knowing that up front saved a week of "why can't I see it?"

### Workflow 2 — From a Wrong Number to a Reviewed Pull Request

Back to the number from the opening. A hard-coded reconciliation total in our ingestion code didn't match the figure our validation job and the published dashboard used. The prompt, condensed:

```text
The baseline total in our reconciliation module doesn't match the figure the
validation job and the published dashboard use. Fix it on its own branch.

1. Find where the constant is defined, and check whether any deployed job imports
   that module. If none does, say so: a dev deploy won't exercise this fix.
2. Run the non-e2e tests locally, and give me the exact command.
3. Dev testing is approved. Before deploying, show the deployment mode and name
   prefix, and confirm the dev target writes only to ops_dev. Then run the nightly
   job and the validation job.
4. Report pass/fail per check. If a check fails on real data, report it. Don't
   change the check or the data.
5. Show me `git diff --stat` and the full diff. Push only after I approve.

Never -t prod. Never print data rows.
```

And the chain it ran across two of those branches:

```bash
# Branch 1: the fix
git fetch origin
git worktree add ../ops-lakehouse-fix -b fix/sensor-baseline-total origin/main
cd ../ops-lakehouse-fix
git grep -n "SENSOR_BASELINE_TOTAL"                 # defined in one module...
git grep -n "reconcile" -- jobs/ resources/         # ...imported by no deployed job
pytest -q -m "not e2e"                              # fast local tests; e2e runs in dev
git diff --stat origin/main...                      # I read it and approve. Only then:
git push -u origin fix/sensor-baseline-total

# Branch 2: harden the checks, then prove them on real dev data
git worktree add ../ops-lakehouse-verify -b chore/consolidate-verification origin/main
cd ../ops-lakehouse-verify
databricks bundle validate -t dev
databricks bundle summary  -t dev                   # dev prefix, ops_dev only
databricks bundle deploy   -t dev
databricks bundle run      -t dev nightly_refresh
databricks bundle run      -t dev validate_run
git diff --stat origin/main...
```

The part that earned my trust was what the agent *said*, not what it typed:

- **It told me when its own test wouldn't prove anything.** The dev job didn't import the module containing the constant, so a dev deploy couldn't exercise the fix. It verified the fix with a small standalone check instead and said so explicitly.
- **It hardened the checks before trusting them.** On the follow-up branch we added two hard checks: no sensor maps to two locations, and each device has at most one sensor. We also added a check that compares non-null raw counts against non-null counts after the type cast, to prove no records were silently lost.
- **It reported per check, on real dev data.** Every hard check passed, and the parity check matched the published total exactly.
- **It escalated what it couldn't decide.** It flagged 84 date-and-location windows overlapping known equipment-replacement periods. During those windows, sensor counts are inflated by construction crews while the comparison counts are structurally zero. No model knew that. An operations colleague did. It also noticed a sanity check that still passed at a nonsensical negative rate, and that quarantine tables kept growing across dev runs. Both became human decisions, not silent "fixes."

Four small branches, merged in a deliberate order through Azure DevOps PRs. I touched the browser once per PR, to approve.

### Workflow 3 — The 403 That Wasn't a Permissions Problem

Creating a Unity Catalog volume failed with an `AbfsRestOperationException` and an empty message. That's the classic signature of a swallowed 403 from ADLS. I first worked this one out in a chat window, pasting error text back and forth. In hindsight, it's the perfect CLI agent task, because every diagnostic step is a read. Today I'd hand it a prompt like this:

```text
Creating a volume in ops_dev.vendor_raw fails with an empty AbfsRestOperationException.
Diagnose it. Read-only: change nothing in Databricks or Azure.

1. Find the storage location behind the schema, the external location that covers
   it, and the managed identity behind its storage credential.
2. Resolve that identity in Azure. List its role assignments and the storage
   account's network rules.
3. Tell me whether this is RBAC or the firewall, and show the evidence.
4. Write up the fix for the cloud team: the exact firewall rule and roles to add.
   Put the diagnosis in docs/runbooks/storage-access.md on a docs branch, and show
   me the diff before committing.
```

The chain behind it:

```bash
# 1. Where does the write actually land, and as which identity?
databricks schemas get ops_dev.vendor_raw -p OPS -o json | jq '{storage_root, storage_location}'
databricks external-locations list -p OPS -o json \
  | jq -r '.[] | "\(.name)\t\(.url)\t\(.credential_name)"'
databricks storage-credentials get <credential-name> -p OPS -o json | jq '.azure_managed_identity'

# 2. Resolve the access connector's managed identity
az resource show --ids <access-connector-resource-id> --query identity.principalId -o tsv

# 3. Network or RBAC?
az storage account show -n stvendordev01 \
  --query "networkRuleSet.{default:defaultAction, resources:resourceAccessRules}" -o json
az role assignment list --assignee <principal-id> --all \
  --query "[].{role:roleDefinitionName, scope:scope}" -o table
az provider show -n Microsoft.EventGrid --query registrationState -o tsv

# 4. Leave the next person a runbook, not a chat history
git switch -c docs/storage-access-runbook
git add docs/runbooks/storage-access.md
git diff --cached                    # I review; it commits only after I approve
```

The insight hides in the error code. `AuthorizationPermissionMismatch` means RBAC: the identity lacks a role. `AuthorizationFailure` means the storage **firewall** rejected the request before roles were ever evaluated. Ours was the second. The fix was a resource-instance rule for the Databricks access connector on the storage account's firewall. The "allow trusted Azure services" checkbox doesn't cover it. File-event notifications needed a few more roles at account scope, plus the Event Grid resource provider registered.

The agent couldn't apply that fix, and shouldn't have. The storage account belongs to our cloud team. What it can do is collect the evidence, name the exact rule and roles, and draft the ticket. That turns a multi-day back-and-forth into a single, precise request.

## Your Afternoon Setup Checklist

1. Install `git`, `az`, `databricks`, `jq`, and one AI CLI. Confirm one copy of each on PATH.
2. Fix proxy certificates the right way: schannel for git, `REQUESTS_CA_BUNDLE` for `az`, `NODE_EXTRA_CA_CERTS` for Node-based agents.
3. Move every repo under one `repos/` folder and set folder-based git identity.
4. Create OAuth Databricks profiles and delete the token-based `DEFAULT`.
5. Set `az` defaults to your dev subscription and resource group.
6. Write `~/.claude/CLAUDE.md` with your always/never rules.
7. In each repo, write a local `CLAUDE.md` and `settings.local.json`, and exclude both.
8. Ask the agent to verify the setup: `databricks auth profiles`, `az account show`, `databricks bundle validate -t dev`. Read-only.

---

## We Don't Have a Model Capability Problem Anymore

Here's my honest read after a year of doing this inside a large, regulated organization: the models stopped being the bottleneck a while ago.

Look back at the workflows above: reading a schema, writing SQL against real metadata, chaining three CLIs, reading a diff, knowing when to stop and ask. All of it was within reach of the models from two versions ago. The newer ones are faster, more careful, and better at long tasks. But capability isn't what's holding enterprises back. Most organizations are using a small fraction of what these tools could already do.

What holds them back is permission, plumbing, and policy:

- CLI agents blocked by endpoint protection before they ever run a command.
- TLS-inspecting proxies that break every installer, with no documented fix.
- No sanctioned way to sign in, so engineers fall back to personal tokens.
- Blanket "no AI in the terminal" policies written because nobody could explain what the agent would be allowed to touch.

I understand every one of those fears. An agent acting with your identity *can* do anything you can. Credentials *do* leak. Prod writes *are* catastrophic. Caution is necessary.

**Slow adoption is not.** Gatekeeping doesn't stop people from using AI. It just moves the usage somewhere you can't see it. We recently inherited an operations app a team had built with a consumer AI tool on a hosted stack. Security blocked it from going live, and rightly so. It came to us to rebuild on the governed platform. That's shadow IT, and it's what "no" produces. The better answer is "yes, inside these rails."

## Guardrails Over Gatekeeping

Here are the rails that make CLI agents safe in our environment:

| The fear | The guardrail |
|---|---|
| "It'll write to prod." | Humans have **read-only** access to prod catalogs. Only a deployer service principal can write, and it only runs from CI after a merged PR. The agent inherits *your* identity, so if you can't write prod, neither can it. |
| "It'll see data it shouldn't." | **Unity Catalog** grants are the real boundary. Agents work against dev and sandbox catalogs, and see prod as metadata. |
| "It'll deploy something unreviewed." | `main` is protected: PR required, build validation required. Prod deploys come only from the pipeline. |
| "It'll leak secrets." | OAuth profiles instead of tokens. Key Vault names, never values. `secret show` and the CLI config file are on the deny list. |
| "It'll do something we didn't intend." | `CLAUDE.md` encodes the team's tribal knowledge as explicit always/never rules. **Command approval prompts** (allow, ask, deny) gate anything that changes state. |
| "We can't audit it." | Every action is a command in a transcript, a commit in git, a run in the jobs history, and a query in the warehouse history. CLI work is *more* auditable than portal work, not less. |

The Unity Catalog piece, concretely:

```sql
-- Engineers (and the agents acting as them): browse and read prod, never write
GRANT BROWSE ON CATALOG ops_prd TO `data-engineers`;
GRANT USE CATALOG, USE SCHEMA, SELECT ON CATALOG ops_prd TO `data-engineers`;

-- Full rights in dev
GRANT USE CATALOG, USE SCHEMA, SELECT, MODIFY, CREATE TABLE ON CATALOG ops_dev TO `data-engineers`;

-- Only the deployer service principal can change prod
GRANT USE CATALOG, USE SCHEMA, SELECT, MODIFY, CREATE TABLE
  ON CATALOG ops_prd TO `<prod-deployer-sp-application-id>`;
```

One story convinced me the identity layer matters more than any prompt. While investigating an automated report nobody could explain, I found in query history that it was running as *me*. A personal access token I'd shared "just for testing" had quietly become production plumbing. No agent was involved, and that's precisely the point. The risk was never the AI. It was unscoped credentials. The fix was a service principal with `SELECT` on exactly one view, plus OAuth for everything else. Do that, and an agent in the terminal is the *least* risky actor in the room, because everything it does is written down.

If you're the engineer trying to get this approved, here's what to ask your security team for. It's a much easier conversation than "please unblock AI":

1. A sanctioned install path for one AI CLI, and an egress allowlist for its model endpoint.
2. An enterprise plan with clear data-retention and no-training terms.
3. The proxy's root CA, documented for git, Python, and Node tools.
4. A sandbox catalog and a dev subscription where agents can write.
5. A service principal for prod deploys, so no human (or agent) needs prod write access.

Guardrails over gatekeeping. Ship the rails, then let people move fast on them.

---

## What I Still Don't Hand to the Agent

Let me be clear about what I *don't* hand to the agent.

**Architecture is mine.** "Workspace = project, catalog = environment" was a human decision. So was keeping prod deploys off laptops, and so was the four-branch merge order. Agents are excellent inside a structure. They're not yet the ones who should choose it.

**Business logic is mine, and my colleagues'.** The agent found 84 suspicious windows in a few minutes. It couldn't know that equipment replacement inflates sensor counts while the comparison counts drop to zero. Someone who has walked that site during a replacement knows. The agent's job was to surface it with evidence. A human with the maintenance records closes it.

**Sign-off is mine.** Every merge to `main` passes through a person reading a diff. That's not ceremony. It's the moment someone accountable says "yes, this is what we meant."

So the human stays in the loop. But I'd be dishonest if I stopped there, because the loop itself is getting smaller.

## So What Happens to the Team?

Look at what one engineer wired into these four CLIs carried over the past couple of months:

- Two unrelated workspaces re-platformed onto OAuth and bundles
- CI cleanup
- A validation framework running against real data
- Token retirement
- A storage firewall diagnosis
- The usual stream of department requests

A few years ago, that portfolio meant a platform engineer, two or three data engineers, someone on testing, and someone on DevOps. Right now I'm scoping an app migration where the staffing plan has one name on it at 100%. Mine.

That raises the question I keep circling without a clean answer: **if one engineer with a terminal can deliver what used to take a squad, do we still need the squad?**

The optimistic case is real. When delivery gets cheaper, demand usually grows. Every department I work with has a backlog of "we'd love a dashboard for that" requests that never cleared the cost bar, and plenty of them will clear it now. More data work might mean more data engineers, just doing a different kind of work.

The pessimistic case is also real. In a lot of organizations, mine included, budgets don't grow just because delivery got cheaper. The same work done with fewer people is the more likely outcome than more work done by the same people. And the tasks agents absorb first (boilerplate pipelines, test scaffolding, "run this and tell me if it passed") are exactly the tasks junior engineers used to learn on. If the bottom rung of the ladder disappears, where do the next leads come from?

I don't know which way it breaks. My guess is that a data engineering team a year from now is smaller, more senior, and heavier on platform, governance, and domain knowledge. Fewer people writing transforms, more people deciding what's true, what's allowed, and what ships. But that's a guess, and I'd rather say so than pretend otherwise.

What I do know is this: the terminal didn't win because it's nostalgic. It won because it's the one interface that both the agent and I can read.

I don't know what my team looks like in October 2027. I'm fairly sure which window it will be working in.

---

*If you're wiring agents into an enterprise data stack, or arguing with your security team about it, I'd love to compare notes. Drop a comment or reach out on [LinkedIn](https://www.linkedin.com/in/saikrishna-poluri/). And if you think I'm wrong about the team-size question, I especially want to hear from you.*
