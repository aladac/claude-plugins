#!/usr/bin/env ruby
# frozen_string_literal: true

# EVE Online screen capture — macOS
# Usage: ruby eve-screen.rb capture [path]
#
# Captures the EVE game window using screencapture -l <window_id>.
# Returns the file path for visual analysis via Read tool.

require "time"

def find_game_window_id
  swift_file = "/tmp/eve-find-window.swift"
  File.write(swift_file, <<~'SWIFT')
    import Cocoa
    var found = false
    if let list = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] {
      var best: (Int, Int) = (0, 0)
      for w in list {
        let owner = w[kCGWindowOwnerName as String] as? String ?? ""
        let name = w[kCGWindowName as String] as? String ?? ""
        if owner == "EVE" && name.hasPrefix("EVE - ") {
          let id = w[kCGWindowNumber as String] as? Int ?? 0
          let bounds = w[kCGWindowBounds as String] as? [String: Any] ?? [:]
          let width = bounds["Width"] as? Int ?? 0
          let height = bounds["Height"] as? Int ?? 0
          let area = width * height
          if area > best.1 { best = (id, area) }
        }
      }
      if best.0 > 0 { print(best.0); found = true }
    }
    if !found { print("0") }
  SWIFT

  output = `swift #{swift_file} 2>/dev/null`.strip
  wid = output.to_i
  wid > 0 ? wid : nil
end

def cmd_capture(path = nil)
  wid = find_game_window_id
  unless wid
    $stderr.puts "ERROR: No EVE game window found. Is the client running and logged in?"
    exit 1
  end

  path ||= "/tmp/eve-screen-#{Time.now.strftime("%Y%m%d-%H%M%S")}.png"

  result = `screencapture -x -o -l #{wid} "#{path}" 2>&1`
  unless $?.success?
    $stderr.puts "ERROR: screencapture failed: #{result.strip}"
    exit 1
  end

  unless File.exist?(path) && File.size(path) > 0
    $stderr.puts "ERROR: Screenshot file not created or empty"
    exit 1
  end

  # Output path for the Read tool
  puts path
end

# --- Main ---

command = ARGV.shift
case command
when "capture", "snap"
  cmd_capture(ARGV.shift)
else
  puts "EVE Screen Capture — macOS"
  puts ""
  puts "Usage: ruby eve-screen.rb <command> [path]"
  puts ""
  puts "Commands:"
  puts "  capture [path]   Capture EVE game window (default: /tmp/eve-screen-<timestamp>.png)"
  puts "  snap [path]      Alias for capture"
  puts ""
  puts "Returns the file path on stdout for visual analysis via Read tool."
end
