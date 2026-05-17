# frozen_string_literal: true
#
# 노트별 좌표 해석 + places.json 생성
# - 우선순위: frontmatter coords -> iframe 검색어 -> 상호명 -> iframe 좌표 -> 주소 캐스케이드 -> known_places -> cleaned title
# - 신규 해석된 노트는 _data/places_db.yml 에 정렬 유지하며 자동 추가
require 'json'
require 'set'
require 'base64'

module PlacesGenerator
  MAP_COORD_REGEX         = /maps\/embed\?[^"']*?!2d(-?\d+\.\d+)!3d(-?\d+\.\d+)/
  MAP_PLACE_NAME_REGEX    = /!2z([A-Za-z0-9_-]+)/
  ADDRESS_HEADING_REGEX   = /##\s*(?:위치|주소|주\s*소|위\s*치|location|address)\s*\n+([^\n#|]+)/i
  BUSINESS_HEADING_REGEX  = /##\s*(?:상호\s*명|상호|business|name)\s*\n+([^\n#|]+)/i
  KAKAO_PLACE_URL_REGEX   = /https?:\/\/(?:place\.)?map\.kakao\.com\/(?:place\/)?(\d+)/
  NAVER_PLACE_URL_REGEX   = /https?:\/\/(?:naver\.me\/[A-Za-z0-9]+|map\.naver\.com\/[^\s)]+)/

  REGION_MAP = {
    '서울' => '서울', '부산' => '부산', '대구' => '대구', '인천' => '인천',
    '광주' => '광주', '대전' => '대전', '울산' => '울산', '세종' => '세종',
    '경기' => '경기', '강원' => '강원', '충북' => '충북', '충남' => '충남',
    '전북' => '전북', '전남' => '전남', '경북' => '경북', '경남' => '경남',
    '제주' => '제주'
  }
  KR_REGIONS = REGION_MAP.keys

  # 도(道) 우선. "경기 광주시"에서 광주광역시로 잘못 분류되는 것 방지
  DOMINANT_REGIONS = %w[경기 강원 충북 충남 전북 전남 경북 경남 제주
                        서울 부산 대구 인천 광주 대전 울산 세종]

  ADDR_LINE_REGEX = /
    (?:#{KR_REGIONS.join('|')})
    (?:특별시|광역시|특별자치도|특별자치시|도)?
    \s+\S*(?:구|시|군|읍|면|동)\s+[^\n<|"\[#]+
  /x

  AREA_REGION_PREFIX = {
    '해방촌'   => '서울 용산구', '경리단길' => '서울 용산구',
    '이태원'   => '서울 용산구', '한남동'   => '서울 용산구',
    '연남동'   => '서울 마포구', '연희동'   => '서울 서대문구',
    '망원동'   => '서울 마포구', '서촌'     => '서울 종로구',
    '북촌'     => '서울 종로구', '익선동'   => '서울 종로구'
  }

  def self.region_from_address(addr)
    return nil if addr.nil? || addr.empty?
    DOMINANT_REGIONS.each { |prefix| return prefix if addr.include?(prefix) }
    nil
  end

  def self.region_from_tags(tags)
    Array(tags).each do |t|
      DOMINANT_REGIONS.each { |prefix| return prefix if t.to_s.include?(prefix) }
    end
    nil
  end

  def self.clean_address_noise(s)
    s = s.gsub(/\([^)]*\)/, '').gsub(/（[^）]*）/, '')
    s = s.gsub(/\[[^\]]*\]/, '')
    s.gsub(/\s+/, ' ').strip
  end

  def self.augment_address_prefix(addr)
    return addr if addr.nil? || addr.empty?
    return addr if KR_REGIONS.any? { |r| addr.start_with?(r) }
    AREA_REGION_PREFIX.each do |area, prefix|
      return "#{prefix} #{addr}" if addr.start_with?(area) || addr.include?(area)
    end
    addr
  end

  def self.extract_address(content)
    return '' if content.nil?
    if (m = content.match(ADDRESS_HEADING_REGEX))
      addr = m[1].to_s.strip.gsub(/<[^>]+>/, '').strip
      return augment_address_prefix(clean_address_noise(addr)) unless addr.empty?
    end
    if (m = content.match(ADDR_LINE_REGEX))
      return augment_address_prefix(clean_address_noise(m[0].to_s.strip.gsub(/<[^>]+>/, '').strip))
    end
    ''
  end

  def self.extract_iframe_query(content)
    return nil unless (m = content.match(MAP_PLACE_NAME_REGEX))
    encoded = m[1]
    padded = encoded + '=' * ((4 - encoded.length % 4) % 4)
    decoded = Base64.urlsafe_decode64(padded).force_encoding('UTF-8')
    return nil unless decoded.valid_encoding?
    decoded.gsub(/\s+/, ' ').strip
  rescue StandardError
    nil
  end

  def self.extract_business(content)
    return nil if content.nil?
    return nil unless (m = content.match(BUSINESS_HEADING_REGEX))
    name = m[1].to_s.strip.gsub(/<[^>]+>/, '').strip
    name.empty? ? nil : name
  end

  def self.extract_external_urls(content)
    {
      'kakao' => content.scan(KAKAO_PLACE_URL_REGEX).flatten.first,
      'naver' => content.scan(NAVER_PLACE_URL_REGEX).flatten.first
    }.compact
  end

  def self.business_variants(name)
    return [] if name.nil?
    out = [name]
    n = name.gsub(/\s*\d+\s*호점\s*$/, '')
         .gsub(/\s*(?:본점|직영점|분점|지점|점)\s*$/, '').strip
    out << n if n != name && n.length > 1
    out.uniq.reject { |s| s.nil? || s.length < 2 }
  end

  def self.address_variants(addr)
    return [] if addr.nil? || addr.empty?
    out = []
    a0 = clean_address_noise(addr)
    out << a0
    a1 = a0.dup
    a1 = a1.sub(/\s+(?:지하\s*\d*\s*층?|B\d+(?:-\d+)?(?:호)?|\d+\s*층(?:\s*[A-Z]?\d+(?:-\d+)?(?:호)?)?|\d+\s*호)\b.*$/, '')
    a1 = a1.split(',').first.to_s.strip
    a1 = a1.gsub(/\s+\S+동(?=\s+\S+(?:로|길))/, '')
    a1 = a1.gsub(/\s+/, ' ').strip
    out << a1 if a1 != a0 && a1.length > 5
    if (m = a1.match(/^(.+?(?:로|길)\s*\d+(?:-\d+)?)\b/))
      out << m[1].strip if !out.include?(m[1].strip) && m[1].strip.length > 5
    end
    if (m = a1.match(/^(.+?(?:로|길))(?:\s|$)/))
      out << m[1].strip if !out.include?(m[1].strip) && m[1].strip.length > 3
    end
    if (m = a1.match(/^([가-힣]+(?:특별시|광역시|특별자치도|특별자치시|도)?\s+\S+(?:구|시|군))/))
      out << m[1].strip unless out.include?(m[1].strip)
    end
    out.uniq.reject(&:empty?)
  end

  def self.build_tag_to_categories(site)
    raw = site.data['tag_categories'] || {}
    index = Hash.new { |h, k| h[k] = [] }
    raw.each { |c, ts| Array(ts).each { |t| index[t.to_s] << c.to_s } }
    index
  end

  def self.lookup_known_place(site, *texts)
    known = site.data['known_places'] || {}
    return nil if known.empty?
    haystack = texts.compact.join(' ')
    return nil if haystack.empty?
    known.keys.sort_by { |k| -k.length }.each do |key|
      if haystack.include?(key)
        entry = known[key]
        lat = (entry['lat'] || entry[:lat]).to_f
        lng = (entry['lng'] || entry[:lng]).to_f
        return { 'lat' => lat, 'lng' => lng, 'source' => "known:#{key}" } if lat != 0 && lng != 0
      end
    end
    nil
  end

  def self.resolve_coords(site, note, content, address, business, iframe_query, tags, cache)
    if note.data['coords'].is_a?(Array) && note.data['coords'].size == 2
      lat, lng = note.data['coords']
      return { 'lat' => lat.to_f, 'lng' => lng.to_f, 'source' => 'frontmatter' }
    end
    region = region_from_address(address) || region_from_tags(tags)
    title = note.data['title'].to_s
    hints = tags + [title]

    if iframe_query && !iframe_query.empty?
      iq = [iframe_query]
      iq << "#{iframe_query} #{region}" if region && !iframe_query.include?(region)
      result = GeocodeResolver.lookup_cascade(iq, hints, cache)
      return result if result
    end

    if business && !business.empty?
      biz_queries = business_variants(business).flat_map { |b| region ? [b, "#{b} #{region}"] : [b] }.uniq
      result = GeocodeResolver.lookup_cascade(biz_queries, hints, cache)
      return result if result
    end

    if (m = content.match(MAP_COORD_REGEX))
      lng = m[1].to_f
      lat = m[2].to_f
      if GeocodeResolver.in_korea?(lat, lng)
        return { 'lat' => lat, 'lng' => lng, 'source' => 'iframe' }
      else
        Jekyll.logger.warn('Places', "iframe outside KR for '#{title}'") if defined?(Jekyll)
      end
    end

    if address && !address.empty?
      result = GeocodeResolver.lookup_cascade(address_variants(address), hints, cache)
      return result if result
    end

    known = lookup_known_place(site, title, content)
    return known if known

    cleaned = clean_title_for_geocode(title)
    if cleaned && cleaned.length >= 3
      result = GeocodeResolver.lookup(cleaned, tags, cache, source_tag: 'nominatim:title')
      return result if result
    end

    nil
  end

  def self.clean_title_for_geocode(title)
    return nil if title.nil? || title.empty?
    t = title.dup
    t.gsub!(/_\d{6,8}(?:-\d{4,8})?/, ' ')
    t.gsub!(/\d{6,8}-\d{4,8}/, ' ')
    t.gsub!(/\([^)]*\)/, ' ')
    t.gsub!(/\[[^\]]*\]/, ' ')
    %w[광고 디지털보드 CM\s*보드 DID\s*스크린 DID광고 전광판 LED\s*스크린 Max\s*Vision DS\s*LED 스크린 보드 G-?Vision 유플렉스 대형].each do |kw|
      t.gsub!(/#{kw}/i, ' ')
    end
    t.gsub!(/\s+/, ' ').strip
    t.empty? ? nil : t
  end

  # 신규 항목을 places_db.yml 에 정렬 유지하며 추가
  def self.append_db_entry(title, entry)
    return if title.nil? || title.empty?
    require 'yaml'
    db_file = '_data/places_db.yml'
    db = File.exist?(db_file) ? (YAML.load_file(db_file) || {}) : {}
    db[title] = entry
    rewrite_db_sorted(db_file, db)
  rescue StandardError => e
    Jekyll.logger.warn('Places', "DB write failed for '#{title}': #{e.message}") if defined?(Jekyll)
  end

  def self.rewrite_db_sorted(db_file, db)
    esc = ->(s) { s.to_s.gsub('"', '\\"') }
    lines = [
      "# 노트별 좌표 DB",
      "# - places_generator 가 우선 참조",
      "# - 매핑된 노트: lat/lng/source",
      "# - 명시적 스킵: skipped: true",
      "# - 키는 알파벳 순 정렬",
      ""
    ]
    db.keys.sort.each do |k|
      v = db[k]
      next unless v.is_a?(Hash)
      lines << "\"#{esc.call(k)}\":"
      if v['skipped']
        lines << "  skipped: true"
        lines << "  reason: \"#{esc.call(v['reason'])}\"" if v['reason']
      else
        lines << "  lat: #{v['lat']}"
        lines << "  lng: #{v['lng']}"
        lines << "  source: #{v['source'] || 'unknown'}"
        lines << "  note: \"#{esc.call(v['note'])}\"" if v['note']
      end
    end
    new_content = lines.join("\n") + "\n"
    existing = File.exist?(db_file) ? File.read(db_file) : nil
    return if existing == new_content
    tmp = "#{db_file}.tmp"
    File.open(tmp, 'w:utf-8') do |f|
      f.write(new_content); f.fsync
    end
    File.rename(tmp, db_file)
  end

  class Generator < Jekyll::Generator
    safe true
    priority :low

    def generate(site)
      tag_to_cats = PlacesGenerator.build_tag_to_categories(site)
      cache = GeocodeResolver.load_cache
      db = site.data['places_db'] || {}

      places = []
      skipped = []
      newly_resolved = 0
      newly_skipped = 0
      all_tags_counter = Hash.new(0)
      source_counter = Hash.new(0)

      site.collections['notes'].docs.each do |note|
        content = note.content.to_s
        tags = Array(note.data['tags']).map(&:to_s)
        tags.each { |t| all_tags_counter[t] += 1 }

        title = note.data['title'].to_s
        addr = PlacesGenerator.extract_address(content)
        addr = nil if addr.empty?
        biz = PlacesGenerator.extract_business(content)
        iframe_q = PlacesGenerator.extract_iframe_query(content)
        ext_urls = PlacesGenerator.extract_external_urls(content)

        coords = nil
        db_entry = db[title]
        if db_entry.is_a?(Hash)
          if db_entry['skipped']
            skipped << title
            next
          elsif db_entry['lat'] && db_entry['lng']
            coords = { 'lat' => db_entry['lat'].to_f, 'lng' => db_entry['lng'].to_f, 'source' => db_entry['source'] || 'db' }
          end
        end

        unless coords
          coords = PlacesGenerator.resolve_coords(site, note, content, addr, biz, iframe_q, tags, cache)
          if coords
            newly_resolved += 1
            PlacesGenerator.append_db_entry(title, coords)
          else
            newly_skipped += 1
            PlacesGenerator.append_db_entry(title, { 'skipped' => true, 'reason' => 'resolver returned nil' })
            skipped << title
            next
          end
        end

        categories = tags.flat_map { |t| tag_to_cats[t] }.uniq
        categories << '기타' if categories.empty? && !tags.empty?
        source_counter[coords['source']] += 1

        places << {
          'title' => title, 'url' => "#{site.baseurl}#{note.url}",
          'lat' => coords['lat'], 'lng' => coords['lng'], 'source' => coords['source'],
          'address' => addr.to_s, 'business' => biz.to_s, 'iframe_q' => iframe_q.to_s,
          'kakao_url' => ext_urls['kakao'] ? "https://place.map.kakao.com/#{ext_urls['kakao']}" : '',
          'naver_url' => ext_urls['naver'].to_s,
          'region' => PlacesGenerator.region_from_address(addr) || PlacesGenerator.region_from_tags(tags),
          'tags' => tags, 'members' => Array(note.data['members']).map(&:to_s), 'categories' => categories
        }
      end

      if defined?(Jekyll)
        Jekyll.logger.info('Places', "mapped #{places.size}, skipped #{skipped.size} (#{newly_resolved} new resolved, #{newly_skipped} new skipped)")
        source_counter.sort_by { |_, c| -c }.each { |s, c| Jekyll.logger.info('Places', "  source #{s}: #{c}") }
        skipped.each { |t| Jekyll.logger.warn('Places', "skipped: #{t}") } if skipped.size <= 30
      end

      site.data['places']         = places
      site.data['places_count']   = places.size
      site.data['place_regions']  = places.map { |p| p['region'] }.compact.uniq.sort
      site.data['places_skipped'] = skipped

      cats_with_tags = {}
      raw_cats = site.data['tag_categories'] || {}
      raw_cats.each do |cat, tags|
        used = Array(tags).map(&:to_s).select { |t| all_tags_counter.key?(t) }
                          .sort_by { |t| -all_tags_counter[t] }
        cats_with_tags[cat] = used unless used.empty?
      end
      categorized = raw_cats.values.flatten.map(&:to_s).to_set
      uncategorized = all_tags_counter.keys.reject { |t| categorized.include?(t) }
                                           .sort_by { |t| -all_tags_counter[t] }
      cats_with_tags['기타'] = uncategorized unless uncategorized.empty?
      site.data['category_tags'] = cats_with_tags
    end
  end
end
