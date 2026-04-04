---
name: Browser Automation
description: |
  This skill should be used when automating browser interactions, taking screenshots, scraping web content, managing cookies, or testing web pages. Triggers on requests involving web page interaction, browser control, or visual capture.

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

# Tools Reference

## Navigation
| Tool | Purpose |
|------|---------|
| `mcp__browse__launch` | Configure browser (headed/headless, viewport, preview mode) |
| `mcp__browse__goto` | Navigate to a URL |
| `mcp__browse__back` | Go back in browser history |
| `mcp__browse__forward` | Go forward in browser history |
| `mcp__browse__reload` | Reload current page |
| `mcp__browse__close` | Close browser and end session |

## Interaction
| Tool | Purpose |
|------|---------|
| `mcp__browse__click` | Click on element by CSS selector |
| `mcp__browse__type` | Type text into input field |
| `mcp__browse__hover` | Hover over element |
| `mcp__browse__select` | Select option(s) in dropdown |
| `mcp__browse__keys` | Send keyboard keys/shortcuts |
| `mcp__browse__scroll` | Scroll page or element into view |
| `mcp__browse__upload` | Upload files to file input |
| `mcp__browse__dialog` | Handle browser dialogs (alert, confirm, prompt) |

## Query & Extract
| Tool | Purpose |
|------|---------|
| `mcp__browse__query` | Query elements by CSS selector, get attributes |
| `mcp__browse__url` | Get current URL and page title |
| `mcp__browse__html` | Get page HTML content |
| `mcp__browse__eval` | Execute JavaScript in browser context |

## Capture & Debug
| Tool | Purpose |
|------|---------|
| `mcp__browse__screenshot` | Take screenshot of current page |
| `mcp__browse__console` | Get captured console messages |
| `mcp__browse__network` | Get captured network requests/responses |
| `mcp__browse__errors` | Get page errors (exceptions, unhandled rejections) |
| `mcp__browse__metrics` | Get performance metrics and DOM stats |
| `mcp__browse__a11y` | Get accessibility tree snapshot |

## State Management
| Tool | Purpose |
|------|---------|
| `mcp__browse__cookies` | Get, set, delete, or clear cookies |
| `mcp__browse__storage` | Get, set, delete localStorage/sessionStorage |
| `mcp__browse__session_save` | Save session state to JSON file |
| `mcp__browse__session_restore` | Restore session from JSON file |
| `mcp__browse__import` | Import cookies from Safari (macOS) |

## Network Control
| Tool | Purpose |
|------|---------|
| `mcp__browse__intercept` | Block or mock network requests |

## Viewport & Emulation
| Tool | Purpose |
|------|---------|
| `mcp__browse__viewport` | Resize browser viewport |
| `mcp__browse__emulate` | Emulate mobile device |
| `mcp__browse__wait` | Wait for specified time |

## Image Processing
| Tool | Purpose |
|------|---------|
| `mcp__browse__favicon` | Generate favicon set from image |
| `mcp__browse__convert` | Convert image format (png, jpeg, webp, avif) |
| `mcp__browse__resize` | Resize image to dimensions |
| `mcp__browse__crop` | Crop region from image |
| `mcp__browse__compress` | Compress image to reduce size |
| `mcp__browse__thumbnail` | Create thumbnail from image |

---

# Browser Automation

Automate browser interactions using Playwright via the browse MCP server.

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

## Architecture

- **Engine**: Playwright (Chromium)
- **Transport**: MCP stdio server (`browse-mcp`)
- **Context**: Ephemeral by default, persistent via session_save/restore
- **Cookies**: In-memory unless explicitly saved

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

### Headless (Default)
No visible window, fastest execution:
```
mcp__browse__launch()  # or omit launch entirely
```

### Headed
Visible browser window for debugging:
```
mcp__browse__launch(headed: true)
```

### Fullscreen (macOS)
Native fullscreen, implies headed:
```
mcp__browse__launch(fullscreen: true)
```

### Preview Mode
Highlight elements before actions:
```
mcp__browse__launch(preview: true, previewDelay: 2000)
```

## Session Persistence

Browser state is ephemeral by default. To persist across sessions:

### Save Session
```
mcp__browse__session_save(path: "my-session.json")
```

Saves:
- Current URL
- All cookies
- localStorage
- sessionStorage

### Restore Session
```
mcp__browse__session_restore(path: "my-session.json")
```

### Import Safari Cookies (macOS)
Requires Full Disk Access permission:
```
mcp__browse__import(domain: "github.com")  # Import for specific domain
mcp__browse__import()  # Import all cookies
```

## Cookie Management

### Get Cookies
```
mcp__browse__cookies(action: "get")           # All cookies
mcp__browse__cookies(action: "get", name: "session")  # Specific cookie
```

### Set Cookie
```
mcp__browse__cookies(action: "set", name: "token", value: "abc123")
```

### Delete/Clear
```
mcp__browse__cookies(action: "delete", name: "token")
mcp__browse__cookies(action: "clear")  # All cookies
```

## Element Selectors

Use CSS selectors for all element interactions:

| Selector | Example |
|----------|---------|
| Tag | `button`, `input`, `a` |
| Class | `.btn-primary`, `.nav-link` |
| ID | `#login-form`, `#submit` |
| Attribute | `[type="submit"]`, `[href="/login"]` |
| Combined | `button.primary[type="submit"]` |
| Descendant | `.form-group input` |
| Nth-child | `li:nth-child(2)` |

## Network Interception

Block or mock requests:

### Block Requests
```
mcp__browse__intercept(pattern: "*.analytics.com/*", action: "block")
```

### Mock Response
```
mcp__browse__intercept(
  pattern: "/api/user",
  action: "mock",
  response: '{"id": 1, "name": "Test User"}'
)
```

## Debugging

### Console Messages
```
mcp__browse__console()  # Get all console.log, warn, error
```

### Network Requests
```
mcp__browse__network()  # Get all requests with status, timing
```

### Page Errors
```
mcp__browse__errors()  # Uncaught exceptions, unhandled rejections
```

### Performance Metrics
```
mcp__browse__metrics()  # DOM stats, load times, memory
```

### Accessibility
```
mcp__browse__a11y()  # Full accessibility tree
mcp__browse__a11y(selector: "#main")  # Specific element
```

## Image Processing

Process screenshots or any image:

### Generate Favicons
```
mcp__browse__screenshot()
mcp__browse__favicon(dir: "./favicons")  # Creates full favicon set
```

### Convert Format
```
mcp__browse__convert(format: "webp")  # From last screenshot
```

### Resize
```
mcp__browse__resize(width: 800, height: 600)
mcp__browse__resize(width: 800)  # Maintain aspect ratio
```

### Compress
```
mcp__browse__compress(quality: 60)  # 1-100
```

## Best Practices

1. **Launch once per session** - Reuse the browser instance
2. **Wait after navigation** - Pages need time to load
3. **Use specific selectors** - Avoid ambiguous matches
4. **Save sessions for auth** - Don't re-login every time
5. **Check for errors** - Use `errors()` and `console()` to debug
6. **Close when done** - Free resources with `close()`

## Common Patterns

### Login and Save Session
```
1. launch(headed: true)  # Watch what happens
2. goto(url: "https://site.com/login")
3. type(selector: "#email", text: "user@example.com")
4. type(selector: "#password", text: "secret")
5. click(selector: "button[type='submit']")
6. wait(ms: 3000)  # Wait for redirect
7. session_save(path: "site-session.json")
8. close()
```

### Scrape Data
```
1. goto(url: "https://example.com/products")
2. query(selector: ".product-card")  # Get all products
3. eval(script: "document.querySelectorAll('.price').map(e => e.textContent)")
```

### Visual Regression
```
1. goto(url: "https://staging.example.com")
2. screenshot(path: "staging.png")
3. goto(url: "https://prod.example.com")
4. screenshot(path: "prod.png")
# Compare manually or with image diff tool
```
