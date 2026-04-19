#!/usr/bin/env ruby
# frozen_string_literal: true

# EVE Survival mission guide lookup
# Usage: ruby eve-survival.rb <mission_name> [level] [faction]
#
# URL pattern: https://eve-survival.org/?wakka={MissionName}{Level}{Faction}
# Mission name is CamelCase, level is 1-5, faction is 2-letter code.
#
# Examples:
#   ruby eve-survival.rb "Pirate Invasion" 4 sansha
#   ruby eve-survival.rb PirateInvasion 4 sa
#   ruby eve-survival.rb Blockade 3 guristas
#   ruby eve-survival.rb "The Assault" 4

require "net/http"
require "uri"

BASE_URL = "https://eve-survival.org"

FACTION_CODES = {
  "angel" => "an", "angels" => "an", "angel cartel" => "an", "an" => "an",
  "blood" => "br", "blood raider" => "br", "blood raiders" => "br", "br" => "br",
  "guristas" => "gu", "gurista" => "gu", "gu" => "gu",
  "sansha" => "sa", "sansha's nation" => "sa", "sa" => "sa",
  "serpentis" => "se", "serp" => "se", "se" => "se",
  "amarr" => "am", "am" => "am",
  "caldari" => "ca", "ca" => "ca",
  "gallente" => "ga", "ga" => "ga",
  "minmatar" => "mi", "mi" => "mi",
  "mercenary" => "me", "me" => "me",
  "rogue" => "rd", "rogue drone" => "rd", "rogue drones" => "rd", "rd" => "rd",
  "mordus" => "ml", "mordu" => "ml", "mordu's legion" => "ml", "ml" => "ml",
  "khanid" => "kh", "kh" => "kh",
  "eom" => "eo", "eo" => "eo",
}.freeze

def to_camel_case(name)
  # Already CamelCase? Return as-is.
  return name if name.match?(/\A[A-Z][a-zA-Z0-9]+\z/) && !name.include?(" ")

  name.split(/[\s_-]+/).map(&:capitalize).join
end

def resolve_faction(input)
  return nil if input.nil? || input.empty?
  key = input.strip.downcase
  FACTION_CODES[key] || (key.length == 2 ? key : nil)
end

def strip_html(html)
  # Remove script/style blocks
  text = html.gsub(/<script[^>]*>.*?<\/script>/mi, "")
  text = text.gsub(/<style[^>]*>.*?<\/style>/mi, "")

  # Extract just the page content — WikkaWiki uses <div id="content">
  # Content ends at <!--closing page content--> or <div class="commentheader">
  if text =~ /<div id="content">(.*?)<!--closing page content-->/mi
    text = $1
  elsif text =~ /<div id="content">(.*?)(?:<div[^>]*class="comment)/mi
    text = $1
  elsif text =~ /<div id="content">(.*)/mi
    text = $1
  end

  # Remove lastedit div (editor info at top)
  text = text.gsub(/<div class="lastedit">.*?<\/div>/mi, "")
  # Remove clear divs
  text = text.gsub(/<div style="clear:[^"]*">.*?<\/div>/mi, "")

  # Convert common HTML to readable text
  text = text.gsub(/<br\s*\/?>/i, "\n")
  text = text.gsub(/<\/p>/i, "\n\n")
  text = text.gsub(/<\/tr>/i, "\n")
  text = text.gsub(/<\/td>/i, " | ")
  text = text.gsub(/<\/th>/i, " | ")
  text = text.gsub(/<hr\s*\/?>/i, "\n---\n")
  text = text.gsub(/<li>/i, "\n- ")
  text = text.gsub(/<h1[^>]*>(.*?)<\/h1>/i) { "\n# #{$1}\n" }
  text = text.gsub(/<h2[^>]*>(.*?)<\/h2>/i) { "\n## #{$1}\n" }
  text = text.gsub(/<h3[^>]*>(.*?)<\/h3>/i) { "\n### #{$1}\n" }
  text = text.gsub(/<h4[^>]*>(.*?)<\/h4>/i) { "\n#### #{$1}\n" }
  text = text.gsub(/<h[5-6][^>]*>(.*?)<\/h[5-6]>/i) { "\n##### #{$1}\n" }

  # Bold/italic
  text = text.gsub(/<b>(.*?)<\/b>/i) { "**#{$1}**" }
  text = text.gsub(/<strong>(.*?)<\/strong>/i) { "**#{$1}**" }
  text = text.gsub(/<i>(.*?)<\/i>/i) { "*#{$1}*" }
  text = text.gsub(/<em>(.*?)<\/em>/i) { "*#{$1}*" }

  # Links — extract text
  text = text.gsub(/<a[^>]*>(.*?)<\/a>/mi) { $1 }

  # Images — skip
  text = text.gsub(/<img[^>]*>/i, "")

  # Strip remaining tags
  text = text.gsub(/<[^>]+>/, "")

  # Decode HTML entities
  text = text.gsub("&amp;", "&")
  text = text.gsub("&lt;", "<")
  text = text.gsub("&gt;", ">")
  text = text.gsub("&quot;", '"')
  text = text.gsub("&#39;", "'")
  text = text.gsub("&nbsp;", " ")
  text = text.gsub(/&#(\d+);/) { [$1.to_i].pack("U") }

  # Clean up whitespace
  text = text.gsub(/[ \t]+/, " ")
  text = text.gsub(/\n[ \t]+/, "\n")
  text = text.gsub(/\n{3,}/, "\n\n")
  text.strip
end

def fetch_mission(mission_name, level, faction)
  camel = to_camel_case(mission_name)
  faction_code = resolve_faction(faction)

  slug = "#{camel}#{level}#{faction_code}"
  url = "#{BASE_URL}/?wakka=#{slug}"

  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.open_timeout = 10
  http.read_timeout = 15

  response = http.get(uri.request_uri)

  if response.code != "200"
    # Try without faction code
    if faction_code
      slug_nofaction = "#{camel}#{level}"
      uri2 = URI.parse("#{BASE_URL}/?wakka=#{slug_nofaction}")
      response = http.get(uri2.request_uri)
      if response.code == "200" && !response.body.include?("doesn't exist yet")
        slug = slug_nofaction
        url = "#{BASE_URL}/?wakka=#{slug}"
      else
        $stderr.puts "ERROR: Page not found: #{url}"
        exit 1
      end
    else
      $stderr.puts "ERROR: Page not found: #{url}"
      exit 1
    end
  end

  body = response.body

  if body.include?("doesn't exist yet") || body.include?("This page doesn")
    # Try without faction
    if faction_code
      slug_nofaction = "#{camel}#{level}"
      uri2 = URI.parse("#{BASE_URL}/?wakka=#{slug_nofaction}")
      response = http.get(uri2.request_uri)
      if response.code == "200" && !response.body.include?("doesn't exist yet")
        body = response.body
        slug = slug_nofaction
        url = "#{BASE_URL}/?wakka=#{slug}"
      else
        $stderr.puts "ERROR: Mission not found. Tried: #{slug}, #{slug_nofaction}"
        $stderr.puts "URL: #{url}"
        exit 1
      end
    else
      $stderr.puts "ERROR: Mission not found: #{slug}"
      $stderr.puts "URL: #{url}"
      exit 1
    end
  end

  content = strip_html(body)

  puts "SOURCE: #{url}"
  puts "SLUG: #{slug}"
  puts "---"
  puts content
end

def usage
  puts <<~USAGE
    EVE Survival Mission Guide Lookup

    Usage: ruby eve-survival.rb <mission_name> [level] [faction]

    Arguments:
      mission_name  Mission name (quoted or CamelCase)
      level         Mission level 1-5 (default: 4)
      faction       Faction name or 2-letter code (optional)

    Faction codes:
      an=Angel  br=Blood  gu=Guristas  sa=Sansha  se=Serpentis
      am=Amarr  ca=Caldari  ga=Gallente  mi=Minmatar
      rd=Rogue Drone  ml=Mordus  me=Mercenary

    Examples:
      ruby eve-survival.rb "Pirate Invasion" 4 sansha
      ruby eve-survival.rb PirateInvasion 4 sa
      ruby eve-survival.rb Blockade 3 gu
      ruby eve-survival.rb "The Assault" 4
  USAGE
end

# --- Main ---

if ARGV.empty? || ARGV.include?("--help") || ARGV.include?("-h")
  usage
  exit 0
end

mission_name = ARGV[0]
level = ARGV[1] || "4"
faction = ARGV[2]

fetch_mission(mission_name, level, faction)
