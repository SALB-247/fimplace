# frozen_string_literal: true
#
# 노트별 좌표 해석 + places.json 생성
# - 우선순위: DB 캐시 -> frontmatter coords -> iframe 검색어 -> 상호명 -> 주소 캐스케이드 -> known_places -> cleaned title -> iframe !2d!3d (최후 fallback, KR만)
# - iframe URL의 !2d/!3d는 지도 뷰포트 중심값이라 마커 좌표와 다를 수 있어 신뢰도 낮음 (Place ID 필요)
# - 신규 해석된 노트는 _data/places_db.yml 에 정렬 유지하며 자동 추가
require 'json'
require 'set'
require 'base64'
require 'date'

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

  # 일본 광역 단위 (도도부현). 도시명은 광역으로 alias.
  # 노트의 tags 에서 직접 매칭. 매칭은 긴 키 우선 (예: "야마나시현" > "야마나시")
  JP_REGION_ALIAS = {
    '도쿄'       => '도쿄',
    '오다이바'   => '도쿄',
    '오사카'     => '오사카',
    '교토'       => '교토',
    '나고야'     => '아이치현',
    '아이치현'   => '아이치현',
    '야마나시현' => '야마나시현',
    '미에현'     => '미에현',
    '카나가와현' => '카나가와현',
    '고베'       => '효고현',
    '효고현'     => '효고현',
    '홋카이도'   => '홋카이도',
    '후쿠오카'   => '후쿠오카'
  }
  JP_REGION_KEYS_SORTED = JP_REGION_ALIAS.keys.sort_by { |k| -k.length }

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

  def self.region_from_address(addr, country = nil)
    return nil if addr.nil? || addr.empty?
    return nil if country && country != 'kr'
    DOMINANT_REGIONS.each { |prefix| return prefix if addr.include?(prefix) }
    nil
  end

  def self.region_from_tags(tags, country = nil)
    arr = Array(tags).map(&:to_s)
    if country == 'jp'
      arr.each do |t|
        JP_REGION_KEYS_SORTED.each { |k| return JP_REGION_ALIAS[k] if t.include?(k) }
      end
      return nil
    end
    return nil if country && country != 'kr'
    arr.each do |t|
      DOMINANT_REGIONS.each { |prefix| return prefix if t.include?(prefix) }
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

  # YYMMDD 6자리 문자열 → Date (잘못된 값이면 nil)
  def self.parse_yymmdd(str)
    return nil unless str.is_a?(String) && str =~ /\A\d{6}\z/
    Date.new(2000 + str[0..1].to_i, str[2..3].to_i, str[4..5].to_i)
  rescue ArgumentError
    nil
  end

  # 종료 여부 판정.
  # 우선순위:
  # 1) frontmatter end_date / valid_until / ended_at (YYYY-MM-DD 또는 Date)
  # 2) 파일명 또는 title 에서 YYMMDD[-_~]YYMMDD 패턴 종료일
  # 3) 파일명 또는 title 에서 YYMMDD[-_~]MMDD 패턴 (시작의 YY 차용)
  # 매칭이 하나도 안 잡히면 nil (판정 불가 — 클라이언트 fallback)
  def self.detect_ended(note, today)
    # frontmatter 명시적 종료 플래그 (ended: true) 최우선
    return true if note.data['ended'] == true
    # 통합 기간 해석 결과 (event_period_generator 가 :normal 에서 주입 — 기간섹션·제목·frontmatter 통합)
    if (ev_end = note.data['event_end'])
      return ev_end < today
    end
    %w[end_date valid_until ended_at].each do |k|
      v = note.data[k]
      next if v.nil? || v.to_s.empty?
      begin
        d = v.is_a?(Date) ? v : Date.parse(v.to_s)
        return d < today
      rescue ArgumentError
        # invalid date string, skip
      end
    end

    candidates = []
    candidates << File.basename(note.path, '.*') if note.respond_to?(:path) && note.path
    candidates << note.data['title'].to_s
    candidates.compact.uniq.each do |s|
      next if s.empty?
      if (m = s.match(/(\d{6})[-_~](\d{6})(?=[^\d]|\z)/))
        d = parse_yymmdd(m[2])
        return d < today if d
      end
      if (m = s.match(/(\d{6})[-_~](\d{4})(?=[^\d]|\z)/))
        d = parse_yymmdd(m[1][0..1] + m[2])
        return d < today if d
      end
    end

    nil
  end

  # 리스트 '최신순' 정렬용 날짜 추출.
  # 우선순위: frontmatter date → 제목의 YYMMDD(이벤트) → 본문 메모줄 'YYMMDD ...' 의 YYMMDD
  def self.extract_date(note, content)
    v = note.data['date']
    if v
      begin
        return v.is_a?(Date) ? v : Date.parse(v.to_s)
      rescue ArgumentError
        # invalid, fall through
      end
    end
    title = note.data['title'].to_s
    if (m = title.match(/(\d{6})/))
      d = parse_yymmdd(m[1])
      return d if d
    end
    content.to_s.each_line do |line|
      s = line.strip
      if (m = s.match(/\A(\d{6})\b/))
        d = parse_yymmdd(m[1])
        return d if d
      end
    end
    # 방문 기록 (메모줄·허브표·영상/IG 게시일 — event_period_generator 가 통합 주입).
    # 대표 date 는 '최신순' 정렬용이므로 가장 최근 날짜. 재방문 장소는 최근 방문으로 랭크됨.
    dates = Array(note.data['visit_dates']).map { |v| v['date'] }.compact
    return dates.max unless dates.empty?
    nil
  end

  # 이벤트 모음/목차 페이지 자동 감지
  # 핵심 기준: "위치/상호명 섹션이 없는데 내부 링크가 다수" — 단일 장소가 아닌 인덱스
  # 보조 기준: 총집편, 또는 "이벤트" + 모음 키워드, 또는 "이벤트"인데 날짜범위 없음
  def self.compilation_page?(title, content)
    has_location_block = content =~ /##\s*(위치|주소|상호명)/
    links_count = content.scan(/\[\[[^\]]+\]\]/).size

    # 명백한 키워드: 총집편 (단일 키워드만으로 확정)
    return true if title.include?('총집편')

    # "이벤트"가 들어간 제목 + YYMMDD-YYMMDD 날짜범위 없음 + 내부 링크 4개 이상
    if title.include?('이벤트') && title !~ /\d{6}\s*[-~]\s*\d{6}/
      return true if links_count >= 4 && !has_location_block
    end

    # "모음" 단어가 본문/제목에 있고 단일 위치 정보 없음
    if (title.include?('모음') || content.include?('모음')) && !has_location_block && links_count >= 4
      return true
    end

    # 내부 링크가 매우 많고 위치 정보 없음 (일반 인덱스 페이지)
    return true if links_count >= 8 && !has_location_block

    false
  end

  # frontmatter 의 coords / lat-lng 를 어떤 형식이든 [lat, lng] 로 정규화.
  # 지원 형식:
  #   coords: [37.5, 127.0]           (배열)
  #   coords: 37.5, 127.0             (무따옴표 콤마)
  #   coords: "37.5, 127.0"           (따옴표)
  #   coords: "[37.5, 127.0]"         (따옴표 + 대괄호)
  #   lat: 37.5  /  lng: 127.0        (두 필드)
  # (0, 0) 은 placeholder 로 간주해 무시.
  def self.parse_frontmatter_coords(note)
    raw = note.data['coords']
    pair = nil
    case raw
    when Array
      pair = [raw[0], raw[1]] if raw.size == 2
    when String
      cleaned = raw.gsub(/[\[\]]/, '').strip
      parts = cleaned.split(',').map(&:strip)
      pair = parts if parts.size == 2
    end
    pair ||= [note.data['lat'], note.data['lng']] if note.data['lat'] && note.data['lng']
    return nil unless pair && pair.size == 2

    begin
      lat = Float(pair[0].to_s)
      lng = Float(pair[1].to_s)
    rescue ArgumentError, TypeError
      return nil
    end
    return nil if lat == 0.0 && lng == 0.0
    return nil if lat.abs > 90 || lng.abs > 180
    { 'lat' => lat, 'lng' => lng, 'source' => 'frontmatter' }
  end

  def self.resolve_coords(site, note, content, address, business, iframe_query, tags, cache)
    # frontmatter coords 는 generate() 에서 이미 우선 처리됨.
    # 여기는 폴백: iframe → business → address → known_places → cleaned title → iframe!2d!3d

    region = region_from_address(address) || region_from_tags(tags)
    title = note.data['title'].to_s
    hints = tags + [title]

    # iframe 검색어 (!2z base64) — 가장 신뢰도 높은 식별자
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

    # 최후의 보루: iframe !2d!3d (지도 뷰포트 중심값이라 부정확 가능 — 한국 영역만 허용)
    if (m = content.match(MAP_COORD_REGEX))
      lng = m[1].to_f
      lat = m[2].to_f
      if GeocodeResolver.in_korea?(lat, lng)
        return { 'lat' => lat, 'lng' => lng, 'source' => 'iframe' }
      end
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
      today = Date.today

      places = []
      skipped = []
      newly_resolved = 0
      newly_skipped = 0
      all_tags_counter = Hash.new(0)
      source_counter = Hash.new(0)

      site.collections['notes'].docs.each do |note|
        # 모음/인덱스 페이지(hide_backlinks)는 실제 장소가 아니므로 지도에서 제외
        if note.data['hide_backlinks']
          skipped << note.data['title'].to_s
          next
        end
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

        # 1) frontmatter coords / lat-lng 최우선 — 사용자가 명시한 좌표는 캐시·자동감지보다 우선
        coords = PlacesGenerator.parse_frontmatter_coords(note)

        # 2) db 캐시 (frontmatter 없을 때만)
        unless coords
          db_entry = db[title]
          if db_entry.is_a?(Hash)
            if db_entry['skipped']
              skipped << title
              next
            elsif db_entry['lat'] && db_entry['lng']
              coords = { 'lat' => db_entry['lat'].to_f, 'lng' => db_entry['lng'].to_f, 'source' => db_entry['source'] || 'db' }
            end
          end
        end

        # 3) 이벤트 모음/목차 페이지 자동 감지 → skipped 캐싱
        if !coords && PlacesGenerator.compilation_page?(title, content)
          PlacesGenerator.append_db_entry(title, { 'skipped' => true, 'reason' => '이벤트 모음/목차 페이지 (자동 감지)' })
          newly_skipped += 1
          skipped << title
          next
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

        country = note.data['country'].to_s.downcase
        country = 'kr' if country.empty?
        region = PlacesGenerator.region_from_address(addr, country) ||
                 PlacesGenerator.region_from_tags(tags, country)
        ended = PlacesGenerator.detect_ended(note, today)
        date = PlacesGenerator.extract_date(note, content)
        places << {
          'title' => title, 'url' => "#{site.baseurl}#{note.url}",
          'lat' => coords['lat'], 'lng' => coords['lng'], 'source' => coords['source'],
          'address' => addr.to_s, 'business' => biz.to_s, 'iframe_q' => iframe_q.to_s,
          'kakao_url' => ext_urls['kakao'] ? "https://place.map.kakao.com/#{ext_urls['kakao']}" : '',
          'naver_url' => ext_urls['naver'].to_s,
          'country' => country,
          'region' => region,
          'ended' => ended,
          'date' => (date ? date.strftime('%Y-%m-%d') : nil),
          'start' => (note.data['event_start'] ? note.data['event_start'].strftime('%Y-%m-%d') : nil),
          'end' => (note.data['event_end'] ? note.data['event_end'].strftime('%Y-%m-%d') : nil),
          'visits' => Array(note.data['visit_dates']).map { |v| { 'date' => v['date'].strftime('%Y-%m-%d'), 'label' => v['label'] } },
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
      # yml 에 정의된 '기타' 태그와 자동 감지 미분류 태그를 병합 (덮어쓰기 방지)
      unless uncategorized.empty?
        existing = cats_with_tags['기타'] || []
        cats_with_tags['기타'] = (existing + uncategorized).uniq
      end
      site.data['category_tags'] = cats_with_tags
    end
  end
end
