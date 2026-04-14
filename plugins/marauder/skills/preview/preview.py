#!/usr/bin/env python3
"""Preview — render HTML file or URL to visor viewport.

Usage:
    preview.py <file_or_url> [options]

Options:
    --title TEXT       Visor title (default: filename or domain)
    --caption TEXT     Visor caption
    --width N          Viewport width (default: 640)
    --height N         Viewport height (default: 400)
    --full-page        Capture full scrollable page
    --no-visor         Save screenshot only, don't push to visor
    --output PATH      Screenshot output path (default: /tmp/preview.png)
    --delay MS         Wait before screenshot (default: 1000)

Examples:
    preview.py /tmp/mockup.html --title "MOCKUP"
    preview.py https://kwit.fit --title "KWIT.FIT" --full-page
    preview.py component.html --width 400 --height 300 --caption "mobile view"
"""

import argparse
import json
import os
import sys
import urllib.request
from pathlib import Path

HUD_URL = os.environ.get("HUD_URL", "http://127.0.0.1:9876")


def is_url(s):
    return s.startswith("http://") or s.startswith("https://")


def resolve_target(target):
    if is_url(target):
        return target
    path = Path(target).resolve()
    if not path.exists():
        print(f"Error: {target} not found", file=sys.stderr)
        sys.exit(1)
    return f"file://{path}"


def default_title(target):
    if is_url(target):
        from urllib.parse import urlparse
        return urlparse(target).hostname or "PREVIEW"
    return Path(target).stem.upper()


def screenshot(url, output, width, height, full_page, delay_ms):
    from playwright.sync_api import sync_playwright

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page(viewport={"width": width, "height": height})
        page.goto(url, wait_until="networkidle")
        if delay_ms > 0:
            page.wait_for_timeout(delay_ms)
        page.screenshot(path=output, full_page=full_page)
        browser.close()

    return output


def push_to_visor(image_path, title, caption):
    try:
        urllib.request.urlopen(
            urllib.request.Request(
                f"{HUD_URL}/status", method="GET"
            ),
            timeout=2,
        )
    except Exception:
        print("Visor not running, skipping display")
        return False

    payload = json.dumps({
        "source": f"file://{os.path.abspath(image_path)}",
        "title": title or None,
        "caption": caption or None,
    }).encode()

    req = urllib.request.Request(
        f"{HUD_URL}/image",
        data=payload,
        headers={"Content-Type": "application/json"},
    )
    urllib.request.urlopen(req)
    return True


def main():
    parser = argparse.ArgumentParser(description="Preview HTML/URL on visor")
    parser.add_argument("target", help="HTML file path or URL")
    parser.add_argument("--title", default=None, help="Visor title")
    parser.add_argument("--caption", default=None, help="Visor caption")
    parser.add_argument("--width", type=int, default=640, help="Viewport width")
    parser.add_argument("--height", type=int, default=400, help="Viewport height")
    parser.add_argument("--full-page", action="store_true", help="Full page capture")
    parser.add_argument("--no-visor", action="store_true", help="Screenshot only")
    parser.add_argument("--output", default="/tmp/preview.png", help="Output path")
    parser.add_argument("--delay", type=int, default=1000, help="Delay before capture (ms)")
    args = parser.parse_args()

    url = resolve_target(args.target)
    title = args.title or default_title(args.target)

    print(f"Capturing: {args.target} ({args.width}x{args.height})")
    output = screenshot(url, args.output, args.width, args.height, args.full_page, args.delay)
    print(f"Saved: {output}")

    if not args.no_visor:
        if push_to_visor(output, title, args.caption):
            print(f"Displayed on visor: {title}")

    # Output path for caller to use
    print(output)


if __name__ == "__main__":
    main()
