---
name: Browser Automation
description: |
  Automate browser interactions via Playwright MCP. Screenshots, scraping, cookie management, form filling, and visual testing.

  <example>
  Context: User wants to capture a webpage
  user: "Take a screenshot of example.com"
  </example>

  <example>
  Context: User wants to interact with a page
  user: "Go to github.com and click the sign in button"
  </example>

  <example>
  Context: User needs to manage browser state
  user: "Save the current browser session so I can resume later"
  </example>

  <example>
  Context: User wants to extract data
  user: "Query all the links on this page"
  </example>
version: 1.0.0
---

# Browser Automation

Automate browser interactions using Playwright via the browse MCP server.

> Full tool reference: `references/tools.md`

## Session Startup (IMPORTANT)

**On first browse tool use each session**, restore saved cookies:

```
mcp__browse__session_restore(path: "/Users/chi/.claude/browse-session.json")
```

This restores 400+ authenticated cookies from Safari. Skip only if:
- File doesn't exist
- User explicitly wants fresh session
- Already restored this session

**Before ending session**, save if cookies changed:
```
mcp__browse__session_save(path: "/Users/chi/.claude/browse-session.json")
```

## Quick Start

### Basic Screenshot
```
1. mcp__browse__goto(url: "https://example.com")
2. mcp__browse__screenshot()
```

### Interactive Session
```
1. mcp__browse__launch(headed: true)
2. mcp__browse__goto(url: "https://github.com")
3. mcp__browse__click(selector: "a[href='/login']")
4. mcp__browse__type(selector: "#login_field", text: "username")
```

### Query Elements
```
1. mcp__browse__goto(url: "https://example.com")
2. mcp__browse__query(selector: "a[href]")  # Get all links
```

## Browser Modes

| Mode | Launch | Use Case |
|------|--------|----------|
| Headless | `launch()` or omit | Default, fastest |
| Headed | `launch(headed: true)` | Debugging |
| Fullscreen | `launch(fullscreen: true)` | macOS native fullscreen |
| Preview | `launch(preview: true, previewDelay: 2000)` | Highlight before action |

## Session Persistence

Save: `mcp__browse__session_save(path: "my-session.json")` — saves URL, cookies, localStorage, sessionStorage.

Restore: `mcp__browse__session_restore(path: "my-session.json")`

Import Safari cookies (macOS, requires Full Disk Access):
```
mcp__browse__import(domain: "github.com")  # Specific domain
mcp__browse__import()                       # All cookies
```

## Common Patterns

### Login and Save Session
```
1. launch(headed: true)
2. goto(url: "https://site.com/login")
3. type(selector: "#email", text: "user@example.com")
4. type(selector: "#password", text: "secret")
5. click(selector: "button[type='submit']")
6. wait(ms: 3000)
7. session_save(path: "site-session.json")
8. close()
```

### Scrape Data
```
1. goto(url: "https://example.com/products")
2. query(selector: ".product-card")
```

## Best Practices

1. **Launch once per session** — reuse the browser instance
2. **Wait after navigation** — pages need time to load
3. **Use specific selectors** — avoid ambiguous matches
4. **Save sessions for auth** — don't re-login every time
5. **Check for errors** — use `errors()` and `console()` to debug
6. **Close when done** — free resources with `close()`
