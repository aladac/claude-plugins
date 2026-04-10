---
name: Cloudflare
description: |
  Cloudflare infrastructure management — zones, DNS, tunnels, Pages, Workers. Call cf.sh with all arguments directly. Use for DNS records, tunnel creation (local and remote), static site deployment, and serverless workers.

  <example>
  Context: User wants to list DNS records
  user: "show me DNS records for saiden.dev"
  </example>

  <example>
  Context: User wants to expose a local service
  user: "expose port 3000 as app.saiden.dev"
  </example>

  <example>
  Context: User wants to create a tunnel on junkpile
  user: "tunnel port 8080 on junkpile to api.tengu.to"
  </example>

  <example>
  Context: User wants to deploy to Pages
  user: "deploy this to Cloudflare Pages"
  </example>
version: 2.0.0
---

# Cloudflare Skill

Unified CLI for all Cloudflare operations via `cf.sh`. Each module uses a specific CLI tool -- never curl or the CF API directly.

## CLI Tool Assignments

| Tool | Modules | Installed On | Auth |
|------|---------|--------------|------|
| **flarectl** | zones, dns | fuji + junkpile (Homebrew) | `CF_API_KEY` + `CF_API_EMAIL` env vars |
| **cloudflared** | tunnels | fuji (Homebrew) + junkpile (`/usr/local/bin/cloudflared`) | `~/.cloudflared/cert.pem` |
| **wrangler** | pages, workers | fuji (Homebrew) | `CLOUDFLARE_ACCOUNT_ID` env var |

**Do NOT use curl, the CF REST API, or python3 for any operation.** Use the CLI tools above.

## Quick Reference

```bash
CF="$HOME/Projects/personality-plugin/skills/cloudflare/cf.sh"
CHECK="$HOME/Projects/personality-plugin/skills/cloudflare/cf-check.sh"

# ── Check ──
bash $CHECK              # Verify setup on both fuji + junkpile
bash $CHECK local        # Fuji only
bash $CHECK remote       # Junkpile only

# ── Auth ──
bash $CF auth setup              # Interactive credential setup
bash $CF auth test               # Verify credentials (uses flarectl)
bash $CF auth show               # Show stored credentials

# ── Zones (flarectl) ──
bash $CF zones list              # List all zones
bash $CF zones info saiden.dev   # Zone details

# ── DNS (flarectl) ──
bash $CF dns list saiden.dev                                   # All records
bash $CF dns add saiden.dev A app 192.168.1.1 true             # A record, proxied
bash $CF dns add saiden.dev CNAME www saiden.dev true           # CNAME, proxied
bash $CF dns add saiden.dev TXT @ "v=spf1 include:_spf..."     # TXT record
bash $CF dns find saiden.dev app                                # Find record by name
bash $CF dns del saiden.dev <record-id>                         # Delete by ID

# ── Tunnels (cloudflared) ──
bash $CF tunnels list                                          # List local tunnels
bash $CF tunnels list junkpile                                 # List tunnels on junkpile
bash $CF tunnels info my-tunnel                                # Tunnel details
bash $CF tunnels create my-tunnel                              # Create on local
bash $CF tunnels create my-tunnel junkpile                     # Create on junkpile
bash $CF tunnels route my-tunnel app.saiden.dev                # Route DNS
bash $CF tunnels config junkpile                               # Show junkpile tunnel config
bash $CF tunnels run my-tunnel                                 # Run tunnel

# Quick expose (creates tunnel + routes DNS in one step)
bash $CF tunnels expose 3000 app.saiden.dev                    # localhost:3000 -> hostname
bash $CF tunnels expose 8080 api.saiden.dev my-api             # with custom tunnel name
bash $CF tunnels expose 3000 app.saiden.dev '' junkpile        # on junkpile

# Remote expose (creates tunnel on remote host)
bash $CF tunnels expose-ssh junkpile 8080 api.saiden.dev       # junkpile:8080 -> hostname
bash $CF tunnels expose-ssh junkpile 3000 app.tengu.to my-app # with custom name

# Ingress management
bash $CF tunnels ingress-add app.saiden.dev http://localhost:3000 junkpile  # Add to config

# ── Pages (wrangler) ──
bash $CF pages list                                            # List projects
bash $CF pages deploy ./dist my-site                           # Deploy (branch: main)
bash $CF pages deploy ./build my-site production               # Deploy specific branch
bash $CF pages destroy old-site                                # Delete project

# ── Workers (wrangler) ──
bash $CF workers list                                          # List all workers
bash $CF workers info my-worker                                # Worker details
bash $CF workers deploy                                        # Deploy from current dir
bash $CF workers deploy ./worker-dir                           # Deploy from path
bash $CF workers dev                                           # Local dev server
bash $CF workers tail my-worker                                # Stream logs
bash $CF workers delete my-worker                              # Delete worker
```

## Command Reference

### Check (cf-check.sh)
| Command | Purpose |
|---------|---------|
| `cf-check.sh` | Verify tools, credentials, tunnels, API on both machines |
| `cf-check.sh local` | Check fuji only (also accepts `fuji`, `f`) |
| `cf-check.sh remote` | Check junkpile only (also accepts `junkpile`, `j`) |

### Auth
| Command | Purpose |
|---------|---------|
| `auth setup` | Interactive setup, saves to `~/.config/cloudflare/credentials` |
| `auth test` | Verify credentials work (uses `flarectl user info`) |
| `auth show` | Display stored credential info (masked key) |

### Zones (flarectl)
| Command | Purpose |
|---------|---------|
| `zones list` | List all zones via `flarectl zone list` |
| `zones info <domain>` | Zone details via `flarectl zone info --zone <domain>` |

### DNS (flarectl)
| Command | Purpose |
|---------|---------|
| `dns list <domain>` | All records via `flarectl dns list --zone <domain>` |
| `dns add <domain> <type> <name> <content> [proxy]` | Create record via `flarectl dns create` |
| `dns del <domain> <record-id>` | Delete record via `flarectl dns delete` |
| `dns find <domain> <name>` | Find record via `flarectl dns list --name <name>` |

### Tunnels (cloudflared)
| Command | Purpose |
|---------|---------|
| `tunnels list [host]` | List tunnels via `cloudflared tunnel list` |
| `tunnels info <name> [host]` | Tunnel details via `cloudflared tunnel info` |
| `tunnels create <name> [host]` | Create tunnel via `cloudflared tunnel create` |
| `tunnels delete <name> [host]` | Delete tunnel via `cloudflared tunnel delete` |
| `tunnels route <tunnel> <hostname> [host]` | Route DNS via `cloudflared tunnel route dns` |
| `tunnels config [host]` | Show `~/.cloudflared/config.yml` |
| `tunnels run <name> [host]` | Run tunnel via `cloudflared tunnel run` |
| `tunnels expose <port> <hostname> [name] [host]` | One-step: create tunnel + route DNS for localhost |
| `tunnels expose-ssh <ssh-host> <port> <hostname> [name]` | One-step: create tunnel + route DNS on remote host |
| `tunnels ingress-add <hostname> <service-url> [host]` | Add ingress rule to cloudflared config |

### Pages (wrangler)
| Command | Purpose |
|---------|---------|
| `pages list` | List projects via `wrangler pages project list` |
| `pages deploy <dir> <project> [branch]` | Deploy via `wrangler pages deploy` |
| `pages destroy <project>` | Delete project via `wrangler pages project delete` |

### Workers (wrangler)
| Command | Purpose |
|---------|---------|
| `workers list` | List workers via `wrangler deployments list` |
| `workers info <name>` | Worker details via `wrangler deployments list --name` |
| `workers deploy [dir]` | Deploy via `wrangler deploy` |
| `workers dev [dir]` | Local dev server via `wrangler dev` |
| `workers tail <name>` | Stream logs via `wrangler tail` |
| `workers delete <name>` | Delete via `wrangler delete` |

## Credential Chain

Credentials are loaded in this order:
1. **Environment variables** -- `CF_API_KEY` + `CF_API_EMAIL` (flarectl), `CLOUDFLARE_ACCOUNT_ID` (wrangler)
2. **Config file** -- `~/.config/cloudflare/credentials`
3. **1Password** -- `op item get cf --vault DEV`

The env vars `CLOUDFLARE_API_KEY` and `CLOUDFLARE_EMAIL` are also accepted and mapped to `CF_API_KEY`/`CF_API_EMAIL` for flarectl.

Account ID defaults to `95ad3baa2a4ecda1e38342df7d24204f` if not set.

**NEVER use** `CF_API_TOKEN`, `CLOUDFLARE_API_TOKEN`, or Bearer tokens. flarectl uses Global API Key auth.

## Tunnel Expose Workflow

### Expose localhost (dev machine)
```bash
# Creates tunnel, routes DNS, gives you the run command
bash $CF tunnels expose 3000 app.saiden.dev
# Then run it:
cloudflared tunnel --url http://localhost:3000 run app-saiden-dev
```

### Expose service on junkpile
```bash
# Creates tunnel on junkpile, routes DNS
bash $CF tunnels expose-ssh junkpile 8080 api.tengu.to
# Or add to existing config:
bash $CF tunnels ingress-add api.tengu.to http://localhost:8080 junkpile
# Restart tunnel on junkpile to pick up changes
```

### Full tunnel setup (manual)
```bash
bash $CF tunnels create my-service junkpile
bash $CF tunnels route my-service app.example.com junkpile
bash $CF tunnels ingress-add app.example.com http://localhost:3000 junkpile
# On junkpile: cloudflared tunnel run my-service
```

## Cross-Machine Support

All tunnel commands accept a `[host]` parameter:
- **local** (default) -- runs on current machine
- **fuji** -- runs on Mac (SSH if needed)
- **junkpile** -- runs on PC (SSH if needed)

DNS and zones use flarectl locally (no host parameter needed -- flarectl talks to the API).
Pages and workers use wrangler locally (fuji only).

**junkpile cloudflared note:** The cert at `/home/chi/.cloudflared/cert.pem` is locked to the `tengu.to` zone. For tunnel DNS routing to other zones, the DNS CNAME must be created separately via flarectl.

## Related Agents
- `psn:devops-cf` -- Cloudflare infrastructure agent (loads this skill)

## Prerequisites
- `flarectl` -- fuji (`/opt/homebrew/bin`) + junkpile (`/home/linuxbrew/.linuxbrew/bin`) -- DNS and zone management
- `cloudflared` -- fuji (`/opt/homebrew/bin`) + junkpile (`/usr/local/bin` + `/home/linuxbrew/.linuxbrew/bin`) -- tunnels
- `wrangler` -- fuji (`/opt/homebrew/bin`) + junkpile (`/home/linuxbrew/.linuxbrew/bin`) -- Pages and Workers
- Run `bash cf-check.sh` to verify all tools, credentials, and API access on both machines
- Credentials configured via `auth setup` or env vars
