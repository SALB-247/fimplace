# frozen_string_literal: true
#
# [데이터 레이어 통합] 노트의 이벤트 기간을 한 곳에서 해석해 전 파이프라인에 공급.
#
# 지금까지 기간 표현이 3곳에 흩어져 있었다:
#   ① 본문 `## 기간` 섹션 (생일카페)   ② 제목/파일명 YYMMDD-YYMMDD (광고·이벤트)
#   ③ frontmatter end_date 등 (일부)   — 그리고 투어 표는 tour_schedule_generator 가 별도 처리.
#
# 이 플러그인이 ①②③을 하나의 우선순위로 해석해서 note.data 에 주입하고(1단계),
# 좌표가 해석된 뒤 events.json 으로 발행한다(2단계).
# 노트 작성 방식은 그대로 — 어떤 형식으로 쓰든 빌드 때 자동으로 DB 화된다.
#
# 해석 우선순위 (높은 것부터):
#   1. frontmatter `period: 2026-07-31 ~ 2026-08-01`  (또는 event_start / event_end)
#   2. frontmatter end_date / valid_until / ended_at   (기존 호환 — 종료일만)
#   3. 본문 `## 기간` 섹션 — 허용 표기:
#        2026-07-31 ~ 2026-08-01 / 단일 2026-08-15 / 구분자 ~ - – / 연도 2자리(25-08-01)도 관대 처리
#   4. 제목·파일명 — YYMMDD-YYMMDD / YYMMDD-MMDD / 단일 YYMMDD
#
# 주입 필드: note.data['event_start'|'event_end'] (Date), ['event_period_source']
# 검증: ③과 ④가 둘 다 있는데 종료일이 다르면 빌드 로그에 ⚠️ 경고 (자동 수정은 안 함)

require 'date'

module EventPeriod
  DASH = /[-–—~]/

  module_function

  def parse_ymd(s)
    m = s.match(/\A(\d{2}|\d{4})-(\d{1,2})-(\d{1,2})\z/)
    return nil unless m
    y = m[1].length == 2 ? 2000 + m[1].to_i : m[1].to_i
    Date.new(y, m[2].to_i, m[3].to_i)
  rescue ArgumentError
    nil
  end

  def parse_yymmdd(s)
    return nil unless s =~ /\A\d{6}\z/
    Date.new(2000 + s[0, 2].to_i, s[2, 2].to_i, s[4, 2].to_i)
  rescue ArgumentError
    nil
  end

  # "2026-07-31 ~ 2026-08-01" / "2026-08-15" / "2025-07-30 ~ 25-08-01" → [start, end]
  def parse_range_text(text)
    s = text.to_s.strip
    return nil if s.empty?
    dates = s.scan(/(\d{2,4}-\d{1,2}-\d{1,2})/).flatten.map { |d| parse_ymd(d) }.compact
    return nil if dates.empty?
    [dates.first, dates.last].sort
  end

  # 본문 `## 기간` 섹션의 첫 줄
  def from_gigan_section(content)
    m = content.match(/^##\s*기간\s*\n+(.+)$/)
    return nil unless m
    parse_range_text(m[1])
  end

  # 제목/파일명 패턴
  def from_title(str)
    s = str.to_s
    if (m = s.match(/(\d{6})[-_~](\d{6})(?=[^\d]|\z)/))
      a = parse_yymmdd(m[1]); b = parse_yymmdd(m[2])
      return [a, b].compact.sort if a || b
    end
    if (m = s.match(/(\d{6})[-_~](\d{4})(?=[^\d]|\z)/))
      a = parse_yymmdd(m[1]); b = parse_yymmdd(m[1][0, 2] + m[2])
      return [a, b].compact.sort if a || b
    end
    if (m = s.match(/(?:\A|[_\s(])(\d{6})(?=[^\d]|\z)/))
      d = parse_yymmdd(m[1])
      return [d, d] if d
    end
    nil
  end

  # 노트 하나의 기간 해석. [start(Date), end(Date), source(String)] 또는 nil
  def resolve(note)
    fm = note.data

    # 1. period / event_start·event_end
    if fm['period']
      r = parse_range_text(fm['period'].to_s)
      return [r[0], r[1], 'frontmatter:period'] if r
    end
    if fm['event_start'] || fm['event_end']
      a = to_date(fm['event_start'])
      b = to_date(fm['event_end'])
      return [a || b, b || a, 'frontmatter:event'] if a || b
    end

    # 2. 기존 종료일 필드 (start 는 4의 시작일 활용)
    legacy_end = %w[end_date valid_until ended_at].map { |k| to_date(fm[k]) }.compact.first

    # 3. 본문 ## 기간
    gigan = from_gigan_section(note.content.to_s)

    # 4. 제목/파일명
    title_range = from_title(File.basename(note.path.to_s, '.*')) || from_title(fm['title'])

    # ③④ 교차검증 (종료일 불일치 경고)
    if gigan && title_range && gigan[1] != title_range[1]
      Jekyll.logger.warn('EventPeriod',
        "⚠️ 기간 불일치: #{fm['title']} — 기간섹션 #{gigan[1]} vs 제목 #{title_range[1]} (기간섹션 채택)")
    end

    if gigan
      [gigan[0], legacy_end || gigan[1], legacy_end ? 'gigan+legacy_end' : 'gigan']
    elsif title_range
      [title_range[0], legacy_end || title_range[1], legacy_end ? 'title+legacy_end' : 'title']
    elsif legacy_end
      [nil, legacy_end, 'legacy_end']
    end
  end

  def to_date(v)
    return nil if v.nil? || v.to_s.empty?
    v.is_a?(Date) ? v : Date.parse(v.to_s)
  rescue ArgumentError
    nil
  end

  # ───────── 방문/컨텐츠 날짜 레이어 ─────────
  # 이벤트 '기간' 이 없는 노트도 대부분 날짜 소스를 갖는다:
  #   · 메모줄  "260614 허윤진 인스타 / 260616 홍은채 인스타"  (복수 가능)
  #   · IG embed 의 shortcode — 게시 시각이 인코딩돼 있음 (네트워크 불필요 디코드)
  #   · YouTube embed — _data/video_dates.yml 캐시 (scripts/fetch_video_dates.py 가 갱신)

  IG_ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_'

  # instagram shortcode → 게시일 (KST). media_id 상위비트가 timestamp.
  # ※ shift 는 통설 22 가 아니라 23 (프로젝트에서 26건 실측 검증)
  def ig_code_date(code)
    n = 0
    code.each_char do |ch|
      i = IG_ALPHABET.index(ch)
      return nil unless i
      n = n * 64 + i
    end
    ms = (n >> 23) + 1_314_220_021_721
    return nil if ms <= 1_314_220_021_721
    Time.at(ms / 1000.0).getlocal('+09:00').to_date
  rescue StandardError
    nil
  end

  # 6자리 YYMMDD 또는 8자리 YYYYMMDD → Date
  def parse_date_token(tok)
    return parse_yymmdd(tok) if tok.length == 6
    return nil unless tok.length == 8 && tok =~ /\A\d{8}\z/
    Date.new(tok[0, 4].to_i, tok[4, 2].to_i, tok[6, 2].to_i)
  rescue ArgumentError
    nil
  end

  # 본문 메모줄에서 방문 기록 추출: [{'date'=>Date,'label'=>String}, ...]
  # 허용 형식: "260614 허윤진 인스타" / "20250505_채원 DM" / "260724_SPECIAL_..." / "251125_윤진 DM"
  #   날짜(6 또는 8자리) 뒤 구분자는 공백 또는 언더스코어. '/' 로 한 줄에 복수 기록도 지원.
  def memo_visits(content)
    out = []
    content.to_s.each_line do |line|
      s = line.strip
      next if s.empty? || s.start_with?('<', '#', '[', '!', '|', '-')
      s.split(%r{\s*/\s*}).each do |seg|
        m = seg.strip.match(/\A(\d{8}|\d{6})[_\s]+(.+)\z/)
        next unless m
        d = parse_date_token(m[1])
        out << { 'date' => d, 'label' => m[2].strip.gsub('_', ' ')[0, 40] } if d
      end
    end
    out
  end

  # 컨텐츠 게시일 목록: IG shortcode(게시일) + YouTube 업로드일 — 전부 반환 (중복 제거)
  #   ⚠️ fallback 이 아니라 '방문 날짜'와 별개의 독립 날짜로 취급 → 본문 날짜와 영상 날짜가 둘 다 DB 에 남음
  def content_dates(content, video_dates)
    out = []
    content.to_s.scan(%r{instagram\.com/(?:p|reel)/([A-Za-z0-9_-]{8,})/embed}) do |(code)|
      d = ig_code_date(code)
      out << { 'date' => d, 'label' => 'IG 게시' } if d
    end
    content.to_s.scan(%r{youtube(?:-nocookie)?\.com/embed/([A-Za-z0-9_-]{11})}) do |(vid)|
      v = video_dates[vid]
      out << { 'date' => Date.parse(v), 'label' => '영상 업로드' } if v
    end
    out
  end

  # ── 허브 표 날짜 레이어 ──
  # "-SNS 장소" 같은 모음(hide_backlinks) 노트의 표가 장소별 날짜의 정본인 경우:
  #   | [[노트제목]] | 위치 | 날짜 | 멤버 | SNS |
  # 헤더에 '날짜' 컬럼이 있는 표만 파싱해 { 제목 => {date, label} } 맵을 만든다.
  def hub_date_map(site)
    map = {}
    site.collections['notes'].docs.each do |note|
      next unless note.data['hide_backlinks']
      lines = note.content.to_s.lines.map(&:strip).select { |l| l.start_with?('|') }
      next if lines.size < 3

      header = lines[0].split('|').map(&:strip)
      di = header.index { |h| h.include?('날짜') }
      next unless di
      mi = header.index { |h| h.include?('멤버') }
      si = header.index { |h| h =~ /SNS|콘텐츠|컨텐츠/ }

      lines.drop(2).each do |row|
        cells = row.split('|').map(&:strip)
        link = cells.find { |c| c =~ /\[\[/ }
        next unless link
        title = link[/\[\[([^\]|]+)/, 1].to_s.strip
        date_cell = cells[di].to_s
        d = date_cell[/\d{4}-\d{2}-\d{2}/]
        next if title.empty? || d.nil?
        begin
          date = Date.parse(d)
        rescue ArgumentError
          next
        end
        label = [mi && cells[mi], si && cells[si]].compact.reject(&:empty?).join(' ')
        map[title] ||= { 'date' => date, 'label' => label[0, 40] }
      end
    end
    map
  end

  # 이벤트 유형 추론 (tags 기준)
  def infer_type(tags)
    t = tags.join(' ')
    return '생일카페'  if t.include?('생일카페')
    return '광고'      if t.include?('생일광고') || t.include?('광고')
    return '팝업'      if t.include?('팝업스토어')
    return '투어이벤트' if t =~ /TOUR|PUREFLOW|FEARNADA/
    '이벤트'
  end

  # ── 1단계: 기간 해석 → note.data 주입 (places_generator(:low) 보다 먼저) ──
  class PeriodInjector < Jekyll::Generator
    safe true
    priority :normal

    def generate(site)
      video_dates = site.data['video_dates'] || {}
      hub_dates   = EventPeriod.hub_date_map(site)
      n = visited = hubbed = contented = 0

      site.collections['notes'].docs.each do |note|
        r = EventPeriod.resolve(note)
        if r
          note.data['event_start']         = r[0]
          note.data['event_end']           = r[1]
          note.data['event_period_source'] = r[2]
          n += 1
        end

        # 날짜 소스를 모두 합침 (한 장소가 여러 번 방문·촬영되면 전부 DB 화):
        #   ① 본문 메모줄  ② 허브 표(-SNS 장소 등)  ③ 컨텐츠 게시일(IG·YouTube)
        #   ⚠️ 본문 날짜와 영상 업로드일이 둘 다 있으면 둘 다 남긴다 (사용자 요청).
        visits = EventPeriod.memo_visits(note.content)
        if (h = hub_dates[note.data['title'].to_s])
          visits << h
          hubbed += 1
        end
        cds = EventPeriod.content_dates(note.content, video_dates)
        contented += 1 unless cds.empty?
        visits.concat(cds)

        # 같은 날짜 중복 제거 (라벨은 먼저 잡힌 것 우선), 날짜순 정렬
        uniq = {}
        visits.each { |v| next unless v['date']; k = v['date'].to_s; uniq[k] ||= v }
        merged = uniq.values.sort_by { |v| v['date'] }
        unless merged.empty?
          note.data['visit_dates'] = merged
          visited += 1
        end
      end
      Jekyll.logger.info('EventPeriod',
        "기간 #{n} / 날짜있는노트 #{visited} (허브표 #{hubbed}, 컨텐츠 #{contented})")
    end
  end

  # ── 2단계: 좌표(:low에서 해석됨) 붙여 events 데이터 조립 ──
  class EventsAssembler < Jekyll::Generator
    safe true
    priority :lowest

    def generate(site)
      by_url = {}
      Array(site.data['places']).each { |p| by_url[p['url'].to_s] = p }

      events = []
      site.collections['notes'].docs.each do |note|
        s = note.data['event_start']
        e = note.data['event_end']
        next unless s || e
        next if note.data['hide_backlinks']   # 모음/허브 페이지 제외

        url = "#{site.baseurl}#{note.url}"
        place = by_url[url]
        tags = Array(note.data['tags']).map(&:to_s)
        events << {
          'title'   => note.data['title'].to_s,
          'url'     => url,
          'type'    => EventPeriod.infer_type(tags),
          'start'   => (s || e).strftime('%Y-%m-%d'),
          'end'     => (e || s).strftime('%Y-%m-%d'),
          'source'  => note.data['event_period_source'],
          'lat'     => place && place['lat'],
          'lng'     => place && place['lng'],
          'address' => place && place['address'],
          'tags'    => tags,
          'members' => Array(note.data['members']).map(&:to_s)
        }
      end

      events.sort_by! { |ev| [ev['start'], ev['title']] }
      site.data['events'] = events
      Jekyll.logger.info('EventPeriod', "events: #{events.size}건 (유형: " +
        events.group_by { |ev| ev['type'] }.map { |k, v| "#{k} #{v.size}" }.join(', ') + ')')
    end
  end
end
