# frozen_string_literal: true
require 'net/http'
require 'json'
require 'uri'
require 'yaml'

module GeocodeResolver
  CACHE_FILE  = '_data/geocode_cache.yml'
  USER_AGENT  = 'Fimplace/1.0 (https://fimplace.netlify.app; fim.hlight@gmail.com)'

  KOREA_LAT = (33.0..39.0)
  KOREA_LNG = (124.0..132.0)

  REGIONS = %w[서울 부산 대구 인천 광주 대전 울산 세종 경기 강원 충북 충남 전북 전남 경북 경남 제주]

  REGION_EN = {
    '서울' => 'Seoul', '부산' => 'Busan', '대구' => 'Daegu', '인천' => 'Incheon',
    '광주' => 'Gwangju', '대전' => 'Daejeon', '울산' => 'Ulsan', '세종' => 'Sejong',
    '경기' => 'Gyeonggi', '강원' => 'Gangwon', '충북' => 'Chungbuk', '충남' => 'Chungnam',
    '전북' => 'Jeonbuk', '전남' => 'Jeollanam', '경북' => 'Gyeongsangbuk', '경남' => 'Gyeongsangnam',
    '제주' => 'Jeju'
  }

  def self.in_korea?(lat, lng)
    KOREA_LAT.include?(lat) && KOREA_LNG.include?(lng)
  end

  def self.load_cache
    return {} unless File.exist?(CACHE_FILE)
    YAML.load_file(CACHE_FILE) || {}
  rescue StandardError => e
    Jekyll.logger.warn('Geocode', "cache load failed (#{e.message}); starting fresh") if defined?(Jekyll)
    {}
  end

  def self.save_cache(cache)
    lines = ["# 주소/상호명 -> 좌표 캐시 (geocode_resolver.rb 가 자동 관리)"]
    cache.each do |key, val|
      key_q = key.to_s.gsub('"', '\\"')
      lines << "\"#{key_q}\":"
      if val.is_a?(Hash) && val['failed']
        lines << "  failed: true"
      elsif val.is_a?(Hash) && val['lat'] && val['lng']
        lines << "  lat: #{val['lat']}"
        lines << "  lng: #{val['lng']}"
        lines << "  source: #{val['source'] || 'nominatim'}"
        if val['matched']
          matched = val['matched'].to_s.gsub('"', '\\"').gsub(/[\r\n]/, ' ')[0, 200]
          lines << "  matched: \"#{matched}\""
        end
      end
    end
    # Atomic write: 임시 파일에 fsync 후 rename → 중간 중단되도 캐시 손상 X
    tmp = "#{CACHE_FILE}.tmp"
    File.open(tmp, 'w:utf-8') do |f|
      f.write(lines.join("\n") + "\n")
      f.fsync
    end
    File.rename(tmp, CACHE_FILE)
  rescue StandardError => e
    Jekyll.logger.warn('Geocode', "cache save failed: #{e.message}") if defined?(Jekyll)
  end

  def self.normalize(addr)
    return nil if addr.nil?
    addr.to_s.strip.gsub(/\s+/, ' ').gsub(/[()（）]/, ' ').strip
  end

  def self.region_from(text)
    return nil if text.nil?
    s = text.to_s
    REGIONS.each { |r| return r if s.include?(r) }
    nil
  end

  def self.result_matches_region?(display, expected_region)
    return true if expected_region.nil?
    s = display.to_s
    return true if s.include?(expected_region)
    en = REGION_EN[expected_region]
    return true if en && s.include?(en)
    false
  end

  def self.lookup(query, hints, cache, source_tag: nil)
    key = normalize(query)
    return nil if key.nil? || key.empty? || key.length < 2

    cached = cache[key]
    return cached if cached.is_a?(Hash) && cached['lat'] && cached['lng']
    return nil if cached.is_a?(Hash) && cached['failed']

    expected_region = region_from(key) || (Array(hints).map { |h| region_from(h) }.compact.first)

    result = nominatim_search(key, expected_region)
    result ||= photon_search(key, expected_region)

    if result
      result['source'] = source_tag || result['source']
      cache[key] = result
      save_cache(cache)
      Jekyll.logger.info('Geocode', "OK [#{result['lat']}, #{result['lng']}] (#{result['source']}) <- #{key}") if defined?(Jekyll)
      return result
    end

    Jekyll.logger.warn('Geocode', "miss for: #{key} (expected: #{expected_region || 'any'})") if defined?(Jekyll)
    cache[key] = { 'failed' => true }
    save_cache(cache)
    nil
  end

  def self.lookup_cascade(variants, hints, cache)
    Array(variants).uniq.each_with_index do |q, i|
      next if q.nil? || q.strip.empty?
      tag = case i
            when 0 then 'nominatim'
            when 1 then 'nominatim:cleaned'
            when 2 then 'nominatim:road'
            when 3 then 'nominatim:district'
            else 'nominatim:fallback'
            end
      result = lookup(q, hints, cache, source_tag: tag)
      return result if result
    end
    nil
  end

  def self.nominatim_search(query, expected_region)
    sleep 1.1
    uri = URI('https://nominatim.openstreetmap.org/search')
    uri.query = URI.encode_www_form(
      q: query, format: 'json', limit: 5, countrycodes: 'kr', 'accept-language' => 'ko'
    )
    req = Net::HTTP::Get.new(uri)
    req['User-Agent'] = USER_AGENT
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.open_timeout = 10
      http.read_timeout = 15
      http.request(req)
    end
    candidates = JSON.parse(res.body) rescue []
    picked = nil
    if expected_region
      picked = candidates.find do |c|
        lat = c['lat'].to_f; lng = c['lon'].to_f
        in_korea?(lat, lng) && result_matches_region?(c['display_name'], expected_region)
      end
    end
    picked ||= candidates.find { |c| in_korea?(c['lat'].to_f, c['lon'].to_f) }
    return nil unless picked
    { 'lat' => picked['lat'].to_f, 'lng' => picked['lon'].to_f,
      'source' => 'nominatim', 'matched' => picked['display_name'] }
  rescue StandardError => e
    Jekyll.logger.warn('Geocode', "nominatim error: #{e.class}") if defined?(Jekyll)
    nil
  end

  def self.photon_search(query, expected_region)
    sleep 0.3
    uri = URI('https://photon.komoot.io/api/')
    uri.query = URI.encode_www_form(q: query, limit: 5, lang: 'default')
    req = Net::HTTP::Get.new(uri)
    req['User-Agent'] = USER_AGENT
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.open_timeout = 10
      http.read_timeout = 15
      http.request(req)
    end
    data = JSON.parse(res.body) rescue {}
    features = Array(data['features'])
    picked = nil
    features.each do |f|
      coords = f.dig('geometry', 'coordinates')
      next unless coords.is_a?(Array) && coords.size == 2
      lng = coords[0].to_f; lat = coords[1].to_f
      next unless in_korea?(lat, lng)
      props = f['properties'] || {}
      country = props['country'].to_s
      next unless country.empty? || country.include?('Korea') || country.include?('대한민국')
      if expected_region
        display = "#{props['state']} #{props['city']} #{props['county']} #{props['name']}"
        next unless result_matches_region?(display, expected_region)
      end
      picked = { lat: lat, lng: lng, name: props['name'].to_s, state: props['state'].to_s }
      break
    end
    return nil unless picked
    { 'lat' => picked[:lat], 'lng' => picked[:lng], 'source' => 'photon',
      'matched' => [picked[:state], picked[:name]].reject(&:empty?).join(', ') }
  rescue StandardError => e
    Jekyll.logger.warn('Geocode', "photon error: #{e.class}") if defined?(Jekyll)
    nil
  end
end
