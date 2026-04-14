#!/usr/bin/env ruby
# frozen_string_literal: true

# EVE Online ESI API client — public + authenticated endpoints
# Usage: ruby eve-esi.rb <command> [args...]
#
# Auth via 1Password: `op item get eve-esi --vault DEV`
# Supports: Spinister (default), Battletrap, Amy (via --char flag)

require "json"
require "net/http"
require "uri"
require "base64"

# SDE for offline static data lookups
SDE_AVAILABLE = begin
  require "sde"
  true
rescue LoadError
  false
end

BASE_URL = "https://esi.evetech.net/latest"
DATASOURCE = "tranquility"
IMAGES_URL = "https://images.evetech.net"
LOGIN_URL = "https://login.eveonline.com/v2/oauth/token"

# --- SDE helpers (offline, instant) ---

def sde_system_name(id)
  return nil unless SDE_AVAILABLE
  sys = SDE::MapSolarSystem.find(id.to_i)
  sys&.name&.dig("en")
rescue
  nil
end

def sde_system(id)
  return nil unless SDE_AVAILABLE
  SDE::MapSolarSystem.find(id.to_i)
rescue
  nil
end

def sde_constellation_name(id)
  return nil unless SDE_AVAILABLE
  c = SDE::MapConstellation.find(id.to_i)
  c&.name&.dig("en")
rescue
  nil
end

def sde_region_name(id)
  return nil unless SDE_AVAILABLE
  r = SDE::MapRegion.find(id.to_i)
  r&.name&.dig("en")
rescue
  nil
end

def sde_type_name(id)
  return nil unless SDE_AVAILABLE
  t = SDE::Type.find(id.to_i)
  t&.name&.dig("en")
rescue
  nil
end

def sde_type(id)
  return nil unless SDE_AVAILABLE
  SDE::Type.find(id.to_i)
rescue
  nil
end

def roman(n)
  %w[0 I II III IV V VI VII VIII IX X XI XII XIII XIV XV XVI XVII XVIII XIX XX][n] || n.to_s
end

def sde_station(id)
  return nil unless SDE_AVAILABLE
  SDE::NpcStation.find(id.to_i)
rescue
  nil
end

def sde_station_name(id)
  return nil unless SDE_AVAILABLE
  st = SDE::NpcStation.find(id.to_i)
  return nil unless st

  # Derive: SystemName PlanetRoman - Moon MoonIndex - CorpName OperationName
  sys = SDE::MapSolarSystem.find(st.solarSystemID)
  sys_name = sys&.name&.dig("en") || st.solarSystemID.to_s

  # Find which planet/moon this station orbits
  planet_index = st.celestialIndex
  moon = SDE::MapMoon.find(st.orbitID) rescue nil
  if moon
    # Station is on a moon — find parent planet
    planet = SDE::MapPlanet.find(moon.orbitID) rescue nil
    planet_idx = planet&.celestialIndex || planet_index
    moon_idx = moon.orbitIndex
    location = "#{sys_name} #{roman(planet_idx)} - Moon #{moon_idx}"
  else
    # Station orbits a planet directly
    planet = SDE::MapPlanet.find(st.orbitID) rescue nil
    planet_idx = planet&.celestialIndex || planet_index
    location = "#{sys_name} #{roman(planet_idx)}"
  end

  corp = SDE::NpcCorporation.find(st.ownerID) rescue nil
  corp_name = corp&.name&.dig("en") || st.ownerID.to_s

  op = SDE::StationOperation.find(st.operationID) rescue nil
  op_name = op&.operationName&.dig("en") || ""

  "#{location} - #{corp_name} #{op_name}".strip
rescue
  nil
end

# Resolve system name — SDE first, API fallback
def resolve_system_name(id)
  sde_system_name(id) || esi_get("/universe/systems/#{id}/")&.dig("name") || id.to_s
end

# Resolve type name — SDE first, API fallback
def resolve_type_name(id)
  sde_type_name(id) || esi_get("/universe/types/#{id}/")&.dig("name") || id.to_s
end

# Resolve station name — SDE first, API fallback
def resolve_station_name(id)
  sde_station_name(id) || esi_get("/universe/stations/#{id}/")&.dig("name") || id.to_s
end

# Resolve system ID from name — SDE search
def resolve_system_id(name)
  return name.to_i if name.match?(/^\d+$/)
  return nil unless SDE_AVAILABLE
  SDE::MapSolarSystem.all.each do |id, sys|
    return id if sys.name&.dig("en")&.downcase == name.downcase
  end
  nil
rescue
  nil
end

# Resolve type ID from name — SDE search
def resolve_type_id(name)
  return name.to_i if name.match?(/^\d+$/)
  return nil unless SDE_AVAILABLE
  SDE::Type.all.each do |id, t|
    return id if t.name&.dig("en")&.downcase == name.downcase
  end
  nil
rescue
  nil
end

# SDE search — returns array of formatted result strings, or nil if category not in SDE
def sde_search(category, term)
  return nil unless SDE_AVAILABLE
  term_down = term.downcase
  case category
  when "solar_system"
    results = []
    SDE::MapSolarSystem.all.each do |id, s|
      name = s.name&.dig("en")
      next unless name&.downcase&.include?(term_down)
      results << "#{name} (#{id}) — sec #{s.securityStatus&.round(2)}"
    end
    results
  when "station"
    results = []
    SDE::NpcStation.all.each do |id, s|
      name = s.stationName rescue nil
      next unless name&.downcase&.include?(term_down)
      results << "#{name} (#{id})"
    end
    results
  when "inventory_type"
    results = []
    SDE::Type.all.each do |id, t|
      name = t.name&.dig("en")
      next unless name&.downcase&.include?(term_down)
      results << "#{name} (#{id})"
    end
    results
  else
    nil # characters, corps, alliances — not in SDE, fall through to ESI
  end
rescue
  nil
end

# Character map — name to 1Password refresh token field
CHARACTERS = {
  "spinister"  => { id: 2119104851, token_field: "refresh_token" },
  "battletrap" => { id: 2119255298, token_field: "refresh_token_battletrap" },
  "amy"        => { id: 2116789099, token_field: "refresh_token_amy" },
}.freeze

DEFAULT_CHAR = "spinister"

# Cache access token in memory for the process lifetime
@access_token = nil
@active_char = DEFAULT_CHAR

def get_credentials
  json = `op item get eve-esi --vault DEV --format json 2>/dev/null`
  return nil if json.empty?
  data = JSON.parse(json)
  fields = {}
  data["fields"]&.each { |f| fields[f["label"]] = f["value"] if f["label"] && f["value"] }
  fields
rescue
  nil
end

def refresh_access_token(char_name = nil)
  char_name ||= @active_char
  creds = get_credentials
  unless creds
    $stderr.puts "ERROR: Cannot read eve-esi from 1Password"
    return nil
  end

  char = CHARACTERS[char_name.downcase]
  unless char
    $stderr.puts "ERROR: Unknown character '#{char_name}'. Known: #{CHARACTERS.keys.join(", ")}"
    return nil
  end

  refresh_token = creds[char[:token_field]]
  unless refresh_token
    $stderr.puts "ERROR: No refresh token for #{char_name} (field: #{char[:token_field]})"
    return nil
  end

  client_id = creds["client_id"]
  client_secret = creds["client_secret"]

  uri = URI(LOGIN_URL)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  req = Net::HTTP::Post.new(uri)
  req["Content-Type"] = "application/x-www-form-urlencoded"
  req["Authorization"] = "Basic #{Base64.strict_encode64("#{client_id}:#{client_secret}")}"
  req.body = URI.encode_www_form(grant_type: "refresh_token", refresh_token: refresh_token)

  response = http.request(req)
  if response.code.to_i == 200
    data = JSON.parse(response.body)
    @access_token = data["access_token"]
    @access_token
  else
    $stderr.puts "ERROR: Token refresh failed (HTTP #{response.code}): #{response.body[0..200]}"
    nil
  end
rescue => e
  $stderr.puts "ERROR: Token refresh failed: #{e.message}"
  nil
end

def ensure_token(char_name = nil)
  @access_token || refresh_access_token(char_name)
end

def esi_get_auth(path, params = {}, char_name: nil)
  token = ensure_token(char_name)
  return { error: "No access token" } unless token

  params[:datasource] = DATASOURCE
  query = params.map { |k, v| "#{k}=#{URI.encode_www_form_component(v)}" }.join("&")
  url = "#{BASE_URL}#{path}?#{query}"

  uri = URI(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  req = Net::HTTP::Get.new(uri)
  req["Authorization"] = "Bearer #{token}"
  response = http.request(req)

  case response.code.to_i
  when 200
    JSON.parse(response.body)
  when 403
    # Token might be expired, try refresh once
    @access_token = nil
    token = refresh_access_token(char_name)
    return { error: "Auth failed after refresh" } unless token
    req2 = Net::HTTP::Get.new(uri)
    req2["Authorization"] = "Bearer #{token}"
    resp2 = http.request(req2)
    resp2.code.to_i == 200 ? JSON.parse(resp2.body) : { error: "HTTP #{resp2.code}", body: resp2.body[0..200] }
  else
    { error: "HTTP #{response.code}", body: response.body[0..200] }
  end
rescue => e
  { error: e.message }
end

def esi_post_auth(path, body = nil, params = {}, char_name: nil)
  token = ensure_token(char_name)
  return { error: "No access token" } unless token

  params[:datasource] = DATASOURCE
  query = params.map { |k, v| "#{k}=#{URI.encode_www_form_component(v)}" }.join("&")
  url = "#{BASE_URL}#{path}?#{query}"

  uri = URI(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  req = Net::HTTP::Post.new(uri)
  req["Authorization"] = "Bearer #{token}"
  req["Content-Type"] = "application/json"
  req.body = body.to_json if body
  response = http.request(req)

  case response.code.to_i
  when 200
    (response.body.nil? || response.body.empty?) ? { ok: true } : JSON.parse(response.body)
  when 204
    { ok: true }
  else
    { error: "HTTP #{response.code}", body: (response.body || "")[0..200] }
  end
rescue => e
  { error: e.message }
end

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

  corp_name = corp_id ? (esi_get("/corporations/#{corp_id}/")&.dig("name")) : nil
  alliance_name = alliance_id ? (esi_get("/alliances/#{alliance_id}/")&.dig("name")) : nil

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

  # SDE search for static categories (no API call needed)
  if SDE_AVAILABLE
    sde_results = sde_search(category, term)
    if sde_results && !sde_results.empty?
      puts "Search '#{term}' in #{category}: #{sde_results.length} results (SDE)"
      sde_results.first(20).each { |line| puts "  #{line}" }
      return
    end
  end

  # Fallback to ESI
  data = esi_get("/search/", categories: category, search: term, strict: false)
  return puts JSON.pretty_generate(data) if data.is_a?(Hash) && data[:error]

  results = data[category] || []
  puts "Search '#{term}' in #{category}: #{results.length} results (ESI)"

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
  # Try name-to-ID resolution if not numeric
  unless id.to_s.match?(/^\d+$/)
    resolved = resolve_type_id(id)
    if resolved
      id = resolved
    else
      puts "Type '#{id}' not found"
      return
    end
  end

  # SDE first
  t = sde_type(id)
  if t
    name = t.name&.dig("en") || id.to_s
    desc = t.description&.dig("en")&.gsub(/<[^>]+>/, "")&.strip&.slice(0, 300)
    puts "Name: #{name}"
    puts "Type ID: #{id}"
    puts "Group ID: #{t.groupID}"
    puts "Mass: #{t.mass} kg" if t.mass
    puts "Volume: #{t.volume} m3" if t.volume
    puts "Capacity: #{t.capacity} m3" if t.capacity
    puts "Portion Size: #{t.portionSize}"
    puts "Published: #{t.published}"
    puts "Market Group: #{t.marketGroupID}" if t.marketGroupID
    puts "Description: #{desc}" if desc
    puts "Icon: #{IMAGES_URL}/types/#{id}/icon?size=64"
    puts "Source: SDE (offline)"
    return
  end

  # Fallback to ESI
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
  puts "Source: ESI (online)"
end

def cmd_system(id)
  # Try name-to-ID resolution if not numeric
  unless id.to_s.match?(/^\d+$/)
    resolved = resolve_system_id(id)
    if resolved
      id = resolved
    else
      # Fallback: ESI search
      data = esi_get("/search/", categories: "solar_system", search: id, strict: true)
      ids = data.is_a?(Hash) ? data["solar_system"] : nil
      if ids&.any?
        id = ids.first
      else
        puts "System '#{id}' not found"
        return
      end
    end
  end

  # SDE first
  sys = sde_system(id)
  if sys
    name = sys.name&.dig("en") || id.to_s
    sec = sys.securityStatus
    sec_class = if sec && sec >= 0.45 then "High-sec"
    elsif sec && sec > 0.0 then "Low-sec"
    else "Null-sec"
    end
    constellation = sde_constellation_name(sys.constellationID) || sys.constellationID.to_s
    region = sde_region_name(sys.regionID) || sys.regionID.to_s

    puts "Name: #{name}"
    puts "System ID: #{id}"
    puts "Region: #{region} (#{sys.regionID})"
    puts "Constellation: #{constellation} (#{sys.constellationID})"
    puts "Security Status: #{sec&.round(4)}"
    puts "Security Class: #{sec_class}"
    puts "Star ID: #{sys.starID}" if sys.starID
    puts "Stargates: #{sys.stargateIDs&.length || 0}"
    puts "Planets: #{sys.planetIDs&.length || 0}"
    puts "Source: SDE (offline)"
    return
  end

  # Fallback to ESI
  data = esi_get("/universe/systems/#{id}/")
  return puts JSON.pretty_generate(data) if data.is_a?(Hash) && data[:error]

  puts "Name: #{data["name"]}"
  puts "System ID: #{data["system_id"]}"
  puts "Constellation ID: #{data["constellation_id"]}"
  puts "Security Status: #{data["security_status"]&.round(4)}"
  sec = data["security_status"]
  sec_class = if sec && sec >= 0.45 then "High-sec"
  elsif sec && sec > 0.0 then "Low-sec"
  else "Null-sec"
  end
  puts "Security Class: #{sec_class}"
  puts "Star ID: #{data["star_id"]}" if data["star_id"]
  puts "Stargates: #{data["stargates"]&.length || 0}"
  puts "Stations: #{data["stations"]&.length || 0}"
  puts "Planets: #{data["planets"]&.length || 0}"
  puts "Source: ESI (online)"
end

def cmd_station(id)
  # Try name search if not numeric
  unless id.to_s.match?(/^\d+$/)
    if SDE_AVAILABLE
      term_down = id.downcase
      matches = []
      SDE::NpcStation.all.each do |sid, st|
        name = sde_station_name(sid)
        next unless name&.downcase&.include?(term_down)
        matches << [sid, name]
      end
      if matches.length == 1
        id = matches.first[0]
      elsif matches.length > 1
        puts "Search '#{id}': #{matches.length} stations (SDE)"
        matches.first(20).each { |sid, name| puts "  #{name} (#{sid})" }
        return
      else
        puts "Station '#{id}' not found"
        return
      end
    else
      puts "Station name search requires SDE"
      return
    end
  end

  st = sde_station(id.to_i)
  if st
    name = sde_station_name(id.to_i) || id.to_s
    sys_name = sde_system_name(st.solarSystemID) || st.solarSystemID.to_s
    region_name = nil
    sys = sde_system(st.solarSystemID)
    if sys
      region_name = sde_region_name(sys.regionID)
    end
    corp = (SDE::NpcCorporation.find(st.ownerID) rescue nil)
    corp_name = corp&.name&.dig("en") || st.ownerID.to_s
    op = (SDE::StationOperation.find(st.operationID) rescue nil)
    op_name = op&.operationName&.dig("en") || ""
    type_name = sde_type_name(st.typeID) || st.typeID.to_s

    puts "Name: #{name}"
    puts "Station ID: #{id}"
    puts "System: #{sys_name} (#{st.solarSystemID})"
    puts "Region: #{region_name}" if region_name
    puts "Owner: #{corp_name} (#{st.ownerID})"
    puts "Operation: #{op_name}"
    puts "Type: #{type_name} (#{st.typeID})"
    puts "Reprocessing: #{(st.reprocessingEfficiency * 100).round(1)}% (#{(st.reprocessingStationsTake * 100).round(1)}% tax)"
    puts "Source: SDE (offline)"
    return
  end

  # Fallback to ESI
  data = esi_get("/universe/stations/#{id}/")
  return puts JSON.pretty_generate(data) if data.is_a?(Hash) && data[:error]

  puts "Name: #{data["name"]}"
  puts "Station ID: #{data["station_id"]}"
  puts "System ID: #{data["system_id"]}"
  puts "Owner: #{data["owner"]}"
  puts "Type ID: #{data["type_id"]}"
  puts "Reprocessing: #{((data["reprocessing_efficiency"] || 0) * 100).round(1)}%"
  puts "Source: ESI (online)"
end

def cmd_faction(id)
  # Try name search if not numeric
  unless id.to_s.match?(/^\d+$/)
    if SDE_AVAILABLE
      term_down = id.downcase
      matches = []
      SDE::Faction.all.each do |fid, f|
        name = f.name&.dig("en")
        next unless name&.downcase&.include?(term_down)
        matches << [fid, f]
      end
      if matches.length == 1
        id = matches.first[0]
      elsif matches.length > 1
        puts "Search '#{id}': #{matches.length} factions (SDE)"
        matches.each { |fid, f| puts "  #{f.name&.dig("en")} (#{fid})" }
        return
      else
        puts "Faction '#{id}' not found"
        return
      end
    end
  end

  if SDE_AVAILABLE
    f = SDE::Faction.find(id.to_i) rescue nil
    if f
      corp = (SDE::NpcCorporation.find(f.corporationID) rescue nil)
      militia = f.militiaCorporationID ? (SDE::NpcCorporation.find(f.militiaCorporationID) rescue nil) : nil
      sys_name = sde_system_name(f.solarSystemID)

      puts "Name: #{f.name&.dig("en")}"
      puts "Faction ID: #{id}"
      puts "Corporation: #{corp&.name&.dig("en")} (#{f.corporationID})"
      puts "Militia Corp: #{militia&.name&.dig("en")} (#{f.militiaCorporationID})" if militia
      puts "Home System: #{sys_name} (#{f.solarSystemID})" if f.solarSystemID
      puts "Size Factor: #{f.sizeFactor}"
      puts "Member Races: #{f.memberRaces&.map { |r| race_name(r) }&.join(", ")}"
      puts "Description: #{f.description&.dig("en")&.gsub(/<[^>]+>/, "")&.strip&.slice(0, 300)}"
      puts "Source: SDE (offline)"
      return
    end
  end

  puts "Faction #{id} not found"
end

def cmd_npc_corp(id)
  # Try name search if not numeric
  unless id.to_s.match?(/^\d+$/)
    if SDE_AVAILABLE
      term_down = id.downcase
      matches = []
      SDE::NpcCorporation.all.each do |cid, c|
        name = c.name&.dig("en")
        next unless name&.downcase&.include?(term_down)
        matches << [cid, c]
      end
      if matches.length == 1
        id = matches.first[0]
      elsif matches.length > 1
        puts "Search '#{id}': #{matches.length} NPC corps (SDE)"
        matches.first(20).each { |cid, c| puts "  [#{c.tickerName}] #{c.name&.dig("en")} (#{cid})" }
        return
      else
        puts "NPC Corp '#{id}' not found"
        return
      end
    end
  end

  if SDE_AVAILABLE
    c = SDE::NpcCorporation.find(id.to_i) rescue nil
    if c
      faction = c.factionID ? (SDE::Faction.find(c.factionID) rescue nil) : nil
      ceo = c.ceoID ? (SDE::NpcCharacter.find(c.ceoID) rescue nil) : nil
      sys_name = c.solarSystemID ? sde_system_name(c.solarSystemID) : nil
      station_name = c.stationID ? sde_station_name(c.stationID) : nil

      puts "Name: #{c.name&.dig("en")}"
      puts "Ticker: [#{c.tickerName}]"
      puts "Corp ID: #{id}"
      puts "Faction: #{faction&.name&.dig("en")} (#{c.factionID})" if faction
      puts "CEO: #{ceo&.name&.dig("en") rescue c.ceoID} (#{c.ceoID})" if c.ceoID
      puts "HQ System: #{sys_name} (#{c.solarSystemID})" if sys_name
      puts "HQ Station: #{station_name} (#{c.stationID})" if station_name
      puts "Tax Rate: #{(c.taxRate * 100).round(1)}%"
      puts "Size: #{c.size}"
      puts "Min Standing: #{c.minimumJoinStanding}"
      puts "Description: #{c.description&.dig("en")&.gsub(/<[^>]+>/, "")&.strip&.slice(0, 300)}"
      puts "Source: SDE (offline)"
      return
    end
  end

  # Fallback — treat as player corp via ESI
  cmd_corporation(id)
end

def cmd_agent(id)
  # Try name search if not numeric
  unless id.to_s.match?(/^\d+$/)
    if SDE_AVAILABLE
      term_down = id.downcase
      matches = []
      SDE::NpcCharacter.all.each do |cid, c|
        next unless c.agent
        name = c.name&.dig("en")
        next unless name&.downcase&.include?(term_down)
        matches << [cid, c]
      end
      if matches.length == 1
        id = matches.first[0]
      elsif matches.length > 1
        puts "Search '#{id}': #{matches.length} agents (SDE)"
        matches.first(20).each do |cid, c|
          agent_type = (SDE::AgentType.find(c.agent["agentTypeID"]) rescue nil)&.name || "?"
          division = (SDE::NpcCorporationDivision.find(c.agent["divisionID"]) rescue nil)
          div_name = division&.name&.dig("en") rescue "?"
          corp = (SDE::NpcCorporation.find(c.corporationID) rescue nil)
          puts "  #{c.name&.dig("en")} (#{cid}) — L#{c.agent["level"]} #{div_name} #{agent_type}, #{corp&.name&.dig("en")}"
        end
        return
      else
        puts "Agent '#{id}' not found"
        return
      end
    end
  end

  if SDE_AVAILABLE
    c = SDE::NpcCharacter.find(id.to_i) rescue nil
    if c && c.agent
      agent_type = (SDE::AgentType.find(c.agent["agentTypeID"]) rescue nil)&.name || c.agent["agentTypeID"].to_s
      division = (SDE::NpcCorporationDivision.find(c.agent["divisionID"]) rescue nil)
      div_name = division&.name&.dig("en") rescue c.agent["divisionID"].to_s
      corp = (SDE::NpcCorporation.find(c.corporationID) rescue nil)
      station_name = sde_station_name(c.locationID)
      sys_name = nil
      if station_name.nil?
        sys_name = sde_system_name(c.locationID)
      end

      puts "Name: #{c.name&.dig("en")}"
      puts "Agent ID: #{id}"
      puts "Type: #{agent_type}"
      puts "Level: #{c.agent["level"]}"
      puts "Division: #{div_name}"
      puts "Corporation: #{corp&.name&.dig("en")} (#{c.corporationID})" if corp
      puts "Location: #{station_name || sys_name || c.locationID}" if c.locationID
      puts "Locator: #{c.agent["isLocator"] ? "Yes" : "No"}"
      puts "Race: #{race_name(c.raceID)}"
      puts "Source: SDE (offline)"
      return
    elsif c
      puts "#{c.name&.dig("en")} (#{id}) is not an agent"
      return
    end
  end

  puts "Agent #{id} not found"
end

def cmd_agents_in(location)
  return puts "SDE required for agent search" unless SDE_AVAILABLE

  # Resolve system ID if name given
  sys_id = resolve_system_id(location)

  # Find all agents in this system (by station locationID)
  results = []
  SDE::NpcCharacter.all.each do |cid, c|
    next unless c.agent
    # Check if agent's station is in the target system
    st = sde_station(c.locationID)
    next unless st
    next unless st.solarSystemID == sys_id
    results << [cid, c]
  end

  if results.empty?
    puts "No agents found in #{location}"
    return
  end

  sys_name = sde_system_name(sys_id) || location
  puts "Agents in #{sys_name}: #{results.length} (SDE)"
  results.sort_by { |_, c| [-c.agent["level"], c.name&.dig("en") || ""] }.each do |cid, c|
    agent_type = (SDE::AgentType.find(c.agent["agentTypeID"]) rescue nil)&.name || "?"
    division = (SDE::NpcCorporationDivision.find(c.agent["divisionID"]) rescue nil)
    div_name = division&.name&.dig("en") rescue "?"
    corp = (SDE::NpcCorporation.find(c.corporationID) rescue nil)
    station = sde_station_name(c.locationID)
    locator = c.agent["isLocator"] ? " [LOCATOR]" : ""
    puts "  L#{c.agent["level"]} #{c.name&.dig("en")} — #{div_name} #{agent_type}, #{corp&.name&.dig("en")}#{locator}"
    puts "    @ #{station}" if station
  end
end

def cmd_stations_find(args)
  return puts "SDE required" unless SDE_AVAILABLE

  # Parse flags: --system NAME, --region NAME, --corp NAME, --operation NAME
  system_filter = nil
  region_filter = nil
  corp_filter = nil
  op_filter = nil

  i = 0
  while i < args.length
    case args[i]
    when "--system", "-s"
      system_filter = args[i + 1]
      i += 2
    when "--region", "-r"
      region_filter = args[i + 1]&.downcase
      i += 2
    when "--corp", "-c"
      corp_filter = args[i + 1]&.downcase
      i += 2
    when "--operation", "--op", "-o"
      op_filter = args[i + 1]&.downcase
      i += 2
    else
      corp_filter = args[i..].join(" ").downcase
      break
    end
  end

  if system_filter.nil? && region_filter.nil? && corp_filter.nil? && op_filter.nil?
    puts "Usage: stations-find [options]"
    puts "  --system NAME    Filter by system"
    puts "  --region NAME    Filter by region"
    puts "  --corp NAME      Filter by corporation"
    puts "  --op NAME        Filter by operation (Mining, Storage, Assembly, etc.)"
    return
  end

  sys_id = system_filter ? resolve_system_id(system_filter) : nil

  # Region ID lookup
  region_id = nil
  if region_filter
    SDE::MapRegion.all.each do |rid, r|
      if r.name&.dig("en")&.downcase&.include?(region_filter)
        region_id = rid
        break
      end
    end
    return puts "Region '#{region_filter}' not found" unless region_id
  end

  # Corp ID lookup
  corp_ids = nil
  if corp_filter
    corp_ids = []
    SDE::NpcCorporation.all.each do |cid, c|
      corp_ids << cid if c.name&.dig("en")&.downcase&.include?(corp_filter)
    end
    return puts "No NPC corps matching '#{corp_filter}'" if corp_ids.empty?
  end

  # Operation ID lookup
  op_ids = nil
  if op_filter
    op_ids = []
    SDE::StationOperation.all.each do |oid, o|
      op_ids << oid if o.operationName&.dig("en")&.downcase&.include?(op_filter)
    end
  end

  results = []
  SDE::NpcStation.all.each do |sid, st|
    next if sys_id && st.solarSystemID != sys_id
    next if corp_ids && !corp_ids.include?(st.ownerID)
    next if op_ids && !op_ids.include?(st.operationID)
    if region_id
      sys = sde_system(st.solarSystemID)
      next unless sys && sys.regionID == region_id
    end
    results << [sid, st]
  end

  if results.empty?
    puts "No stations found matching filters"
    return
  end

  puts "Stations found: #{results.length} (SDE)"
  results.first(50).each do |sid, st|
    name = sde_station_name(sid)
    puts "  #{name} (#{sid})"
  end
  puts "... (#{results.length - 50} more)" if results.length > 50
end

def cmd_systems_find(args)
  return puts "SDE required" unless SDE_AVAILABLE

  # Parse flags: --region NAME, --sec-min N, --sec-max N, --sec high/low/null
  region_filter = nil
  sec_min = nil
  sec_max = nil
  sec_class = nil

  i = 0
  while i < args.length
    case args[i]
    when "--region", "-r"
      region_filter = args[i + 1]&.downcase
      i += 2
    when "--sec-min"
      sec_min = args[i + 1]&.to_f
      i += 2
    when "--sec-max"
      sec_max = args[i + 1]&.to_f
      i += 2
    when "--sec"
      sec_class = args[i + 1]&.downcase
      i += 2
    else
      region_filter = args[i..].join(" ").downcase
      break
    end
  end

  if region_filter.nil? && sec_min.nil? && sec_max.nil? && sec_class.nil?
    puts "Usage: systems-find [options]"
    puts "  --region NAME    Filter by region"
    puts "  --sec high|low|null  Filter by security class"
    puts "  --sec-min N      Minimum security status"
    puts "  --sec-max N      Maximum security status"
    return
  end

  # Set sec bounds from class
  if sec_class
    case sec_class
    when "high", "highsec", "hi"
      sec_min = 0.45
    when "low", "lowsec"
      sec_min = 0.0
      sec_max = 0.45
    when "null", "nullsec"
      sec_max = 0.0
    end
  end

  region_id = nil
  if region_filter
    SDE::MapRegion.all.each do |rid, r|
      if r.name&.dig("en")&.downcase&.include?(region_filter)
        region_id = rid
        break
      end
    end
    return puts "Region '#{region_filter}' not found" unless region_id
  end

  results = []
  SDE::MapSolarSystem.all.each do |sid, s|
    next if region_id && s.regionID != region_id
    sec = s.securityStatus || 0
    next if sec_min && sec < sec_min
    next if sec_max && sec >= sec_max
    results << [sid, s]
  end

  if results.empty?
    puts "No systems found matching filters"
    return
  end

  results.sort_by! { |_, s| -(s.securityStatus || 0) }
  puts "Systems found: #{results.length} (SDE)"
  results.first(50).each do |sid, s|
    name = s.name&.dig("en") || sid.to_s
    puts "  #{name} (#{sid}) — sec #{s.securityStatus&.round(2)}"
  end
  puts "... (#{results.length - 50} more)" if results.length > 50
end

def cmd_agents_find(args)
  return puts "SDE required for agent search" unless SDE_AVAILABLE

  # Parse flags: --level N, --corp NAME, --division NAME, --type NAME, --locator, --system NAME
  level = nil
  corp_filter = nil
  div_filter = nil
  type_filter = nil
  locator_only = false
  system_filter = nil

  i = 0
  while i < args.length
    case args[i]
    when "--level", "-l"
      level = args[i + 1]&.to_i
      i += 2
    when "--corp", "-c"
      corp_filter = args[i + 1]&.downcase
      i += 2
    when "--division", "--div", "-d"
      div_filter = args[i + 1]&.downcase
      i += 2
    when "--type", "-t"
      type_filter = args[i + 1]&.downcase
      i += 2
    when "--locator"
      locator_only = true
      i += 1
    when "--system", "-s"
      system_filter = args[i + 1]
      i += 2
    else
      # Treat bare args as corp filter
      corp_filter = args[i..].join(" ").downcase
      break
    end
  end

  if level.nil? && corp_filter.nil? && div_filter.nil? && type_filter.nil? && !locator_only && system_filter.nil?
    puts "Usage: agents-find [options]"
    puts "  --level N        Filter by level (1-5)"
    puts "  --corp NAME      Filter by corporation name"
    puts "  --div NAME       Filter by division (Security, Mining, Distribution, R&D)"
    puts "  --type NAME      Filter by agent type (BasicAgent, ResearchAgent, etc.)"
    puts "  --locator        Show only locator agents"
    puts "  --system NAME    Filter by system"
    puts ""
    puts "Examples:"
    puts "  agents-find --level 4 --corp \"Caldari Navy\""
    puts "  agents-find --level 4 --div Security"
    puts "  agents-find --locator --corp \"Caldari Navy\""
    return
  end

  # Resolve system if given
  sys_id = system_filter ? resolve_system_id(system_filter) : nil

  # Build corp ID cache if filtering by corp
  corp_ids = nil
  if corp_filter
    corp_ids = []
    SDE::NpcCorporation.all.each do |cid, c|
      name = c.name&.dig("en")
      corp_ids << cid if name&.downcase&.include?(corp_filter)
    end
    if corp_ids.empty?
      puts "No NPC corps matching '#{corp_filter}'"
      return
    end
  end

  # Build division ID cache if filtering
  div_ids = nil
  if div_filter
    div_ids = []
    SDE::NpcCorporationDivision.all.each do |did, d|
      name = d.name&.dig("en") rescue nil
      div_ids << did if name&.downcase&.include?(div_filter)
    end
  end

  # Build agent type ID cache if filtering
  type_ids = nil
  if type_filter
    type_ids = []
    SDE::AgentType.all.each do |tid, t|
      type_ids << tid if t.name&.downcase&.include?(type_filter)
    end
  end

  results = []
  SDE::NpcCharacter.all.each do |cid, c|
    next unless c.agent
    next if level && c.agent["level"] != level
    next if corp_ids && !corp_ids.include?(c.corporationID)
    next if div_ids && !div_ids.include?(c.agent["divisionID"])
    next if type_ids && !type_ids.include?(c.agent["agentTypeID"])
    next if locator_only && !c.agent["isLocator"]
    if sys_id
      st = sde_station(c.locationID)
      next unless st && st.solarSystemID == sys_id
    end
    results << [cid, c]
  end

  if results.empty?
    puts "No agents found matching filters"
    return
  end

  puts "Agents found: #{results.length} (SDE)"
  results.sort_by { |_, c| [-c.agent["level"], c.name&.dig("en") || ""] }.first(50).each do |cid, c|
    agent_type = (SDE::AgentType.find(c.agent["agentTypeID"]) rescue nil)&.name || "?"
    division = (SDE::NpcCorporationDivision.find(c.agent["divisionID"]) rescue nil)
    div_name = division&.name&.dig("en") rescue "?"
    corp = (SDE::NpcCorporation.find(c.corporationID) rescue nil)
    station = sde_station_name(c.locationID)
    locator = c.agent["isLocator"] ? " [LOCATOR]" : ""
    puts "  L#{c.agent["level"]} #{c.name&.dig("en")} — #{div_name} #{agent_type}, #{corp&.name&.dig("en")}#{locator}"
    puts "    @ #{station}" if station
  end
  puts "... (#{results.length - 50} more)" if results.length > 50
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

def cmd_kills(system_id = nil)
  data = esi_get("/universe/system_kills/")
  return puts JSON.pretty_generate(data) if data.is_a?(Hash) && data[:error]

  if system_id
    entry = data.find { |d| d["system_id"] == system_id.to_i }
    if entry
      name = resolve_system_name(system_id)
      puts "System: #{name} (#{system_id})"
      puts "Ship Kills: #{entry["ship_kills"]}"
      puts "Pod Kills: #{entry["pod_kills"]}"
      puts "NPC Kills: #{entry["npc_kills"]}"
    else
      puts "No kill data for system #{system_id} (may be quiet)"
    end
  else
    sorted = data.sort_by { |d| -(d["ship_kills"] || 0) }
    puts "Top 20 systems by ship kills (last hour):"
    sorted.first(20).each do |d|
      name = resolve_system_name(d["system_id"])
      puts "  #{name}: #{d["ship_kills"]} ships, #{d["pod_kills"]} pods, #{d["npc_kills"]} NPCs"
    end
  end
end

def cmd_jumps(system_id = nil)
  data = esi_get("/universe/system_jumps/")
  return puts JSON.pretty_generate(data) if data.is_a?(Hash) && data[:error]

  if system_id
    entry = data.find { |d| d["system_id"] == system_id.to_i }
    if entry
      name = resolve_system_name(system_id)
      puts "System: #{name} (#{system_id})"
      puts "Jumps: #{entry["ship_jumps"]}"
    else
      puts "No jump data for system #{system_id}"
    end
  else
    sorted = data.sort_by { |d| -(d["ship_jumps"] || 0) }
    puts "Top 20 systems by jump traffic (last hour):"
    sorted.first(20).each do |d|
      name = resolve_system_name(d["system_id"])
      puts "  #{name}: #{d["ship_jumps"]} jumps"
    end
  end
end

# --- Authenticated commands ---

def char_id(name = nil)
  name ||= @active_char
  CHARACTERS[name.downcase]&.dig(:id)
end

def cmd_location(char_name = nil)
  char_name ||= @active_char
  cid = char_id(char_name)
  data = esi_get_auth("/characters/#{cid}/location/", char_name: char_name)
  return puts JSON.pretty_generate(data) if data.is_a?(Hash) && data[:error]

  sys_id = data["solar_system_id"]
  sys_name = resolve_system_name(sys_id)

  station_name = nil
  if data["station_id"]
    station_name = resolve_station_name(data["station_id"])
  elsif data["structure_id"]
    station_name = "Structure #{data["structure_id"]}"
  end

  # Get security from SDE if available, else API
  sde_sys = sde_system(sys_id)
  sec = sde_sys ? sde_sys.securityStatus&.round(2) : esi_get("/universe/systems/#{sys_id}/")&.dig("security_status")&.round(2)
  sec_class = if sec && sec >= 0.45 then "High"
  elsif sec && sec > 0.0 then "Low"
  else "Null"
  end

  # Region/constellation from SDE
  region = sde_sys ? sde_region_name(sde_sys.regionID) : nil
  constellation = sde_sys ? sde_constellation_name(sde_sys.constellationID) : nil

  puts "Character: #{char_name.capitalize}"
  puts "System: #{sys_name} (#{sys_id})"
  puts "Security: #{sec} (#{sec_class}-sec)"
  puts "Region: #{region}" if region
  puts "Constellation: #{constellation}" if constellation
  puts "Docked: #{station_name || "In space"}"
end

def cmd_ship(char_name = nil)
  char_name ||= @active_char
  cid = char_id(char_name)
  data = esi_get_auth("/characters/#{cid}/ship/", char_name: char_name)
  return puts JSON.pretty_generate(data) if data.is_a?(Hash) && data[:error]

  type_name = resolve_type_name(data["ship_type_id"])
  puts "Ship: #{data["ship_name"]}"
  puts "Type: #{type_name} (#{data["ship_type_id"]})"
  puts "Item ID: #{data["ship_item_id"]}"
end

def cmd_online(char_name = nil)
  char_name ||= @active_char
  cid = char_id(char_name)
  data = esi_get_auth("/characters/#{cid}/online/", char_name: char_name)
  return puts JSON.pretty_generate(data) if data.is_a?(Hash) && data[:error]

  puts "Character: #{char_name.capitalize}"
  puts "Online: #{data["online"]}"
  puts "Last Login: #{data["last_login"]}"
  puts "Last Logout: #{data["last_logout"]}"
  puts "Logins: #{data["logins"]}"
end

def cmd_wallet(char_name = nil)
  char_name ||= @active_char
  cid = char_id(char_name)
  data = esi_get_auth("/characters/#{cid}/wallet/", char_name: char_name)
  if data.is_a?(Hash) && data[:error]
    puts JSON.pretty_generate(data)
    return
  end

  isk = data.is_a?(Numeric) ? data : data.to_f
  puts "Character: #{char_name.capitalize}"
  puts "Wallet: #{"%.2f" % isk} ISK"
end

def cmd_waypoint(destination_id, clear: false)
  data = esi_post_auth("/ui/autopilot/waypoint/", nil,
    {"destination_id" => destination_id, "clear_other_waypoints" => clear.to_s, "add_to_beginning" => "false"})
  if data.is_a?(Hash) && data[:error]
    puts "Failed: #{data[:error]}"
  else
    puts "Waypoint set: #{destination_id}"
  end
end

def cmd_openmarket(type_id)
  data = esi_post_auth("/ui/openwindow/marketdetails/", nil, {"type_id" => type_id})
  if data.is_a?(Hash) && data[:error]
    puts "Failed: #{data[:error]}"
  else
    puts "Market window opened for type #{type_id}"
  end
end

def cmd_openinfo(target_id)
  data = esi_post_auth("/ui/openwindow/information/", nil, {"target_id" => target_id})
  if data.is_a?(Hash) && data[:error]
    puts "Failed: #{data[:error]}"
  else
    puts "Info window opened for #{target_id}"
  end
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

# Parse --char flag
@active_char = DEFAULT_CHAR
if (idx = ARGV.index("--char"))
  ARGV.delete_at(idx)
  @active_char = ARGV.delete_at(idx) || DEFAULT_CHAR
end

command = ARGV.shift
case command
# Public
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
when "station"
  cmd_station(ARGV.shift)
when "faction"
  cmd_faction(ARGV.shift)
when "npc-corp", "npc_corp", "npccorp"
  cmd_npc_corp(ARGV.shift)
when "agent"
  cmd_agent(ARGV.shift)
when "agents-in", "agents_in"
  cmd_agents_in(ARGV.shift)
when "agents-find", "agents_find"
  cmd_agents_find(ARGV)
when "stations-find", "stations_find"
  cmd_stations_find(ARGV)
when "systems-find", "systems_find"
  cmd_systems_find(ARGV)
when "sovereignty", "sov"
  cmd_sovereignty
when "portrait"
  cmd_portrait(ARGV.shift)
when "kills"
  cmd_kills(ARGV.shift)
when "jumps"
  cmd_jumps(ARGV.shift)
# Authenticated
when "location", "loc", "where"
  cmd_location(ARGV.shift)
when "ship"
  cmd_ship(ARGV.shift)
when "online"
  cmd_online(ARGV.shift)
when "wallet", "isk"
  cmd_wallet(ARGV.shift)
when "waypoint", "warp"
  cmd_waypoint(ARGV.shift, clear: true)
when "clear-route", "clear"
  # Set current location as waypoint with clear flag to wipe the route
  cid = char_id
  loc = esi_get_auth("/characters/#{cid}/location/")
  if loc.is_a?(Hash) && loc["solar_system_id"]
    cmd_waypoint(loc["solar_system_id"], clear: true)
    puts "Route cleared"
  else
    puts "Failed to get location"
  end
when "openmarket", "market-open"
  cmd_openmarket(ARGV.shift)
when "openinfo", "info-open"
  cmd_openinfo(ARGV.shift)
else
  puts "EVE ESI API Client"
  puts ""
  puts "Usage: ruby eve-esi.rb [--char name] <command> [args...]"
  puts ""
  puts "Public commands:"
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
  puts "  system <name|id>                Solar system info"
  puts "  station <name|id>               NPC station info"
  puts "  faction <name|id>               Faction info"
  puts "  npc-corp <name|id>              NPC corporation info"
  puts "  agent <name|id>                 Agent info"
  puts "  agents-in <system>              Agents in a system"
  puts "  agents-find [filters]           Find agents (--level --corp --div --locator --system)"
  puts "  stations-find [filters]         Find stations (--system --region --corp --op)"
  puts "  systems-find [filters]          Find systems (--region --sec high/low/null --sec-min --sec-max)"
  puts "  sovereignty                     Sov map"
  puts "  portrait <id>                   Portrait URL"
  puts ""
  puts "Authenticated commands (requires 1Password eve-esi):"
  puts "  location [char]                 Current system/station"
  puts "  ship [char]                     Current ship"
  puts "  online [char]                   Online status"
  puts "  wallet [char]                   ISK balance"
  puts "  waypoint <system_id>            Set autopilot waypoint"
  puts "  openmarket <type_id>            Open market window"
  puts "  openinfo <target_id>            Open info window"
  puts ""
  puts "Characters: spinister (default), battletrap, amy"
  puts "Use --char <name> to switch: ruby eve-esi.rb --char battletrap location"
end
