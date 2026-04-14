---
name: Parallels VM Control
description: |
  Manage Parallels Desktop VMs — list, start, stop, suspend, resume, execute commands inside guests, snapshots, file transfer, and VM configuration. Uses prlctl, prlcopy, and prlsrvctl CLIs.

  <example>
  Context: User wants to see VM status
  user: "what VMs do I have?"
  </example>

  <example>
  Context: User wants to start Windows
  user: "start the Windows VM"
  </example>

  <example>
  Context: User wants to run a command in the VM
  user: "run ipconfig in Windows"
  </example>

  <example>
  Context: User wants to take a snapshot
  user: "snapshot the Windows VM"
  </example>

  <example>
  Context: User wants to copy a file to the VM
  user: "copy this file to Windows"
  </example>

  <example>
  Context: User mentions Parallels or a VM
  user: "suspend Windows"
  </example>

  <example>
  Context: User wants to check what's running in the VM
  user: "what's running on Windows?"
  </example>
version: 1.0.0
---

# Parallels VM Control

Manage Parallels Desktop VMs from the CLI via `prlctl`, `prlcopy`, and `prlsrvctl`.

## Known VMs

| Name | UUID | Notes |
|------|------|-------|
| Windows 11 | `{be561976-04ce-476e-9d71-0af45380dd18}` | Primary Windows VM |

## Quick Reference

### VM Lifecycle

```bash
# List all VMs with status
prlctl list -a

# List with full info (IP, config)
prlctl list -a -f

# Detailed VM info
prlctl list -i "Windows 11"

# JSON output (for parsing)
prlctl list -a -j
```

### Power Operations

```bash
# Start / resume a suspended VM
prlctl start "Windows 11"

# Suspend (save state to disk)
prlctl suspend "Windows 11"

# Pause (freeze in memory)
prlctl pause "Windows 11"

# Resume from pause
prlctl resume "Windows 11"

# Graceful shutdown (via guest OS)
prlctl stop "Windows 11"

# Force stop (like pulling the power)
prlctl stop "Windows 11" --kill

# Restart
prlctl restart "Windows 11"

# Check status
prlctl status "Windows 11"
```

### Execute Commands Inside VM

Requires Parallels Tools installed in the guest.

```bash
# Run a command (uses current user)
prlctl exec "Windows 11" cmd /c "dir C:\\"

# Run PowerShell
prlctl exec "Windows 11" powershell -Command "Get-Process | Select-Object -First 10"

# Run with specific user
prlctl exec "Windows 11" --user Administrator --password "pass" cmd /c "whoami"

# Check IP from inside
prlctl exec "Windows 11" cmd /c "ipconfig"

# Check running processes
prlctl exec "Windows 11" powershell -Command "Get-Process | Sort-Object CPU -Descending | Select-Object -First 20"

# Check disk space
prlctl exec "Windows 11" powershell -Command "Get-PSDrive -PSProvider FileSystem"

# System info
prlctl exec "Windows 11" cmd /c "systeminfo"
```

### File Transfer

```bash
# Upload file to VM (auto-detects temp dir if no guest path)
prlcopy upload /path/to/local/file.txt C:\\Users\\chi\\Desktop\\

# Upload and execute a script
prlcopy upload /path/to/script.ps1 --exec "powershell -ExecutionPolicy Bypass -File script.ps1"

# Download file from VM
prlcopy download C:\\Users\\chi\\Documents\\file.txt /tmp/

# Upload to specific VM (if multiple)
prlcopy upload /path/to/file --vm "Windows 11" C:\\Users\\chi\\Desktop\\
```

### Snapshots

```bash
# Create a named snapshot
prlctl snapshot "Windows 11" -n "clean-state" -d "Fresh install, all updates applied"

# List snapshots (tree view)
prlctl snapshot-list "Windows 11" -t

# List snapshots (JSON)
prlctl snapshot-list "Windows 11" -j

# Get snapshot details
prlctl snapshot-list "Windows 11" -i "{snapshot-uuid}"

# Revert to a snapshot
prlctl snapshot-switch "Windows 11" -i "{snapshot-uuid}"

# Delete a snapshot
prlctl snapshot-delete "Windows 11" -i "{snapshot-uuid}"
```

### VM Configuration

```bash
# Set CPU count
prlctl set "Windows 11" cpus --number 4

# Set memory (MB)
prlctl set "Windows 11" memory --size 8192

# View current config
prlctl list -i "Windows 11"
```

### Server Management

```bash
# Parallels server info
prlsrvctl info

# VM storage location
prlsrvctl info | grep "VM home"
```

## Patterns

### Start VM, Run Command, Get Output

```bash
# Ensure VM is running first
STATUS=$(prlctl status "Windows 11" | awk '{print $NF}')
if [ "$STATUS" != "running" ]; then
  prlctl start "Windows 11"
  sleep 10  # Wait for boot
fi
prlctl exec "Windows 11" cmd /c "your-command"
```

### Safe Snapshot Before Risky Operations

```bash
# Snapshot before making changes
prlctl snapshot "Windows 11" -n "pre-change-$(date +%Y%m%d-%H%M%S)"
# ... do risky stuff ...
# Revert if needed:
# prlctl snapshot-switch "Windows 11" -i "{snapshot-uuid}"
```

## Notes

- VM names with spaces must be quoted: `"Windows 11"`
- `prlctl exec` requires Parallels Tools installed in the guest
- `start` works for both stopped and suspended VMs
- `suspend` saves state; `stop` shuts down; `stop --kill` force-kills
- `prlcopy` auto-starts a stopped VM if needed
- Guest paths use Windows backslash notation: `C:\\Users\\...`
- For long-running guest commands, consider `prlctl exec` with timeout awareness
