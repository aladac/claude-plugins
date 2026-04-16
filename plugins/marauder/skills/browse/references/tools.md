# Browse MCP Tools Reference

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

## Network Interception

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
