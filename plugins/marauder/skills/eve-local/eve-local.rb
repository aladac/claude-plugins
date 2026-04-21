#!/usr/bin/env ruby
# frozen_string_literal: true

# EVE Local Reference Lookup
# Single script for missions, anomalies, and escalations from local files.
#
# Usage:
#   ruby eve-local.rb mission <name> [faction]
#   ruby eve-local.rb anomaly <name>
#   ruby eve-local.rb escalation [faction]
#
# Examples:
#   ruby eve-local.rb mission "gone berserk"
#   ruby eve-local.rb mission "worlds collide" ansa
#   ruby eve-local.rb anomaly den
#   ruby eve-local.rb anomaly "rally point"
#   ruby eve-local.rb escalation
#   ruby eve-local.rb escalation guristas

EVE_DIR = File.expand_path("~/Projects/eve-online")
MISSIONS_DIR = File.join(EVE_DIR, "missions")
GURISTAS_DIR = File.join(EVE_DIR, "guristas-hisec")

def find_files(dir, query)
  return [] unless Dir.exist?(dir)

  # Normalize query: "rally point" -> "rally-point", "Gone Berserk" -> "gone-berserk"
  normalized = query.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")
  all_files = Dir.glob(File.join(dir, "*.md"))

  # 1. Exact segment match: filename contains the full normalized query as a segment
  #    e.g. "den" matches "guristas-den.md" but NOT "guristas-hidden-den.md"
  exact = all_files.select do |f|
    base = File.basename(f, ".md")
    # Check if normalized appears as whole hyphen-delimited segment(s)
    base.match?(/(?:^|-)#{Regexp.escape(normalized)}(?:-|$)/)
  end
  return exact.sort unless exact.empty?

  # 2. Substring match on the full normalized query
  substr = all_files.select do |f|
    File.basename(f, ".md").include?(normalized)
  end
  return substr.sort unless substr.empty?

  # 3. All-words match (each word present anywhere in filename)
  words = normalized.split("-")
  fuzzy = all_files.select do |f|
    base = File.basename(f).downcase
    words.all? { |w| base.include?(w) }
  end

  fuzzy.sort
end

def cmd_mission(args)
  if args.empty?
    $stderr.puts "Usage: ruby eve-local.rb mission <name> [faction]"
    $stderr.puts "  name: mission name (partial match, e.g. 'gone berserk', 'blockade')"
    $stderr.puts "  faction: optional faction suffix (e.g. 'an', 'br', 'gu', 'sa', 'se')"
    $stderr.puts "\nExamples:"
    $stderr.puts '  ruby eve-local.rb mission "gone berserk"'
    $stderr.puts '  ruby eve-local.rb mission blockade an'
    $stderr.puts '  ruby eve-local.rb mission "worlds collide" ansa'
    exit 1
  end

  query = args.join(" ")
  matches = find_files(MISSIONS_DIR, query)

  if matches.empty?
    puts "No mission found matching: #{query}"
    puts "Available missions (#{Dir.glob(File.join(MISSIONS_DIR, '*.md')).size} files):"
    Dir.glob(File.join(MISSIONS_DIR, "*.md")).sort.each { |f| puts "  #{File.basename(f, '.md')}" }
    exit 1
  end

  if matches.size > 10
    puts "#{matches.size} matches for '#{query}' — narrowing needed:"
    matches.first(15).each { |f| puts "  #{File.basename(f, '.md')}" }
    puts "  ... and #{matches.size - 15} more" if matches.size > 15
    exit 0
  end

  if matches.size > 1
    puts "#{matches.size} matches for '#{query}':"
    matches.each { |f| puts "  #{File.basename(f, '.md')}" }
    puts "\n--- Showing first match ---\n\n"
  end

  puts File.read(matches.first)
end

def cmd_anomaly(args)
  if args.empty?
    $stderr.puts "Usage: ruby eve-local.rb anomaly <name>"
    $stderr.puts "  name: anomaly name (partial match, e.g. 'den', 'rally point', 'hideaway')"
    $stderr.puts "\nExamples:"
    $stderr.puts "  ruby eve-local.rb anomaly den"
    $stderr.puts '  ruby eve-local.rb anomaly "scout outpost"'
    $stderr.puts "  ruby eve-local.rb anomaly hideaway"
    exit 1
  end

  query = args.join(" ")
  matches = find_files(GURISTAS_DIR, query)
  # Exclude escalations.md from anomaly results
  matches.reject! { |f| File.basename(f) == "escalations.md" }

  if matches.empty?
    puts "No anomaly/DED found matching: #{query}"
    puts "Available sites:"
    Dir.glob(File.join(GURISTAS_DIR, "*.md")).sort.each do |f|
      next if File.basename(f) == "escalations.md"
      puts "  #{File.basename(f, '.md')}"
    end
    exit 1
  end

  if matches.size > 1
    puts "#{matches.size} matches for '#{query}':"
    matches.each { |f| puts "  #{File.basename(f, '.md')}" }
    puts "\n--- Showing first match ---\n\n"
  end

  puts File.read(matches.first)
end

def cmd_escalation(args)
  esc_file = File.join(GURISTAS_DIR, "escalations.md")
  unless File.exist?(esc_file)
    $stderr.puts "ERROR: #{esc_file} not found"
    exit 1
  end

  content = File.read(esc_file)

  if args.empty?
    puts content
  else
    # Filter to lines matching the query (plus headers)
    query = args.join(" ").downcase
    lines = content.lines
    filtered = lines.select do |line|
      line.start_with?("#") || line.start_with?("|--") || line.start_with?("| ") && line.downcase.include?(query) || line.start_with?("\\*") || line.strip.empty?
    end
    # Always include the header
    puts lines.first(4).join
    puts filtered.join
  end
end

# --- Main ---

if ARGV.empty? || %w[--help -h].include?(ARGV[0])
  puts <<~USAGE
    EVE Local Reference Lookup

    Usage:
      ruby eve-local.rb mission <name> [faction]   Search L4 mission guides
      ruby eve-local.rb anomaly <name>              Search Guristas combat sites
      ruby eve-local.rb escalation [filter]         Show escalation chain

    Data directories:
      Missions:    #{MISSIONS_DIR} (#{Dir.exist?(MISSIONS_DIR) ? Dir.glob(File.join(MISSIONS_DIR, '*.md')).size : 0} files)
      Guristas:    #{GURISTAS_DIR} (#{Dir.exist?(GURISTAS_DIR) ? Dir.glob(File.join(GURISTAS_DIR, '*.md')).size : 0} files)
  USAGE
  exit 0
end

command = ARGV.shift.downcase

case command
when "mission", "m"
  cmd_mission(ARGV)
when "anomaly", "anom", "a"
  cmd_anomaly(ARGV)
when "escalation", "esc", "e"
  cmd_escalation(ARGV)
else
  $stderr.puts "Unknown command: #{command}"
  $stderr.puts "Valid commands: mission, anomaly, escalation"
  exit 1
end
