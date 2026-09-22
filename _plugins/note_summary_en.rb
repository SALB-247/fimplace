# frozen_string_literal: true
#
# 외국인용 한 줄 요약 (2026-09-21) — note.data['summary_en']
#
# 본문(설명문)은 한국어 그대로지만, 구조 데이터만으로 만들 수 있는 요약은 영어로 준다:
#   "Convenience store · Gangnam, Seoul · KIM CHAEWON · Weverse (2023-06-05)"
#   "Venue · Songpa, Seoul · HUH YUNJIN · Featured in LE PLAY"
#   "Cafe · Tokyo, Japan · all members · Featured in FIM-LOG · Permanently closed"
# 재료: 태그(장소 유형·지역·컨텐츠 시리즈·SNS 플랫폼, _data/i18n.yml tags 로 번역) · members(member_extractor) ·
#       category_en(places_en.rb, 구글 카테고리가 있으면 더 구체적이라 우선) · 첫 메모 줄의 날짜 · closed/ended.
# note.html 이 <p class="note-summary-en i18n-en-only" hidden> 으로 찍고 영어 모드에서만 보인다.

module NoteSummaryEn
  MEMBER_ORDER = %w[사쿠라 김채원 허윤진 카즈하 홍은채].freeze
  SNS_TAGS = %w[인스타 위버스 DM 멤트 공트 틱톡 위버스라이브 역조공].freeze

  module_function

  def section(site, *names)
    tc = site.data['tag_categories'] || {}
    names.flat_map { |n| Array(tc[n]).map(&:to_s) }
  end

  # 현재 만들고 있는 요약의 언어 ('en' | 'ja'). generate 가 노트마다 순차로 세팅한다.
  def lang
    @lang || 'en'
  end

  def lang=(v)
    @lang = v
  end

  # 주소로 만든 지역 이름은 영어다 ('Jongno', 'Seoul') — 영어 값을 열쇠로 그 언어 이름을 찾는다
  def region_alt(site, en_name)
    @region_alt ||= {}
    @region_alt[lang] ||= begin
      map = {}
      %w[regions tags].each do |g|
        ko_en = ((site.data['i18n'] || {})[g] || {})
        ko_x  = ((site.data["i18n_#{lang}"] || {})[g] || {})
        ko_en.each { |ko, en| map[en.to_s] ||= ko_x[ko].to_s if ko_x[ko] }
      end
      map
    end
    @region_alt[lang][en_name.to_s] || en_name
  end

  def tr(site, group, key)
    if lang != 'en'
      dx = (site.data["i18n_#{lang}"] || {})[group] || {}
      v = dx[key]
      return v.to_s unless v.nil? || v.to_s.empty?
    end
    d = (site.data['i18n'] || {})[group] || {}
    v = d[key]
    v.nil? || v.to_s.empty? ? key : v.to_s
  end

  # 첫 메모 줄 → [플랫폼(한국어 태그 또는 플랫폼 단어), YYYY-MM-DD]
  PROVINCE_EN = {
    'Gyeonggi-do' => 'Gyeonggi', 'Gangwon-do' => 'Gangwon', 'Gangwon State' => 'Gangwon',
    'Jeollanam-do' => 'South Jeolla', 'Jeollabuk-do' => 'North Jeolla', 'Jeonbuk-do' => 'North Jeolla', 'Jeonbuk State' => 'North Jeolla',
    'Gyeongsangnam-do' => 'South Gyeongsang', 'Gyeongsangbuk-do' => 'North Gyeongsang',
    'Chungcheongnam-do' => 'South Chungcheong', 'Chungcheongbuk-do' => 'North Chungcheong', 'Jeju-do' => 'Jeju'
  }.freeze
  METRO_EN = %w[Seoul Busan Daegu Incheon Gwangju Daejeon Ulsan Sejong].freeze

  # 구글 영어 주소 → ['Damyang', 'South Jeolla'] / ['Yongsan', 'Seoul'] (못 읽으면 [])
  def region_from_address_en(addr)
    toks = addr.to_s.split(/\s*,\s*/).map { |x| x.sub(/\s+KR\z/, '').strip }
    top = nil
    toks.each do |x|
      if PROVINCE_EN[x] then top = PROVINCE_EN[x]
      elsif METRO_EN.include?(x) then top = x
      end
    end
    return [] unless top
    dist = toks.find { |x| x != top && !PROVINCE_EN[x] && x =~ /\A[A-Z][A-Za-z]+(?:-(?:si|gun|gu)| District)\z/ }
    return [top] unless dist
    base = dist.sub(/ District\z/, '').sub(/-(?:si|gun)\z/, '')
    base = base.sub(/-gu\z/, '') unless base =~ /\A(Jung|Nam|Dong|Seo|Buk)-gu\z/
    [base, top]
  end

  def memo_source(note)
    body = note.content.to_s.gsub(/<!--.*?-->/m, '')
    body.each_line do |l|
      s = l.strip
      next if s.empty? || s.start_with?('<', '#', '|', '!', '```', '{')
      if (m = s.match(/\A(\d{6})[ _]\S+(?:\s+(인스타그램|인스타 스토리|인스스|인스타|위버스 포스트|위버스 DM|위버스 라이브|위버스|DM|라이브|위라|멤트|공트|틱톡|트위터))?/))
        yy, mm, dd = m[1][0, 2], m[1][2, 2], m[1][4, 2]
        return [m[2], "20#{yy}-#{mm}-#{dd}"]
      end
      if (m = s.match(/\[위버스 포스트\d*\]\([^)]*\)\s*\((\d{6}) /))
        yy, mm, dd = m[1][0, 2], m[1][2, 2], m[1][4, 2]
        return ['위버스', "20#{yy}-#{mm}-#{dd}"]
      end
      return [nil, nil]
    end
    [nil, nil]
  end

  def build(site, note)
    tags = Array(note.data['tags']).map(&:to_s)
    parts = []

    # 1) 유형 — 구글 카테고리 > 장소 유형 태그 > 이벤트 태그
    types = section(site, '장소 유형')
    cat = tags.find { |t| types.include?(t) }
    ev  = tags.find { |t| t =~ /(_이벤트|생일카페|생일광고|생일_기타|주년_광고|_광고)\z/ }
    label = note.data['category_en'].to_s
    label = (cat == '기타장소' ? 'Place' : tr(site, 'tags', cat)) if label.empty? && cat
    label = tr(site, 'tags', ev) if label.empty? && ev
    parts << label unless label.empty?

    # 2) 지역
    country = note.data['country'].to_s.downcase
    country = 'kr' if country.empty?
    region = []
    if country == 'kr'
      seoul = section(site, '서울 (구별)', '서울(구별)')
      gg    = section(site, '경기')
      wide  = section(site, '광역 지역')
      gu = tags.find { |t| seoul.include?(t) }
      w  = tags.find { |t| (wide + gg).include?(t) && t != '서울' }
      # 주소가 더 구체적이다 ('경기 파주시' → 'Paju, Gyeonggi'); 없으면 태그로
      if defined?(PageDescription) && defined?(HubEnPages)
        ko = PageDescription.region_phrase(site, note, tags).to_s
        en = ko.empty? ? '' : HubEnPages.region_cell(site, ko)
        region = [en] unless en.empty? || en =~ /[가-힣]/ || en !~ /,/
      end
      # 한국어 주소로 못 잡으면 구글 영어 주소('119 Jungnogwon-ro, Damyang-eup, Damyang-gun, Jeollanam-do')에서
      region = region_from_address_en(note.data['address_en']) if region.empty? && note.data['address_en']
      if region.empty?
        if gu
          region = [tr(site, 'tags', gu), 'Seoul']
        elsif w
          region = [tr(site, 'tags', w)]
          region << 'Gyeonggi' if gg.include?(w) && region[0] !~ /Gyeonggi/
        elsif tags.include?('서울')
          region = ['Seoul']
        end
      end
      region << (lang == 'ja' ? '韓国' : 'Korea')
    else
      cities = section(site, '일본 (지역)', '일본(지역)', '해외 (지역)', '해외(지역)')
      labels = section(site, '국가 (라벨)', '국가(라벨)')
      lab  = tags.find { |t| labels.include?(t) }
      city = tags.find { |t| cities.include?(t) && t != lab }
      region = [city && tr(site, 'tags', city), lab && tr(site, 'countries', lab)].compact
    end
    # 'Jung-gu, Busan' 처럼 이미 합쳐진 값도 있어 쉼표로 쪼개 하나씩 옮긴다
    if lang != 'en'
      region = region.flat_map { |r| r.to_s.split(/,\s*/) }.map { |r| region_alt(site, r) }
    end
    parts << region.uniq.join(', ') unless region.empty?

    # 3) 멤버
    ms = Array(note.data['members']).map(&:to_s).uniq
    parts << if ms.empty? || ms.size >= 5
               (lang == 'ja' ? 'メンバー全員' : 'all members')
             else
               (MEMBER_ORDER.select { |m| ms.include?(m) } + (ms - MEMBER_ORDER)).map { |m| tr(site, 'members', m) }.join(' · ')
             end

    # 4) 출처 — 자체/외부 컨텐츠 시리즈 > SNS 플랫폼 + 날짜
    series = section(site, '컨텐츠 (자체)', '컨텐츠(자체)', '컨텐츠 (외부)', '컨텐츠(외부)') - %w[자체컨텐츠_촬영지 외부컨텐츠 유튜브]
    sr = tags.find { |t| series.include?(t) }
    plat_tag = tags.find { |t| SNS_TAGS.include?(t) }
    memo_plat, memo_date = memo_source(note)
    if sr == 'MV_촬영지'
      parts << (lang == 'ja' ? 'MV 撮影地' : 'Music video filming spot')
    elsif sr
      parts << (lang == 'ja' ? "#{tr(site, 'tags', sr)} に登場" : "Featured in #{tr(site, 'tags', sr)}")
    elsif plat_tag || memo_plat
      plats = ((site.data['i18n'] || {})['body'] || {})['platforms'] || {}
      if lang != 'en'
        px = ((site.data["i18n_#{lang}"] || {})['body'] || {})['platforms'] || {}
        plats = plats.merge(px)
      end
      p = memo_plat ? (plats[memo_plat] || memo_plat) : tr(site, 'tags', plat_tag)
      parts << (memo_date ? "#{p} (#{memo_date})" : p)
    elsif tags.include?('자체컨텐츠_촬영지')
      parts << (lang == 'ja' ? '公式コンテンツに登場' : 'Featured in official content')
    elsif tags.include?('외부컨텐츠')
      parts << (lang == 'ja' ? '外部メディアに登場' : 'Featured in external media')
    elsif !tags.include?('공연장') && (vid = note.content.to_s[%r{(?:youtube(?:-nocookie)?\.com/embed/|youtu\.be/)([A-Za-z0-9_-]{11})}, 1])
      # 대분류 태그도 메모 줄도 없이 영상만 임베드된 오래된 노트 — 업로드일 캐시로 'YouTube (2026-05-27)'
      up = (site.data['video_dates'] || {})[vid]
      parts << (up ? "YouTube (#{up})" : 'YouTube')
    end

    # 5) 상태
    closed = note.data['closed']
    parts << (lang == 'ja' ? '閉店' : 'Permanently closed') if closed && closed != false
    if note.data['ended'] == true || (note.data['event_end'].respond_to?(:<) && note.data['event_end'] < Date.today)
      parts << (lang == 'ja' ? '終了' : 'Ended')
    end
    parts.join(' · ')
  end

  class Generator < Jekyll::Generator
    safe true
    priority :lowest   # members(member_extractor)·event_period·places_en 뒤

    def generate(site)
      n = 0
      site.collections['notes'].docs.each do |note|
        next if note.data['hide_backlinks']
        next if note.data['summary_en'].to_s != ''
        # 생일 이벤트 모음처럼 링크 목록만 있는 페이지(상호명 없음 · 내부 링크 5개↑)는 요약이 무의미
        c = note.content.to_s
        next if c !~ /^##\s*상호명/ && c.scan(/internal-link|\[\[/).size >= 5
        NoteSummaryEn.lang = 'en'
        s = NoteSummaryEn.build(site, note)
        next if s.empty?
        note.data['summary_en'] = s
        n += 1
        next unless site.data['i18n_ja']
        NoteSummaryEn.lang = 'ja'
        sj = NoteSummaryEn.build(site, note)
        note.data['summary_ja'] = sj if sj != '' && sj != s
      end
      NoteSummaryEn.lang = 'en'
      Jekyll.logger.info('NoteSummaryEn', "요약 #{n}건 (en" + (site.data['i18n_ja'] ? ' + ja' : '') + ')')
    end
  end
end
