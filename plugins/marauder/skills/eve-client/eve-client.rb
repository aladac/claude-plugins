#!/usr/bin/env ruby
# frozen_string_literal: true

# EVE Online client detection and management — macOS
# Usage: ruby eve-client.rb <command>
#
# The EVE client runs as:
#   - Launcher: /Applications/eve-online.app (Electron)
#   - Game engine: exefile inside EVE.app (SharedCache/tq/EVE.app)
#   - Window owner: "EVE" with title "EVE - <character_name>"
#
# Window detection uses Swift + CGWindowListCopyWindowInfo for reliable IDs.

def eve_windows
  # Swift file for CGWindowListCopyWindowInfo — reliable window IDs
  swift_file = "/tmp/eve-find-windows.swift"
  File.write(swift_file, <<~'SWIFT')
    import Cocoa
    if let list = CGWindowListCopyWindowInfo([.optionAll, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] {
      for w in list {
        let owner = w[kCGWindowOwnerName as String] as? String ?? ""
        if owner.uppercased().contains("EVE") {
          let name = w[kCGWindowName as String] as? String ?? ""
          let id = w[kCGWindowNumber as String] as? Int ?? 0
          let pid = w[kCGWindowOwnerPID as String] as? Int ?? 0
          let layer = w[kCGWindowLayer as String] as? Int ?? 0
          let bounds = w[kCGWindowBounds as String] as? [String: Any] ?? [:]
          let width = bounds["Width"] as? Int ?? 0
          let height = bounds["Height"] as? Int ?? 0
          let x = bounds["X"] as? Int ?? 0
          let y = bounds["Y"] as? Int ?? 0
          print("\(id)|\(owner)|\(name)|\(pid)|\(layer)|\(width)|\(height)|\(x)|\(y)")
        }
      }
    }
  SWIFT

  output = `swift #{swift_file} 2>/dev/null`.strip
  return [] if output.empty?

  output.split("\n").map do |line|
    parts = line.split("|", 9)
    next if parts.length < 9
    {
      id: parts[0].to_i,
      owner: parts[1],
      name: parts[2],
      pid: parts[3].to_i,
      layer: parts[4].to_i,
      width: parts[5].to_i,
      height: parts[6].to_i,
      x: parts[7].to_i,
      y: parts[8].to_i
    }
  end.compact
end

def eve_processes
  # The game engine runs as "exefile" or process contains "EVE.app"
  pids = `pgrep -f "EVE.app" 2>/dev/null`.strip.split("\n").map(&:to_i).reject(&:zero?)
  launcher_pids = `pgrep -f "eve-online.app" 2>/dev/null`.strip.split("\n").map(&:to_i).reject(&:zero?)

  {game: pids, launcher: launcher_pids}
end

def process_info(pid)
  ps_out = `ps -p #{pid} -o pid,ppid,%cpu,%mem,etime,command 2>/dev/null`.strip.split("\n")
  return nil if ps_out.length < 2

  parts = ps_out[1].strip.split(/\s+/, 6)
  {
    pid: parts[0].to_i,
    ppid: parts[1].to_i,
    cpu: parts[2],
    mem: parts[3],
    elapsed: parts[4],
    command: parts[5]
  }
end

def game_windows
  # All EVE windows with a character name in title (multi-client support)
  wins = eve_windows
  wins.select { |w| w[:name]&.start_with?("EVE - ") }
      .sort_by { |w| w[:name] }
end

def game_window(char_name = nil)
  gws = game_windows
  if char_name
    gws.find { |w| w[:name].downcase.include?(char_name.downcase) }
  else
    gws.first
  end
end

def cmd_status
  procs = eve_processes
  wins = eve_windows
  gws = game_windows

  if procs[:game].empty? && procs[:launcher].empty?
    puts "EVE Online: NOT RUNNING"
    return
  end

  puts "EVE Online: RUNNING"
  puts "Clients: #{gws.length}"
  puts ""

  gws.each_with_index do |gw, i|
    char_name = gw[:name].sub("EVE - ", "")
    display = gw[:x] < 0 || gw[:x] >= 2560 ? "Display 2" : "Display 1"
    puts "  #{i + 1}. #{char_name} — #{gw[:width]}x#{gw[:height]} @ (#{gw[:x]},#{gw[:y]}) [#{display}] WID #{gw[:id]}"
  end

  puts ""
  puts "Game PIDs: #{procs[:game].join(", ")}" if procs[:game].any?
  puts "Launcher PIDs: #{procs[:launcher].join(", ")}" if procs[:launcher].any?

  # Aggregate process info
  procs[:game].each do |pid|
    info = process_info(pid)
    next unless info
    # Extract character from command line settingsprofile
    char = info[:command]&.match(/settingsprofile=(\S+)/)&.[](1) || "unknown"
    puts "  PID #{pid} (#{char}): CPU #{info[:cpu]}%  MEM #{info[:mem]}%  Uptime: #{info[:elapsed]}"
  end

  puts ""
  puts "Total windows: #{wins.length}"
  wins.each do |w|
    puts "  [#{w[:id]}] #{w[:owner]} — \"#{w[:name]}\" #{w[:width]}x#{w[:height]} @ (#{w[:x]},#{w[:y]})"
  end
end

def cmd_info
  procs = eve_processes
  all_pids = procs[:game] + procs[:launcher]

  if all_pids.empty?
    puts "No EVE processes found."
    return
  end

  puts "=== Game Processes ==="
  procs[:game].each do |pid|
    info = process_info(pid)
    next unless info
    puts "PID #{info[:pid]}: CPU #{info[:cpu]}% MEM #{info[:mem]}% Uptime #{info[:elapsed]}"
    puts "  #{info[:command][0..120]}"
  end

  puts ""
  puts "=== Launcher Processes ==="
  procs[:launcher].each do |pid|
    info = process_info(pid)
    next unless info
    puts "PID #{info[:pid]}: CPU #{info[:cpu]}% MEM #{info[:mem]}% Uptime #{info[:elapsed]}"
    puts "  #{info[:command][0..120]}"
  end
end

def cmd_windows
  wins = eve_windows
  if wins.empty?
    puts "No EVE windows found."
    return
  end

  wins.each do |w|
    puts "Window ID: #{w[:id]}"
    puts "  Owner: #{w[:owner]} (PID #{w[:pid]})"
    puts "  Title: #{w[:name]}"
    puts "  Size: #{w[:width]}x#{w[:height]}"
    puts "  Position: (#{w[:x]}, #{w[:y]})"
    puts "  Layer: #{w[:layer]}"
    puts ""
  end
end

def cmd_focus
  result = `osascript -e 'tell application "System Events" to set frontmost of (first process whose name is "EVE") to true' 2>&1`
  if $?.success?
    puts "EVE window brought to foreground."
  else
    puts "Failed: #{result.strip}"
  end
end

def cmd_window_id(char_name = nil)
  if char_name
    gw = game_window(char_name)
    if gw
      puts gw[:id]
    else
      $stderr.puts "No EVE window found for '#{char_name}'."
      exit 1
    end
  else
    gws = game_windows
    if gws.any?
      gws.each { |w| puts "#{w[:name].sub("EVE - ", "")}: #{w[:id]}" }
    else
      $stderr.puts "No EVE game windows found."
      exit 1
    end
  end
end

def cmd_character
  gws = game_windows
  if gws.any?
    gws.each { |w| puts w[:name].sub("EVE - ", "") }
  else
    $stderr.puts "No EVE game windows found."
    exit 1
  end
end

# --- Main ---

command = ARGV.shift
case command
when "status"
  cmd_status
when "info"
  cmd_info
when "windows", "wins"
  cmd_windows
when "focus"
  cmd_focus
when "window-id", "wid"
  cmd_window_id(ARGV.shift)
when "character", "char"
  cmd_character
else
  puts "EVE Client Detection — macOS"
  puts ""
  puts "Usage: ruby eve-client.rb <command>"
  puts ""
  puts "Commands:"
  puts "  status      Quick status (running/not, character, window, PIDs)"
  puts "  info        Detailed process info (CPU, mem, uptime)"
  puts "  windows     List all EVE windows with IDs and geometry"
  puts "  focus       Bring EVE to foreground"
  puts "  window-id   Output main game window ID (for screencapture)"
  puts "  character   Output logged-in character name"
end
