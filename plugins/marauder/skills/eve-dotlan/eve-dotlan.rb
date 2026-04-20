#!/usr/bin/env ruby
# frozen_string_literal: true

# EVE DOTLAN EveMaps scraper — system info, routes, region maps
# Usage: ruby eve-dotlan.rb <command> [args...]

require "net/http"
require "uri"
require "json"

DOTLAN_BASE = "https://evemaps.dotlan.net"

def fetch_html(url)
  uri = URI(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.open_timeout = 10
  http.read_timeout = 10
  req = Net::HTTP::Get.new(uri)
  req["User-Agent"] = "MARAUDER-AURA/1.0 (EVE Capsuleer Assistant)"
  response = http.request(req)
  response.code.to_i == 200 ? response.body : nil
rescue => e
  $stderr.puts "ERROR: #{e.message}"
  nil
end

def extract_text(html, pattern)
  match = html.match(pattern)
  match ? match[1].strip.gsub(/<[^>]+>/, "").strip : nil
end

def cmd_system(name)
  slug = name.gsub(" ", "_")
  html = fetch_html("#{DOTLAN_BASE}/system/#{slug}")
  unless html
    puts "ERROR: Could not fetch system #{name}"
    return
  end

  puts "System: #{name}"
  puts "URL: #{DOTLAN_BASE}/system/#{slug}"

  # Security status
  sec = extract_text(html, /Security[:\s]*<[^>]*>([0-9.\-]+)</)
  sec ||= extract_text(html, /class="[^"]*sec[^"]*"[^>]*>([0-9.\-]+)</)
  puts "Security: #{sec}" if sec

  # Region
  region = extract_text(html, /Region[:\s]*<a[^>]*>([^<]+)</)
  puts "Region: #{region}" if region

  # Constellation
  constellation = extract_text(html, /Constellation[:\s]*<a[^>]*>([^<]+)</)
  puts "Constellation: #{constellation}" if constellation

  # Faction
  faction = extract_text(html, /Faction[:\s]*<[^>]*>([^<]+)</)
  puts "Faction: #{faction}" if faction

  # Stations
  stations = html.scan(/<a[^>]*href="\/outpost\/\d+"[^>]*>([^<]+)</).flatten
  stations += html.scan(/<td[^>]*class="[^"]*station[^"]*"[^>]*>([^<]+)</).flatten
  if stations.any?
    puts "Stations: #{stations.length}"
    stations.first(10).each { |s| puts "  - #{s.strip}" }
  end

  # Jumps (connected systems)
  jumps = html.scan(/<a[^>]*href="\/system\/([^"]+)"[^>]*class="[^"]*sys_name[^"]*"/).flatten
  jumps += html.scan(/<a[^>]*class="[^"]*sys[^"]*"[^>]*href="\/system\/([^"]+)"/).flatten
  jumps = jumps.uniq.map { |j| j.gsub("_", " ") }.reject { |j| j.downcase == name.downcase }
  if jumps.any?
    puts "Connected Systems: #{jumps.length}"
    jumps.each { |j| puts "  - #{j}" }
  end

  # Stats from tables — kills, jumps, NPC kills
  if html =~ /Ship Kills.*?(\d+)/m
    puts "Ship Kills (24h): #{$1}"
  end
  if html =~ /Pod Kills.*?(\d+)/m
    puts "Pod Kills (24h): #{$1}"
  end
  if html =~ /NPC Kills.*?(\d+)/m
    puts "NPC Kills (24h): #{$1}"
  end
  if html =~ /Jumps.*?(\d+)/m
    puts "Jumps (24h): #{$1}"
  end
end

def cmd_route(from, to, mode = nil)
  from_slug = from.gsub(" ", "_")
  to_slug = to.gsub(" ", "_")

  # DOTLAN route URL
  route_type = case mode
  when "--safest", "safest", "safe" then ":2"  # safest (prefer high-sec)
  when "--shortest", "shortest", "short" then ""  # shortest
  else ""  # default shortest
  end

  url = "#{DOTLAN_BASE}/route/#{from_slug}#{route_type}:#{to_slug}"
  html = fetch_html(url)
  unless html
    puts "ERROR: Could not fetch route #{from} -> #{to}"
    return
  end

  puts "Route: #{from} → #{to}"
  puts "Mode: #{mode || "shortest"}"
  puts "URL: #{url}"

  # Extract systems from the route
  systems = html.scan(/<td[^>]*class="[^"]*route_sys[^"]*"[^>]*>.*?<a[^>]*>([^<]+)</m).flatten
  systems = html.scan(/<a[^>]*href="\/system\/([^"]+)"[^>]*class="[^"]*sysname[^"]*"/).flatten.map { |s| s.gsub("_", " ") } if systems.empty?

  # Also try extracting from route table rows
  if systems.empty?
    systems = html.scan(/<a[^>]*href="\/system\/([^"]+)"/).flatten.map { |s| s.gsub("_", " ") }.uniq
    # Filter to just the route systems (exclude nav/header links)
    systems = systems.reject { |s| %w[Map Search].include?(s) }
  end

  if systems.any?
    puts "Jumps: #{[systems.length - 1, 0].max}"
    puts "Systems:"
    systems.each_with_index do |sys, i|
      marker = ""
      marker = " [START]" if i == 0
      marker = " [END]" if i == systems.length - 1
      puts "  #{i}. #{sys}#{marker}"
    end
  else
    puts "Could not parse route systems. Check URL manually."
  end
end

def cmd_region(name, mode = nil)
  slug = name.gsub(" ", "_")
  fragment = case mode
  when "sec", "security" then "#sec"
  when "sov", "sovereignty" then "#sov"
  when "kills" then "#kills"
  when "jumps" then "#jumps"
  when "npc" then "#npc24"
  else "#sec"
  end

  url = "#{DOTLAN_BASE}/map/#{slug}#{fragment}"
  puts "Region: #{name}"
  puts "View: #{mode || "security"}"
  puts "URL: #{url}"
end

def cmd_nearby(name)
  slug = name.gsub(" ", "_")
  html = fetch_html("#{DOTLAN_BASE}/system/#{slug}")
  unless html
    puts "ERROR: Could not fetch system #{name}"
    return
  end

  # Extract connected systems with security
  jumps = html.scan(/<a[^>]*href="\/system\/([^"]+)"/).flatten
    .map { |j| j.gsub("_", " ") }
    .uniq
    .reject { |j| j.downcase == name.downcase || j.length < 2 }

  puts "Systems adjacent to #{name}:"
  jumps.first(20).each do |sys|
    puts "  - #{sys}"
  end
end

# --- Main ---

command = ARGV.shift
case command
when "system", "sys"
  cmd_system(ARGV.join(" "))
when "route"
  # Parse --safest/--shortest flag
  mode = nil
  args = ARGV.dup
  if args.include?("--safest") || args.include?("--safe")
    mode = "--safest"
    args.delete("--safest")
    args.delete("--safe")
  elsif args.include?("--shortest") || args.include?("--short")
    mode = "--shortest"
    args.delete("--shortest")
    args.delete("--short")
  end
  from = args.shift
  to = args.join(" ")
  cmd_route(from, to, mode)
when "region"
  name = []
  mode = nil
  ARGV.each do |arg|
    if %w[sec security sov sovereignty kills jumps npc].include?(arg)
      mode = arg
    else
      name << arg
    end
  end
  cmd_region(name.join(" "), mode)
when "nearby", "adj"
  cmd_nearby(ARGV.join(" "))
else
  puts "EVE DOTLAN EveMaps"
  puts ""
  puts "Usage: ruby eve-dotlan.rb <command> [args...]"
  puts ""
  puts "Commands:"
  puts "  system <name>                    System info (security, stations, kills)"
  puts "  route <from> <to> [--safest]     Jump route between systems"
  puts "  region <name> [sec|sov|kills]    Region map URL"
  puts "  nearby <name>                    Adjacent systems"
end
