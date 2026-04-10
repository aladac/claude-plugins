#!/usr/bin/env ruby
# frozen_string_literal: true

# EVE Online ESI API client — public endpoints only
# Usage: ruby eve-esi.rb <command> [args...]

require "json"
require "net/http"
require "uri"

BASE_URL = "https://esi.evetech.net/latest"
DATASOURCE = "tranquility"
IMAGES_URL = "https://images.evetech.net"

def esi_get(path, params = {})
  params[:datasource] = DATASOURCE
  query = params.map { |k, v| "#{k}=#{URI.encode_www_form_component(v)}" }.join("&")
  url = "#{BASE_URL}#{path}?#{query}"

  uri = URI(url)
  response = Net::HTTP.get_response(uri)

  case response.code.to_i
  when 200
    JSON.parse(response.body)
  when 404
    { error: "Not found", path: path }
  else
    { error: "HTTP #{response.code}", body: response.body[0..200] }
  end
rescue => e
  { error: e.message }
end

def esi_post(path, body, params = {})
  params[:datasource] = DATASOURCE
  query = params.map { |k, v| "#{k}=#{URI.encode_www_form_component(v)}" }.join("&")
  url = "#{BASE_URL}#{path}?#{query}"

  uri = URI(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  req = Net::HTTP::Post.new(uri)
  req["Content-Type"] = "application/json"
  req.body = body.to_json
  response = http.request(req)

  case response.code.to_i
  when 200
    JSON.parse(response.body)
  else
    { error: "HTTP #{response.code}", body: response.body[0..200] }
  end
rescue => e
  { error: e.message }
end

def cmd_status
  data = esi_get("/status/")
  if data.is_a?(Hash) && data[:error]
    puts JSON.pretty_generate(data)
    return
  end
  puts "Server: Tranquility"
  puts "Players Online: #{data["players"]}"
  puts "Server Version: #{data["server_version"]}"
  puts "Start Time: #{data["start_time"]}"
  vip = data["vip"] ? "YES — VIP mode active" : "No"
  puts "VIP Mode: #{vip}"
end

def cmd_character(id)
  data = esi_get("/characters/#{id}/")
  return puts JSON.pretty_generate(data) if data.is_a?(Hash) && data[:error]

  # Get affiliation
  affil = esi_post("/characters/affiliation/", [id.to_i])
  corp_id = affil.is_a?(Array) ? affil.first&.dig("corporation_id") : nil
  alliance_id = affil.is_a?(Array) ? affil.first&.dig("alliance_id") : nil

  corp_name = corp_id ? esi_get("/corporations/#{corp_id}/")&.dig("name") : nil
  alliance_name = alliance_id ? esi_get("/alliances/#{alliance_id}/")&.dig("name") : nil

  puts "Name: #{data["name"]}"
  puts "Birthday: #{data["birthday"]}"
  puts "Race: #{race_name(data["race_id"])}"
  puts "Bloodline: #{data["bloodline_id"]}"
  puts "Security Status: #{data["security_status"]&.round(2)}"
  puts "Corporation: #{corp_name} (#{corp_id})"
  puts "Alliance: #{alliance_name || "None"} (#{alliance_id || "-"})"
  puts "Description: #{data["description"]&.gsub(/<[^>]+>/, "")&.strip&.slice(0, 200)}"
  puts "Portrait: #{IMAGES_URL}/characters/#{id}/portrait?size=512"
end

def cmd_corporation(id)
  data = esi_get("/corporations/#{id}/")
  return puts JSON.pretty_generate(data) if data.is_a?(Hash) && data[:error]

  alliance_name = data["alliance_id"] ? esi_get("/alliances/#{data["alliance_id"]}/")&.dig("name") : nil
  ceo = esi_get("/characters/#{data["ceo_id"]}/")

  puts "Name: #{data["name"]}"
  puts "Ticker: [#{data["ticker"]}]"
  puts "Members: #{data["member_count"]}"
  puts "CEO: #{ceo&.dig("name")} (#{data["ceo_id"]})"
  puts "Alliance: #{alliance_name || "None"} (#{data["alliance_id"] || "-"})"
  puts "Tax Rate: #{(data["tax_rate"] * 100).round(1)}%"
  puts "Founded: #{data["date_founded"]}"
  puts "URL: #{data["url"]}" if data["url"]
  puts "Description: #{data["description"]&.gsub(/<[^>]+>/, "")&.strip&.slice(0, 200)}"
  puts "Logo: #{IMAGES_URL}/corporations/#{id}/logo?size=256"
end

def cmd_alliance(id)
  data = esi_get("/alliances/#{id}/")
  return puts JSON.pretty_generate(data) if data.is_a?(Hash) && data[:error]

  puts "Name: #{data["name"]}"
  puts "Ticker: [#{data["ticker"]}]"
  puts "Founded: #{data["date_founded"]}"
  puts "Creator Corp: #{data["creator_corporation_id"]}"
  puts "Creator: #{data["creator_id"]}"
  puts "Executor Corp: #{data["executor_corporation_id"]}"
  puts "Logo: #{IMAGES_URL}/alliances/#{id}/logo?size=128"
end

def cmd_alliance_corps(id)
  data = esi_get("/alliances/#{id}/corporations/")
  return puts JSON.pretty_generate(data) if data.is_a?(Hash) && data[:error]

  puts "Alliance #{id} — #{data.length} member corporations:"
  data.each do |corp_id|
    corp = esi_get("/corporations/#{corp_id}/")
    name = corp.is_a?(Hash) ? corp["name"] : "?"
    members = corp.is_a?(Hash) ? corp["member_count"] : "?"
    ticker = corp.is_a?(Hash) ? corp["ticker"] : "?"
    puts "  [#{ticker}] #{name} (#{corp_id}) — #{members} members"
  end
end

def cmd_search(category, term)
  valid = %w[character corporation alliance solar_system station inventory_type]
  unless valid.include?(category)
    puts "Invalid category: #{category}"
    puts "Valid: #{valid.join(", ")}"
    return
  end

  data = esi_get("/search/", categories: category, search: term, strict: false)
  return puts JSON.pretty_generate(data) if data.is_a?(Hash) && data[:error]

  results = data[category] || []
  puts "Search '#{term}' in #{category}: #{results.length} results"

  results.first(20).each do |id|
    case category
    when "character"
      info = esi_get("/characters/#{id}/")
      puts "  #{info["name"]} (#{id})" if info.is_a?(Hash) && info["name"]
    when "corporation"
      info = esi_get("/corporations/#{id}/")
      puts "  [#{info["ticker"]}] #{info["name"]} (#{id}) — #{info["member_count"]} members" if info.is_a?(Hash) && info["name"]
    when "alliance"
      info = esi_get("/alliances/#{id}/")
      puts "  [#{info["ticker"]}] #{info["name"]} (#{id})" if info.is_a?(Hash) && info["name"]
    when "solar_system"
      info = esi_get("/universe/systems/#{id}/")
      puts "  #{info["name"]} (#{id}) — sec #{info["security_status"]&.round(2)}" if info.is_a?(Hash) && info["name"]
    when "station"
      info = esi_get("/universe/stations/#{id}/")
      puts "  #{info["name"]} (#{id})" if info.is_a?(Hash) && info["name"]
    when "inventory_type"
      info = esi_get("/universe/types/#{id}/")
      puts "  #{info["name"]} (#{id})" if info.is_a?(Hash) && info["name"]
    else
      puts "  ID: #{id}"
    end
  end
end

def cmd_prices
  data = esi_get("/markets/prices/")
  return puts JSON.pretty_generate(data) if data.is_a?(Hash) && data[:error]

  puts "Market prices: #{data.length} types"
  puts "Format: type_id | average_price | adjusted_price"
  puts "-" * 50
  # Show top 20 by average price
  sorted = data.sort_by { |p| -(p["average_price"] || 0) }
  sorted.first(20).each do |p|
    avg = p["average_price"]&.round(2) || "N/A"
    adj = p["adjusted_price"]&.round(2) || "N/A"
    puts "  #{p["type_id"]} | #{avg} ISK | #{adj} ISK (adj)"
  end
  puts "... (#{data.length - 20} more)" if data.length > 20
end

def cmd_orders(region_id, type_id)
  data = esi_get("/markets/#{region_id}/orders/", type_id: type_id, order_type: "all")
  return puts JSON.pretty_generate(data) if data.is_a?(Hash) && data[:error]

  sell = data.select { |o| !o["is_buy_order"] }.sort_by { |o| o["price"] }
  buy = data.select { |o| o["is_buy_order"] }.sort_by { |o| -o["price"] }

  puts "Market Orders — Region #{region_id}, Type #{type_id}"
  puts "Total: #{data.length} orders (#{sell.length} sell, #{buy.length} buy)"
  puts ""

  if sell.any?
    puts "SELL (lowest 10):"
    sell.first(10).each do |o|
      loc = o["location_id"]
      puts "  #{"%.2f" % o["price"]} ISK x#{o["volume_remain"]}/#{o["volume_total"]} @ #{loc}"
    end
    puts ""
  end

  if buy.any?
    puts "BUY (highest 10):"
    buy.first(10).each do |o|
      loc = o["location_id"]
      puts "  #{"%.2f" % o["price"]} ISK x#{o["volume_remain"]}/#{o["volume_total"]} @ #{loc}"
    end
  end

  if sell.any? && buy.any?
    spread = sell.first["price"] - buy.first["price"]
    puts ""
    puts "Spread: #{"%.2f" % spread} ISK (#{"%.2f" % (spread / sell.first["price"] * 100)}%)"
  end
end

def cmd_history(region_id, type_id)
  data = esi_get("/markets/#{region_id}/history/", type_id: type_id)
  return puts JSON.pretty_generate(data) if data.is_a?(Hash) && data[:error]

  puts "Price History — Region #{region_id}, Type #{type_id}"
  puts "#{data.length} days of history"
  puts ""
  puts "Date       | Avg Price     | Volume    | Orders | Low-High"
  puts "-" * 75

  # Show last 14 days
  data.last(14).each do |d|
    avg = "%.2f" % d["average"]
    low = "%.2f" % d["lowest"]
    high = "%.2f" % d["highest"]
    puts "#{d["date"]} | #{avg.rjust(13)} | #{d["volume"].to_s.rjust(9)} | #{d["order_count"].to_s.rjust(6)} | #{low}-#{high}"
  end
end

def cmd_type(id)
  data = esi_get("/universe/types/#{id}/")
  return puts JSON.pretty_generate(data) if data.is_a?(Hash) && data[:error]

  puts "Name: #{data["name"]}"
  puts "Type ID: #{data["type_id"]}"
  puts "Group ID: #{data["group_id"]}"
  puts "Mass: #{data["mass"]} kg" if data["mass"]
  puts "Volume: #{data["volume"]} m3" if data["volume"]
  puts "Capacity: #{data["capacity"]} m3" if data["capacity"]
  puts "Portion Size: #{data["portion_size"]}"
  puts "Published: #{data["published"]}"
  puts "Market Group: #{data["market_group_id"]}" if data["market_group_id"]
  puts "Description: #{data["description"]&.gsub(/<[^>]+>/, "")&.strip&.slice(0, 300)}"
  puts "Icon: #{IMAGES_URL}/types/#{id}/icon?size=64"
end

def cmd_system(id)
  data = esi_get("/universe/systems/#{id}/")
  return puts JSON.pretty_generate(data) if data.is_a?(Hash) && data[:error]

  puts "Name: #{data["name"]}"
  puts "System ID: #{data["system_id"]}"
  puts "Constellation ID: #{data["constellation_id"]}"
  puts "Security Status: #{data["security_status"]&.round(4)}"
  sec = data["security_status"]
  sec_class = if sec >= 0.5 then "High-sec"
  elsif sec > 0.0 then "Low-sec"
  else "Null-sec"
  end
  puts "Security Class: #{sec_class}"
  puts "Star ID: #{data["star_id"]}" if data["star_id"]
  puts "Stargates: #{data["stargates"]&.length || 0}"
  puts "Stations: #{data["stations"]&.length || 0}"
  puts "Planets: #{data["planets"]&.length || 0}"
end

def cmd_sovereignty
  data = esi_get("/sovereignty/map/")
  return puts JSON.pretty_generate(data) if data.is_a?(Hash) && data[:error]

  puts "Sovereignty Map: #{data.length} systems"
  # Count by alliance
  alliances = data.group_by { |s| s["alliance_id"] }
    .reject { |k, _| k.nil? }
    .sort_by { |_, v| -v.length }

  puts "Top 20 alliances by system count:"
  alliances.first(20).each do |alliance_id, systems|
    info = esi_get("/alliances/#{alliance_id}/")
    name = info.is_a?(Hash) ? info["name"] : "Unknown"
    puts "  #{name} (#{alliance_id}): #{systems.length} systems"
  end
end

def cmd_portrait(id)
  puts "#{IMAGES_URL}/characters/#{id}/portrait?size=512"
end

def race_name(id)
  case id
  when 1 then "Caldari"
  when 2 then "Minmatar"
  when 4 then "Amarr"
  when 8 then "Gallente"
  else "Unknown (#{id})"
  end
end

# --- Main ---

command = ARGV.shift
case command
when "status"
  cmd_status
when "character", "char"
  cmd_character(ARGV.shift)
when "corporation", "corp"
  cmd_corporation(ARGV.shift)
when "alliance"
  cmd_alliance(ARGV.shift)
when "alliance-corps"
  cmd_alliance_corps(ARGV.shift)
when "search"
  cmd_search(ARGV.shift, ARGV.join(" "))
when "prices"
  cmd_prices
when "orders"
  cmd_orders(ARGV.shift, ARGV.shift)
when "history"
  cmd_history(ARGV.shift, ARGV.shift)
when "type"
  cmd_type(ARGV.shift)
when "system"
  cmd_system(ARGV.shift)
when "sovereignty", "sov"
  cmd_sovereignty
when "portrait"
  cmd_portrait(ARGV.shift)
else
  puts "EVE ESI API Client"
  puts ""
  puts "Usage: ruby eve-esi.rb <command> [args...]"
  puts ""
  puts "Commands:"
  puts "  status                          Server status"
  puts "  character <id>                  Character info"
  puts "  corporation <id>                Corp info"
  puts "  alliance <id>                   Alliance info"
  puts "  alliance-corps <id>             Corps in alliance"
  puts "  search <category> <term>        Search ESI"
  puts "  prices                          All market avg prices"
  puts "  orders <region_id> <type_id>    Market orders"
  puts "  history <region_id> <type_id>   Price history"
  puts "  type <id>                       Item type info"
  puts "  system <id>                     Solar system info"
  puts "  sovereignty                     Sov map"
  puts "  portrait <id>                   Portrait URL"
end
