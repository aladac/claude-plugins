---
name: mikrotik
description: |
  MikroTik RouterOS management via the native TCP API. DHCP leases, DNS records, ARP table, interfaces, and system info. Uses MCP tools (mikrotik_*) for structured access, CLI (`marauder mt`) for quick checks.

  <example>
  Context: User wants to check router status
  user: "how's the router doing?"
  </example>

  <example>
  Context: User wants to find a device on the network
  user: "what IP does the camera have?"
  </example>

  <example>
  Context: User wants to add a DNS record
  user: "add myhost.local.sazabi.pl pointing to 192.168.88.200"
  </example>

  <example>
  Context: User wants to see DHCP leases
  user: "show me all devices on the network"
  </example>

  <example>
  Context: User wants to pin a DHCP lease
  user: "make that lease static"
  </example>
version: 1.0.0
---

# MikroTik RouterOS Skill

Manage the MikroTik router (yokohama, RB2011UiAS-2HnD, RouterOS 6.49.19) at 192.168.88.1 via the RouterOS TCP API on port 8728.

## Rules

- NEVER remove DNS entries or modify DHCP static leases without confirming via AskUserQuestion. NEVER modify firewall rules or routes — these are out of scope.

## MCP Tools

Use these for structured, programmatic access from Claude:

| Tool | Purpose | Mutating |
|------|---------|----------|
| `mikrotik_system` | CPU, memory, uptime, board, version | no |
| `mikrotik_interfaces` | Interface list with status, traffic, MAC | no |
| `mikrotik_arp` | ARP table (IP→MAC mappings, device discovery) | no |
| `mikrotik_dhcp_leases` | DHCP lease table (IP, MAC, hostname, status) | no |
| `mikrotik_dhcp_static` | Make a DHCP lease static + set comment | yes |
| `mikrotik_dns_list` | Static DNS entries | no |
| `mikrotik_dns_add` | Add a static DNS record (name + address) | yes |
| `mikrotik_dns_remove` | Remove a static DNS record by ID | destructive |

### Filtering

Read-only tools accept optional `filter_key` and `filter_value` parameters:
```json
{"filter_key": "status", "filter_value": "bound"}
```

### Getting IDs

Mutation tools need IDs from the corresponding list tool. Always list first, then use the `.id` field (e.g. `*25`, `*2`).

## CLI

For quick terminal checks (not from MCP):

```bash
marauder mt status              # System info
marauder mt leases              # DHCP lease table
marauder mt dns                 # Static DNS entries
marauder mt arp                 # ARP table
marauder mt exec "/path/print"  # Raw command passthrough
```

## Device Onboarding Workflow

When adding a new device to the network:

1. **Find the device** — use `mikrotik_dhcp_leases` or `mikrotik_arp` to locate by hostname or MAC
2. **Pin the lease** — use `mikrotik_dhcp_static` with the lease ID and a descriptive comment
3. **Add DNS** — use `mikrotik_dns_add` with `name.local.sazabi.pl` and the IP address
4. **Verify** — use `mikrotik_dns_list` to confirm the entry

## Router Details

- **Name:** yokohama
- **Model:** RB2011UiAS-2HnD (MIPSBE, 128MB RAM)
- **RouterOS:** 6.49.19 (long-term branch)
- **API:** TCP port 8728 (no TLS, LAN only)
- **DNS zone:** `*.local.sazabi.pl` for static entries
- **DHCP range:** 192.168.88.x/24

## What This Skill Does NOT Do

- **No firewall rule management** — blast radius too high for autonomous use
- **No routing changes** — could break network connectivity
- **No firmware upgrades** — requires manual verification
- **No REST API** — RouterOS 6 doesn't support it (v7+ only)
