# frozen_string_literal: true
#
# 노트 본문의 반복 문구 영어화 (2026-09-21)
#
# 노트 본문(설명문·상호명·주소)은 번역하지 않는다는 원칙은 그대로다. 대신 모든 노트에 똑같이 반복되는
# '껍데기' 문구 — 소제목(상호명·위치·기간…), 지도 링크 라벨(구글맵·네이버지도·카카오 지도), 메모 줄의
# 'YYMMDD 멤버 플랫폼', 영상 줄 끝의 (전원)·(멤버), ※ 폐업함 … — 는 사전으로 확실히 옮길 수 있다.
#
# 방식: 노트 변환 직후(:post_convert) HTML 을 Nokogiri 로 열어 해당 요소·텍스트 조각에 data-en 을 단다.
# 영어 모드에서는 _layouts/note.html 의 스크립트가 `content [data-en]` 의 텍스트만 바꿔 끼운다.
# 한국어 모드는 원문 그대로(속성만 늘어난다). 사전은 _data/i18n.yml 의 body: 그룹 (+ headings·columns·tags).
#
# 점검: python scripts/body_i18n_audit.py — 빌드 결과에서 data-en 이 안 붙은 구조 문구를 빈도순으로 보여준다.

require 'nokogiri'

module BodyI18n
  SKIP_ANCESTORS = %w[a code pre script style iframe kbd textarea].freeze
  HEADING_TAGS   = %w[h1 h2 h3 h4].freeze

  module_function

  # 사전·정규식은 노트마다 다시 만들지 않는다 (738번 → 1번). --watch 재생성 때는 :site, :after_reset 이 지운다
  def build(site)
    @dict_cache ||= {}
    @dict_cache[site.object_id] ||= build_dict(site)
  end

  def reset_cache!
    @dict_cache = {}
  end

  def build_dict(site)
    i18n = site.data['i18n'] || {}
    body = i18n['body'] || {}
    d = {
      headings: (i18n['headings'] || {}).merge(body['headings'] || {}),
      links:     body['links'] || {},
      names:     body['names'] || {},
      platforms: body['platforms'] || {},
      units:     body['units'] || {},
      tokens:    body['tokens'] || {},
      phrases:   body['phrases'] || {},
      sources:   body['sources'] || {},
      routes:    body['routes'] || {},
      columns:   i18n['columns'] || {},
      tags:      i18n['tags'] || {}
    }
    d[:norm] = {}
    d[:headings].merge(d[:tags]).each { |k, v| d[:norm][k.to_s.gsub(/[\s_]/, '')] = v }
    d[:rules] = text_rules(d)
    d
  end

  def alt(keys)
    keys.map(&:to_s).reject(&:empty?).sort_by { |k| -k.length }.map { |k| Regexp.escape(k) }.join('|')
  end

  # 텍스트 노드 안에서 찾는 규칙 — [정규식, 치환 람다(MatchData → 영어 or nil)]
  def text_rules(d)
    rules = []
    names, plats, units, tokens, sources = d[:names], d[:platforms], d[:units], d[:tokens], d[:sources]

    # 'YYMMDD 허윤진 인스타' / 'YYMMDD_즈하 인스타' / '(230518 허윤진)'
    unless names.empty?
      name_alt = alt(names.keys)
      plat_alt = alt(plats.keys)
      re = plats.empty? ?
        /(?<!\d)(\d{6})[ _](#{name_alt})(?![가-힣A-Za-z0-9])/ :
        /(?<!\d)(\d{6})[ _](?:(#{name_alt})(?:[ ](#{plat_alt}))?|(#{plat_alt}))(?![가-힣A-Za-z0-9])/
      rules << [re, lambda { |m|
        iso = "20#{m[1][0, 2]}-#{m[1][2, 2]}-#{m[1][4, 2]}"   # YYMMDD 는 한국식 표기라 영어에서는 ISO 로
        if m[2]
          s = "#{iso} #{names[m[2]]}"
          s += " #{plats[m[3]]}" if m[3]
          s
        else
          "#{iso} #{plats[m[4]]}"
        end
      }]
    end

    # '※ 폐업함 (네이버·카카오 2026-09 확인)' — 출처를 전부 아는 경우만 통째로
    unless sources.empty?
      src_alt = alt(sources.keys)
      re = /※ 폐업함 \(((?:#{src_alt})(?:\s*[·,\/]\s*(?:#{src_alt}))*) (\d{4}-\d{2}) 확인\)/
      rules << [re, lambda { |m|
        parts = m[1].split(/\s*[·,\/]\s*/).map { |p| sources[p] }
        next nil if parts.any?(&:nil?)
        "※ Permanently closed (confirmed on #{parts.join(' · ')}, #{m[2]})"
      }]
    end

    # '(전원)' · '(꾸라·채원)' · '(진즈하)'
    unless units.empty?
      unit_alt = alt(units.keys)
      re = /\(((?:#{unit_alt})(?:\s*[·,\/&]\s*(?:#{unit_alt}))*)\)/
      rules << [re, lambda { |m|
        parts = m[1].split(/\s*[·,\/&]\s*/).map { |p| units[p] }
        next nil if parts.any?(&:nil?)
        "(#{parts.join(' · ')})"
      }]
    end

    # 고정 문구 ('영상:' · '원본 게시물 삭제됨' · '※ 폐업함' …)
    unless tokens.empty?
      tok_alt = alt(tokens.keys)
      rules << [/(?:#{tok_alt})/, lambda { |m| tokens[m[0]] }]
    end

    # 반복 문구·이름 — 한글 경계 안에서만 ('르세라핌이' 처럼 조사가 붙으면 그대로 둔다)
    phrases = d[:phrases].merge(d[:names])
    unless phrases.empty?
      ph_alt = alt(phrases.keys)
      rules << [/(?<![가-힣])(?:#{ph_alt})(?![가-힣0-9])/, lambda { |m| phrases[m[0]] }]
    end

    # 소요 시간 · 요일 · N곳
    rules << [/도보 약 (\d+)\s*[–~-]\s*(\d+)분/, lambda { |m| "about #{m[1]}–#{m[2]} min on foot" }]
    rules << [/도보 약 (\d+)분/, lambda { |m| "about #{m[1]} min on foot" }]
    rules << [/버스\/차량 약 (\d+)\s*[–~-]\s*(\d+)분/, lambda { |m| "about #{m[1]}–#{m[2]} min by bus or car" }]
    rules << [/차량 약 (\d+)\s*[–~-]\s*(\d+)분/, lambda { |m| "about #{m[1]}–#{m[2]} min by car" }]
    rules << [/공연일 셔틀 약 (\d+)분/, lambda { |m| "show-day shuttle, about #{m[1]} min" }]
    # 요일 범위·나열 + 영업시간: '월~금 11:00 ~ 19:00' · '(금·토 ~20:00)'
    rules << [/(?<![가-힣])([월화수목금토일])~([월화수목금토일])(?![가-힣])/, lambda { |m| "#{WEEKDAY[m[1]]}–#{WEEKDAY[m[2]]}" }]
    rules << [/(?<![가-힣])([월화수목금토일](?:·[월화수목금토일])+)(?![가-힣])(\s*~\s*(\d{1,2}:\d{2}))?/, lambda { |m|
      days = m[1].split('·').map { |x| WEEKDAY[x] }
      list = days.length == 2 ? days.join(' & ') : days[0..-2].join(', ') + ' & ' + days[-1]
      m[3] ? "#{list} until #{m[3]}" : list
    }]
    rules << [/도보 (\d+)\s*[–~-]\s*(\d+)분/, lambda { |m| "#{m[1]}–#{m[2]} min on foot" }]
    rules << [/도보 (\d+)분/, lambda { |m| "#{m[1]} min on foot" }]
    rules << [/차량 약 (\d+)분/, lambda { |m| "about #{m[1]} min by car" }]
    rules << [/\((월|화|수|목|금|토|일)\)/, lambda { |m| "(#{WEEKDAY[m[1]]})" }]
    rules << [/(?<![가-힣])(\d+)곳(?![가-힣])/, lambda { |m| "#{m[1]} places" }]
    rules << [/\((\d[\d,]*)명\)/, lambda { |m| "(#{m[1]} people)" }]                       # (3명) — 괄호째일 때만
    rules << [/(?<![가-힣\d])(\d+)\s*[–~-]\s*(\d+)분(?![가-힣])/, lambda { |m| "#{m[1]}–#{m[2]} min" }]   # (45–50분)
    rules << [/(?<![가-힣])약 (\d+)분(?![가-힣])/, lambda { |m| "about #{m[1]} min" }]
    # 메모 줄 맨 앞의 날짜만 있는 경우('260305 뮤직뱅크 사전녹화') — 연·월·일이 맞는 6자리만 ISO 로
    rules << [/(?<![\d-])(2[0-9])(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])(?=[ _][^\d])/, lambda { |m| "20#{m[1]}-#{m[2]}-#{m[3]}" }]
    rules << [/1일 (\d+)명/, lambda { |m| "#{m[1]} people per day" }]
    rules << [/매일\s*(\d+)명/, lambda { |m| "#{m[1]} people daily" }]
    rules << [/(\d+)일선착/, lambda { |m| "day #{m[1]}, first come first served" }]
    rules << [/(\d+)번 출구/, lambda { |m| "Exit #{m[1]}" }]
    rules << [/(?<![\d.])(\d+)미터(?![가-힣])/, lambda { |m| "#{m[1]} m" }]
    rules << [/제(\d+)전시관/, lambda { |m| "Hall #{m[1]}" }]
    rules << [/랜덤\s*(\d+)중\s*(\d+)/, lambda { |m| "random #{m[2]} of #{m[1]}" }]        # 랜덤3중1
    rules << [/오르막 도보 (\d+)\s*[–~-]\s*(\d+)분/, lambda { |m| "#{m[1]}–#{m[2]} min uphill on foot" }]
    rules << [/(?<![가-힣])(\d+)차(?![가-힣])/, lambda { |m| "round #{m[1]}" }]          # LUCKY DRAW 1차
    rules << [/(\d{1,2}\/\d{1,2}) 휴무/, lambda { |m| "closed #{m[1]}" }]
    rules << [/~\s*(\d{1,2}\/\d{1,2}) 구매건/, lambda { |m| "purchases through #{m[1]}" }]
    rules << [/(\d{1,2}\/\d{1,2})\s*~\s*(\d{1,2}\/\d{1,2}) 구매건/, lambda { |m| "purchases #{m[1]}–#{m[2]}" }]
    rules << [/(\d{1,2}\/\d{1,2}) (월|화|수|목|금|토|일) (\d{1,2}:\d{2})/, lambda { |m| "#{m[1]} (#{WEEKDAY[m[2]]}) #{m[3]}" }]
    rules
  end

  WEEKDAY = { '월' => 'Mon', '화' => 'Tue', '수' => 'Wed', '목' => 'Thu', '금' => 'Fri', '토' => 'Sat', '일' => 'Sun' }.freeze

  # 문자열 전체가 규칙으로 덮이면 영어 전체를, 아니면 nil
  def translate_whole(text, d)
    s = text.to_s.strip
    return nil if s.empty?
    spans = spans_for(s, d[:rules])
    return nil if spans.empty?
    out = +''
    pos = 0
    spans.each do |st, en, tr|
      gap = s[pos...st]
      return nil if gap =~ /[가-힣]/
      out << gap << tr
      pos = en
    end
    tail = s[pos..]
    return nil if tail =~ /[가-힣]/
    out << tail
  end

  # 링크 라벨: 사전 직접 일치 → '위버스 포스트1' 처럼 숫자 접미 → 앞의 이모지·기호를 떼고 다시
  def translate_link(text, d)
    t = text.to_s.strip
    return nil if t.empty?
    links = d[:links]
    return links[t] if links[t]
    if (m = t.match(/\A(.+?)\s*(\d+)\z/)) && links[m[1]]
      return "#{links[m[1]]} #{m[2]}"
    end
    if (m = t.match(/\A([^가-힣A-Za-z0-9]+)\s*(.+)\z/))
      inner = translate_link(m[2], d)
      return "#{m[1]}#{m[1] =~ /\s\z/ ? '' : ' '}#{inner}" if inner
    end
    # 허브의 태그 이름 링크 '2025년_윤진 생일카페(네이버지도)' — 소제목 규칙(태그·정규화·괄호)으로
    th = translate_heading(t, d)
    return th if th && th !~ /[가-힣]/
    nil
  end

  def translate_heading(text, d)
    t = text.to_s.strip
    return d[:headings][t] if d[:headings][t]
    return d[:tags][t] if d[:tags][t]          # 허브의 태그 이름 소제목 ('2025년_사쿠라_생일카페')
    # 밑줄·공백 차이만 나는 변형 ('2025년 윤진 생일광고' · kramdown 이 _…_ 를 em 으로 만든 것)
    n = d[:norm][t.gsub(/[\s_]/, '')]
    return n if n
    # 공연장 노트의 약도 소제목: '🚶 약도 — Bercy역 → Accor Arena (도보 1–2분)' · '🚋 약도 — Mandalay Bay 트램역 → 아레나 (리조트 내부)'
    #   · '🚶 약도 — 올림픽공원역 → 올림픽홀 (도보 약 8분)' · '… Church Street역(SunRail) → Kia Center (…)' · '… Tacoma Dome Station → …'
    if (m = t.match(/\A(\S+) 약도 — (.+?) → (.+?)\s*\(\s*(.+?)\s*\)\z/))
      inner = translate_whole(m[4], d)
      from = route_from(m[2].strip, d)
      dest = route_name(m[3].strip, d)
      return "#{m[1]} Route — #{from} → #{dest} (#{inner})" if inner && from && dest
    end
    if (m = t.match(/\A(.+?)\s*\((.+)\)\z/))
      base = d[:headings][m[1]] || d[:tags][m[1]] || d[:norm][m[1].gsub(/[\s_]/, '')]
      if base
        inner = translate_whole(m[2], d)
        inner = inner.sub(/\A(\d+) places\z/, '\1') if inner   # '참여 매장 (4곳)' → '(4)'
        return "#{base} (#{inner})" if inner
      end
    end
    translate_whole(t, d)
  end

  # 약도 소제목의 역·정류장: 'X역' · 'X역(SunRail)' · 'X 트램역' · 'X 모노레일역' · 'X 정류장' · 'DFW 공항' · 이미 영어인 'X Station'
  def route_from(text, d)
    suffix = ''
    if (m = text.match(/\A(.+?)\s*\(([^()]+)\)\z/))
      text = m[1]
      s = route_name(m[2].strip, d)
      return nil unless s
      suffix = " (#{s})"
    end
    base, stop =
      if (m = text.match(/\A(.+?)\s*트램역\z/)) then [m[1], 'tram stop']
      elsif (m = text.match(/\A(.+?)\s*모노레일역\z/)) then [m[1], 'monorail station']
      elsif (m = text.match(/\A(.+?)역\z/)) then [m[1], 'Station']
      elsif (m = text.match(/\A(.+?)\s*정류장\z/)) then [m[1], 'stop']
      else [text, nil]
      end
    name = route_name(base.strip, d)
    return nil unless name
    stop ? "#{name} #{stop}#{suffix}" : "#{name}#{suffix}"
  end

  # 약도 소제목의 이름 조각: routes 사전 → 본문 규칙으로 전부 덮이면 그것 → 한글이 없으면 그대로
  def route_name(text, d)
    return d[:routes][text] if d[:routes][text]
    tr = translate_whole(text, d)
    return tr if tr && tr !~ /[가-힣]/
    text =~ /[가-힣]/ ? nil : text
  end

  def spans_for(text, rules)
    found = []
    rules.each do |re, fn|
      text.scan(re) do
        m = Regexp.last_match
        tr = fn.call(m)
        found << [m.begin(0), m.end(0), tr] if tr
      end
    end
    found.sort_by! { |st, en, _| [st, -(en - st)] }
    out = []
    last = 0
    found.each do |st, en, tr|
      next if st < last
      out << [st, en, tr]
      last = en
    end
    out
  end

  ADDRESS_HEADINGS = %w[위치 주소 상호명].freeze

  # '## 위치'·'## 주소'·'## 상호명' 아래 문단(주소·가게 이름)은 원문을 지켜야 하므로 규칙을 태우지 않는다
  def address_zone_nodes(frag)
    zone = {}
    skipping = false
    frag.children.each do |el|
      next unless el.element?
      if HEADING_TAGS.include?(el.name)
        skipping = ADDRESS_HEADINGS.include?(el.text.strip)
        next
      end
      zone[el] = true if skipping
    end
    zone
  end

  def wrap_text_nodes(frag, d)
    rules = d[:rules]
    return if rules.empty?
    zone = address_zone_nodes(frag)
    frag.xpath('.//text()').to_a.each do |node|
      next if node.ancestors.any? { |a| SKIP_ANCESTORS.include?(a.name) || a['data-en'] }
      s = node.content
      next unless s =~ /[가-힣※]/
      if node.ancestors.any? { |a| zone[a] }
        # 주소 구역에서는 주소 자체를 건드리지 않는다. 다만 한 줄이 통째로 괄호 설명('(사옥 뒤편 카페골목)')이고
        # 그 안이 규칙으로 전부 덮이면 그 줄만 바꾼다
        spans = []
        whole = translate_whole(s, d)                        # '※ 폐업함 (네이버 2026-09 확인)' 처럼 텍스트 전체가 규칙으로 덮이면 그대로
        if whole
          st = s.index(/\S/); en = s.rindex(/\S/) + 1
          spans << [st, en, whole]
        else
          s.scan(/^[ \t]*\((.+?)\)[ \t]*$/) do
            m = Regexp.last_match
            tr = translate_whole(m[1], d)
            spans << [m.begin(1), m.end(1), tr] if tr
          end
        end
      else
        spans = spans_for(s, rules)
      end
      next if spans.empty?
      doc = node.document
      pos = 0
      pieces = []
      spans.each do |st, en, tr|
        pieces << Nokogiri::XML::Text.new(s[pos...st], doc) if st > pos
        span = Nokogiri::XML::Node.new('span', doc)
        span['data-en'] = tr
        span.content = s[st...en]
        pieces << span
        pos = en
      end
      pieces << Nokogiri::XML::Text.new(s[pos..], doc) if pos < s.length
      pieces.each { |p| node.add_previous_sibling(p) }
      node.remove
    end
  end

  def transform(html, d)
    return html if html.nil? || html.empty? || html !~ /[가-힣※]/
    frag = Nokogiri::HTML::DocumentFragment.parse(html)

    # 1) 소제목 — 글자만 있는 것은 사전 일치, 링크 하나만 든 것은 링크 라벨 규칙
    frag.css(HEADING_TAGS.join(',')).each do |h|
      kids = h.element_children
      next unless kids.empty? || kids.all? { |k| %w[em strong span].include?(k.name) }
      tr = translate_heading(h.text, d)
      h['data-en'] = tr if tr
    end

    # 2) 링크 라벨 (소제목 안팎 모두)
    frag.css('a').each do |a|
      next unless a.element_children.empty?
      tr = translate_link(a.text, d)
      a['data-en'] = tr if tr
    end

    # 3) 표 머리글 (허브 표는 collection-table.html 이 따로 하지만 같은 값이라 무방)
    frag.css('th').each do |th|
      next unless th.element_children.empty?
      tr = d[:columns][th.text.strip]
      th['data-en'] = tr if tr
    end

    # 4) 한 단어짜리 카테고리 줄 ('카페' · '음식점' …) — 태그 사전과 정확히 일치할 때만
    frag.css('p').each do |p|
      next unless p.element_children.empty?
      tr = d[:tags][p.text.strip]
      p['data-en'] = tr if tr
    end

    # 5) 텍스트 조각 — 메모 줄 토큰·(전원)·※ 폐업함 …
    wrap_text_nodes(frag, d)

    frag.to_html
  end
end

Jekyll::Hooks.register :site, :after_reset do |_site|
  BodyI18n.reset_cache!
end

Jekyll::Hooks.register [:notes], :post_convert do |doc|
  d = BodyI18n.build(doc.site)
  doc.content = BodyI18n.transform(doc.content, d)
end
