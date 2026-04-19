#!/usr/bin/env ruby
# frozen_string_literal: true

# EVE University Wiki lookup via MediaWiki API
# Usage: ruby eve-uni.rb <command> [args...]
#
# Commands:
#   search <query>          Search wiki pages
#   page <title>            Get full page content (parsed to text)
#   section <title> <name>  Get a specific section from a page
#   categories <title>      List categories for a page
#
# Examples:
#   ruby eve-uni.rb search "shield tanking"
#   ruby eve-uni.rb page "Tengu"
#   ruby eve-uni.rb page "Pirate Invasion"
#   ruby eve-uni.rb section "Tengu" "Fittings"

require "json"
require "net/http"
require "uri"
require "cgi"

API_URL = "https://wiki.eveuniversity.org/api.php"

def api_get(params)
  params["format"] = "json"
  query = params.map { |k, v| "#{CGI.escape(k)}=#{CGI.escape(v)}" }.join("&")
  uri = URI.parse("#{API_URL}?#{query}")

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.open_timeout = 10
  http.read_timeout = 15

  response = http.get(uri.request_uri)

  unless response.code == "200"
    $stderr.puts "ERROR: API returned #{response.code}"
    exit 1
  end

  JSON.parse(response.body)
end

def strip_html(html)
  text = html.dup

  # Remove edit sections, toc, scripts, styles
  text.gsub!(/<span class="mw-editsection">.*?<\/span>/mi, "")
  text.gsub!(/<div id="toc"[^>]*>.*?<\/div>/mi, "")
  text.gsub!(/<script[^>]*>.*?<\/script>/mi, "")
  text.gsub!(/<style[^>]*>.*?<\/style>/mi, "")

  # Convert structural HTML
  text.gsub!(/<h1[^>]*>(.*?)<\/h1>/i) { "\n# #{$1}\n" }
  text.gsub!(/<h2[^>]*>(.*?)<\/h2>/i) { "\n## #{$1}\n" }
  text.gsub!(/<h3[^>]*>(.*?)<\/h3>/i) { "\n### #{$1}\n" }
  text.gsub!(/<h4[^>]*>(.*?)<\/h4>/i) { "\n#### #{$1}\n" }
  text.gsub!(/<br\s*\/?>/i, "\n")
  text.gsub!(/<\/p>/i, "\n\n")
  text.gsub!(/<\/tr>/i, "\n")
  text.gsub!(/<\/td>/i, " | ")
  text.gsub!(/<\/th>/i, " | ")
  text.gsub!(/<hr\s*\/?>/i, "\n---\n")
  text.gsub!(/<li>/i, "\n- ")
  text.gsub!(/<\/li>/i, "")
  text.gsub!(/<a[^>]*href="([^"]*)"[^>]*>(.*?)<\/a>/i) { $2 }

  # Strip remaining tags
  text.gsub!(/<[^>]+>/, "")

  # Decode entities
  text.gsub!("&amp;", "&")
  text.gsub!("&lt;", "<")
  text.gsub!("&gt;", ">")
  text.gsub!("&quot;", '"')
  text.gsub!("&#39;", "'")
  text.gsub!("&nbsp;", " ")

  # Clean whitespace
  text.gsub!(/\n{3,}/, "\n\n")
  text.strip
end

def cmd_search(query)
  data = api_get(
    "action" => "query",
    "list" => "search",
    "srsearch" => query,
    "srlimit" => "15",
    "srprop" => "snippet|titlesnippet|size"
  )

  results = data.dig("query", "search") || []
  if results.empty?
    puts "No results for: #{query}"
    exit 0
  end

  puts "SEARCH: #{query}"
  puts "RESULTS: #{results.size}"
  puts "---"

  results.each_with_index do |r, i|
    snippet = strip_html(r["snippet"] || "").gsub("\n", " ").strip
    puts "#{i + 1}. #{r["title"]} (#{r["size"]} bytes)"
    puts "   #{snippet[0, 120]}" unless snippet.empty?
    puts "   URL: https://wiki.eveuniversity.org/#{CGI.escape(r["title"].tr(" ", "_"))}"
  end
end

def cmd_page(title)
  data = api_get(
    "action" => "parse",
    "page" => title,
    "prop" => "wikitext|categories|displaytitle"
  )

  if data["error"]
    # Try searching if page not found directly
    $stderr.puts "Page '#{title}' not found. Searching..."
    cmd_search(title)
    return
  end

  parsed = data["parse"]
  display = parsed["displaytitle"] || title
  content = parsed.dig("wikitext", "*") || ""
  cats = (parsed["categories"] || []).map { |c| c["*"] }

  # Clean up wikitext for readability
  content = clean_wikitext(content)

  puts "PAGE: #{strip_html(display)}"
  puts "URL: https://wiki.eveuniversity.org/#{CGI.escape(title.tr(" ", "_"))}"
  puts "CATEGORIES: #{cats.first(8).join(", ")}" unless cats.empty?
  puts "---"
  puts content
end

def clean_wikitext(text)
  # Remove templates that produce nav boxes
  text = text.gsub(/\{\{[Nn]avbox[^}]*\}\}/m, "")
  text = text.gsub(/\{\{[Mm]ission[_ ]?[Rr]eports[^}]*\}\}/m, "")
  # Simplify internal links: [[Page|Display]] -> Display, [[Page]] -> Page
  text = text.gsub(/\[\[(?:[^|\]]*\|)?([^\]]*)\]\]/) { $1 }
  # External links: [url text] -> text
  text = text.gsub(/\[https?:\/\/[^\s\]]+ ([^\]]+)\]/) { $1 }
  text = text.gsub(/\[https?:\/\/[^\]]+\]/, "")
  # Bold/italic
  text = text.gsub("'''", "**")
  text = text.gsub("''", "*")
  # Strip remaining complex templates but keep simple ones
  text = text.gsub(/\{\{[^{}]{200,}\}\}/m, "")
  text.strip
end

def cmd_section(title, section_name)
  # First get sections list
  data = api_get(
    "action" => "parse",
    "page" => title,
    "prop" => "sections"
  )

  if data["error"]
    $stderr.puts "ERROR: Page '#{title}' not found"
    exit 1
  end

  sections = data.dig("parse", "sections") || []
  match = sections.find { |s| s["line"].downcase.include?(section_name.downcase) }

  unless match
    puts "SECTIONS in #{title}:"
    sections.each { |s| puts "  #{s["index"]}. #{s["line"]} (level #{s["level"]})" }
    exit 0
  end

  data = api_get(
    "action" => "parse",
    "page" => title,
    "prop" => "wikitext",
    "section" => match["index"]
  )

  content = data.dig("parse", "wikitext", "*") || ""
  content = clean_wikitext(content)

  puts "PAGE: #{title}"
  puts "SECTION: #{match["line"]}"
  puts "---"
  puts content
end

def cmd_categories(title)
  data = api_get(
    "action" => "query",
    "titles" => title,
    "prop" => "categories",
    "cllimit" => "50"
  )

  pages = data.dig("query", "pages") || {}
  page = pages.values.first
  cats = (page["categories"] || []).map { |c| c["title"].sub("Category:", "") }

  puts "PAGE: #{title}"
  puts "CATEGORIES: #{cats.size}"
  puts "---"
  cats.each { |c| puts "- #{c}" }
end

def usage
  puts <<~USAGE
    EVE University Wiki Lookup

    Usage: ruby eve-uni.rb <command> [args...]

    Commands:
      search <query>            Search wiki pages
      page <title>              Get full page content
      section <title> <name>    Get a specific section
      categories <title>        List page categories

    Examples:
      ruby eve-uni.rb search "shield tanking"
      ruby eve-uni.rb page "Tengu"
      ruby eve-uni.rb page "Pirate Invasion"
      ruby eve-uni.rb section "Tengu" "Fittings"
      ruby eve-uni.rb categories "Caldari ships"
  USAGE
end

# --- Main ---

if ARGV.empty? || ARGV.include?("--help") || ARGV.include?("-h")
  usage
  exit 0
end

command = ARGV[0]

case command
when "search"
  query = ARGV[1..].join(" ")
  abort "Usage: ruby eve-uni.rb search <query>" if query.empty?
  cmd_search(query)
when "page"
  title = ARGV[1..].join(" ")
  abort "Usage: ruby eve-uni.rb page <title>" if title.empty?
  cmd_page(title)
when "section"
  title = ARGV[1]
  section = ARGV[2..].join(" ")
  abort "Usage: ruby eve-uni.rb section <title> <section_name>" if title.nil? || section.empty?
  cmd_section(title, section)
when "categories"
  title = ARGV[1..].join(" ")
  abort "Usage: ruby eve-uni.rb categories <title>" if title.empty?
  cmd_categories(title)
else
  $stderr.puts "Unknown command: #{command}"
  usage
  exit 1
end
