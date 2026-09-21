# frozen_string_literal: true
#
# 모음(허브) 페이지의 영어판 (2026-09-21, 사용자 지시 "허브 표는 병기가 아니라 영어 페이지 따로 제공")
#
# hide_backlinks: true 인 노트마다 /en/<slug> 페이지를 하나 더 만든다. 원본 노트는 손대지 않는다.
#   - 제목 = title_en (없으면 원제), 설명 = intro_en
#   - 표: 머리글은 columns 사전, 셀은 열 이름에 따라 — 위치/도시 → 지역 사전(regions·tags, "서울시 용산구"→"Yongsan, Seoul"),
#     멤버 → units 사전, SNS/콘텐츠/카테고리 → platforms·tags·cells 사전, 장소 링크 → 노트의 name_en(places_en.rb) 또는 원제
#   - 소제목 → headings 사전, 나머지 줄은 body_i18n 의 텍스트 규칙(구문·이름·날짜)으로 부분 치환
#   - 손으로 쓴 영어 원고가 _hubs_en/<원본 파일명>.md 에 있으면 자동 번역 대신 그 본문을 쓴다 (프로즈가 많은 이벤트 모음용)
# 라우팅: 원본 노트에 en_url, 영어판에 ko_url 을 넣고 note.html 이 언어 설정에 따라 서로 넘겨준다.
# 영어판은 Page 라 places.json·검색 색인·백링크·그래프에는 안 들어간다 (sitemap 에는 들어간다).

require 'nokogiri'

module HubEnPages
  HANGUL = /[가-힣]/

  module_function

  def i18n(site)
    site.data['i18n'] || {}
  end

  def dict(site, *groups)
    d = {}
    groups.each do |g|
      src = g.start_with?('body.') ? ((i18n(site)['body'] || {})[g.sub('body.', '')] || {}) : (i18n(site)[g] || {})
      d.merge!(src)
    end
    d
  end

  # "서울시 용산구" → "Yongsan, Seoul" / "🇰🇷 인천" → "🇰🇷 Incheon" / "🇵🇭 마닐라 (파사이)" → "🇵🇭 Manila (Pasay)"
  def region_cell(site, s)
    regions = dict(site, 'regions', 'tags', 'countries')
    countries = dict(site, 'countries')
    wide = %w[서울 부산 대구 인천 광주 대전 울산 세종 경기 강원 충북 충남 전북 전남 경북 경남 제주]
    toks = s.strip.split(/\s+/)
    out = []
    kinds = []
    toks.each do |tok|
      if tok =~ /\A[^\p{Hangul}\p{Latin}\d]+\z/   # 국기 이모지 등
        out << tok; kinds << :emoji; next
      end
      paren = tok.match(/\A\((.+)\)\z/)
      core = paren ? paren[1] : tok
      tr = regions[core]
      base = core.sub(/(특별시|광역시|특별자치도|특별자치시|시|구|군|도)\z/, '')
      tr ||= regions[base] if base != core && !base.empty?
      tr ||= core
      w = wide.include?(base) || wide.include?(core) || countries.key?(core)
      out << (paren ? "(#{tr})" : tr)
      kinds << (w ? :wide : :local)
    end
    # "서울시 용산구" → "Yongsan, Seoul" · "미국 캘리포니아" → "California, USA" 처럼 큰 지역 + 작은 지역이면 순서를 뒤집는다
    if kinds.size == 2 && kinds[0] == :wide && kinds[1] == :local
      return "#{out[1]}, #{out[0]}"
    end
    if kinds.size == 3 && kinds[0] == :emoji && kinds[1] == :wide && kinds[2] == :local
      return "#{out[0]} #{out[2]}, #{out[1]}"
    end
    out.join(' ')
  end

  # "윤진/은채" → "YUNJIN / EUNCHAE", "전원" → "All"
  def member_cell(site, s)
    units = dict(site, 'body.units', 'body.names')
    parts = s.split(/\s*[\/,·+&]\s*/)
    tr = parts.map { |p| p == '전원' ? 'All' : (units[p] || p) }
    tr.join(' / ')
  end

  # 남은 셀: 정확 일치 사전 → 부분 규칙
  def generic_cell(site, s, rules)
    exact = dict(site, 'columns', 'tags', 'body.platforms', 'body.links', 'cells')
    # 태그 사전의 '은채의_취미일기' 는 셀에서 '은채의 취미일기' 로 쓰인다 → 밑줄을 공백으로 바꾼 키도 본다
    exact.keys.each { |k| exact[k.to_s.tr('_', ' ')] ||= exact[k] if k.to_s.include?('_') }
    t = s.strip
    return exact[t] if exact[t]
    parts = t.split(%r{\s*/\s*})
    if parts.size > 1 && parts.all? { |p| exact[p] }
      return parts.map { |p| exact[p] }.join(' / ')
    end
    partial(t, rules, exact)
  end

  # body_i18n 규칙 + 셀 사전으로 부분 치환 (한글이 남아도 그대로 둔다)
  def ordinal(n)
    n = n.to_i
    suf = (n % 100).between?(11, 13) ? 'th' : { 1 => 'st', 2 => 'nd', 3 => 'rd' }.fetch(n % 10, 'th')
    "#{n}#{suf}"
  end

  def partial(text, rules, exact = {})
    s = text.dup
    s = s.gsub(/역조공\s*\((\d{6})\)/) { "Gift from the members (#{Regexp.last_match(1)})" }
    s = s.gsub(/\(폐업\)/, '(closed)').gsub(/\(종료\)/, '(ended)')
    s = s.gsub(/제(\d+)회\s*/) { ordinal(Regexp.last_match(1)) + ' ' }      # 제40회 → 40th
    s = s.gsub(/시즌\s*(\d+)/) { "Season #{Regexp.last_match(1)}" }
    s = s.gsub(/미니\s*(\d+)집/) { "#{ordinal(Regexp.last_match(1))} mini album" }   # 미니 3집 'EASY'
    s = s.gsub(/정규\s*(\d+)집/) { "#{ordinal(Regexp.last_match(1))} full album" }
    s = s.gsub(/ㅣ/, ' | ')                                                # 제목 구분자로 쓰인 한글 ㅣ
    spans = BodyI18n.spans_for(s, rules)
    unless spans.empty?
      out = +''
      pos = 0
      spans.each do |st, en, tr|
        out << s[pos...st] << tr
        pos = en
      end
      out << s[pos..]
      s = out
    end
    # 셀 사전의 단어를 경계 안에서 치환 (예: '유튜브·예능' 의 '예능')
    exact.each do |k, v|
      next if k.to_s !~ HANGUL || v.to_s.empty?
      s = s.gsub(/(?<![가-힣])#{Regexp.escape(k)}(?![가-힣])/, v.to_s)
    end
    s
  end

  # 내부 링크 라벨을 영어 이름으로 (bidirectional_links 가 이미 <a class='internal-link'> 로 바꿔 둔 상태)
  def relabel_links(site, text, by_url)
    text.gsub(%r{<a class=['"]internal-link['"] href=['"]([^'"]+)['"]>(.*?)</a>}) do
      href, label = Regexp.last_match(1), Regexp.last_match(2)
      note = by_url[href.sub(/\A#{Regexp.escape(site.baseurl.to_s)}/, '')]
      if note
        en = note.data['name_en'].to_s
        en = note.data['title_en'].to_s if en.empty? && note.data['hide_backlinks']
        en = label if en.empty?
        target = note.data['hide_backlinks'] && note.data['en_url'] ? "#{site.baseurl}#{note.data['en_url']}" : href
        "<a class='internal-link' href='#{target}'>#{en}</a>"
      else
        "<a class='internal-link' href='#{href}'>#{label}</a>"
      end
    end
  end

  # 손으로 쓴 영어 원고(_hubs_en)의 [[위키링크]] — bidirectional_links 는 이미 지나갔으므로 직접 바꾼다
  def convert_wikilinks(site, text, by_title)
    text.gsub(/\[\[([^\]|]+)(?:\|([^\]]+))?\]\]/) do
      title, label = Regexp.last_match(1).strip, Regexp.last_match(2)
      note = by_title[title]
      if note
        en = label || (note.data['name_en'].to_s.empty? ? nil : note.data['name_en']) || (note.data['hide_backlinks'] ? note.data['title_en'] : nil) || title
        href = note.data['hide_backlinks'] && note.data['en_url'] ? "#{site.baseurl}#{note.data['en_url']}" : "#{site.baseurl}#{note.url}"
        "<a class='internal-link' href='#{href}'>#{en}</a>"
      else
        label || title
      end
    end
  end

  def split_row(line)
    # '\|' 이스케이프를 보호하고 셀로 나눈다
    line.strip.sub(/\A\|/, '').sub(/\|\z/, '').gsub('\\|', "\u0001").split('|').map { |c| c.gsub("\u0001", '\\|').strip }
  end

  def translate_table(site, lines, rules, by_url)
    header = split_row(lines[0])
    columns = dict(site, 'columns')
    header_en = header.map { |h| columns[h] || h }
    out = ['| ' + header_en.join(' | ') + ' |', lines[1]]
    lines[2..].each do |l|
      cells = split_row(l)
      tr = cells.each_with_index.map do |c, i|
        h = header[i].to_s
        c2 = relabel_links(site, c, by_url)
        if c2.include?('internal-link')
          c2
        elsif %w[위치 도시 장소].include?(h) && c2 !~ /<a /
          h == '장소' ? generic_cell(site, c2, rules) : region_cell(site, c2)
        elsif h == '멤버'
          member_cell(site, c2)
        elsif h == '날짜'
          c2
        else
          generic_cell(site, c2, rules)
        end
      end
      out << '| ' + tr.join(' | ') + ' |'
    end
    out
  end

  def translate_heading(site, text, d)
    t = text.strip
    return t if t !~ HANGUL
    if (m = t.match(/\A\[([^\]]+)\]\(([^)]+)\)\z/))   # [🅽네이버지도](url)
      lab = BodyI18n.translate_link(m[1], d)
      return lab ? "[#{lab}](#{m[2]})" : t
    end
    BodyI18n.translate_heading(t, d) || HubEnPages.partial(t, d[:rules], dict(site, 'tags', 'cells', 'regions'))
  end

  def translate_content(site, note, by_url)
    d = BodyI18n.build(site)
    src = note.content.to_s
    lines = src.split("\n", -1)
    out = []
    i = 0
    intro_done = false
    while i < lines.size
      l = lines[i]
      if l.start_with?('|') && i + 1 < lines.size && lines[i + 1] =~ /\A\|?\s*:?-{2,}/
        j = i
        j += 1 while j < lines.size && lines[j].start_with?('|')
        out.concat(translate_table(site, lines[i...j], d[:rules], by_url))
        i = j
        next
      end
      if (m = l.match(/\A(\#{1,6})\s+(.*)\z/))
        out << "#{m[1]} #{translate_heading(site, relabel_links(site, m[2], by_url), d)}"
      elsif l.strip == '{: .hub-intro}' && note.data['intro_en'] && !intro_done
        # 바로 앞 문단(한국어 설명, 여러 줄일 수 있음)을 영어 설명 한 줄로 바꾼다
        k = out.size - 1
        k -= 1 while k >= 0 && out[k].strip.empty?
        j = k
        j -= 1 while j > 0 && !out[j - 1].strip.empty? && !out[j - 1].start_with?('<', '#')
        if k >= 0
          out.slice!(j..k)
          out << note.data['intro_en'].to_s
        end
        out << l
        intro_done = true
      elsif l.start_with?('<') || l.strip.empty?
        out << relabel_links(site, l, by_url)
      else
        out << partial(relabel_links(site, l, by_url), d[:rules])
      end
      i += 1
    end
    out.join("\n")
  end

  class Generator < Jekyll::Generator
    safe true
    priority :lowest   # places_en(:normal, name_en)·bidirectional_links(:normal, [[링크]]→<a>) 뒤

    def generate(site)
      notes = site.collections['notes'].docs
      hubs = notes.select { |n| n.data['hide_backlinks'] }
      return if hubs.empty?
      by_url = {}
      by_title = {}
      notes.each { |n| by_url[n.url] = n; by_title[n.data['title'].to_s] = n; by_title[File.basename(n.path, '.md')] = n }
      # 1) 먼저 en_url 을 전부 정해 둔다 (허브끼리 서로 링크할 때 필요)
      #    슬러그는 title_en 에서 ASCII 로 만든다 (/en/sns-places). 없거나 ASCII 가 안 나오면 원본 url 그대로 (/en/<원본 슬러그>)
      used = {}
      hubs.each do |h|
        te = h.data['title_en'].to_s.strip
        slug = te.empty? ? '' : Jekyll::Utils.slugify(te, mode: 'default')   # 빈 문자열을 slugify 하면 'Empty slug' 경고가 뜬다
        slug = '' unless slug =~ /\A[a-z0-9-]+\z/ && !used[slug]
        h.data['en_url'] = slug.empty? ? "/en#{h.url}" : "/en/#{slug}"
        used[slug] = true unless slug.empty?
      end
      n = 0
      hubs.each do |note|
        manual = File.join(site.source, '_hubs_en', File.basename(note.path))
        content = if File.exist?(manual)
                    HubEnPages.convert_wikilinks(site, File.read(manual, encoding: 'utf-8').sub(/\A---.*?---\s*/m, ''), by_title)
                  else
                    HubEnPages.translate_content(site, note, by_url)
                  end
        page = Jekyll::PageWithoutAFile.new(site, site.source, 'en', "#{File.basename(note.path, '.md')}.md")
        page.content = content
        page.data.merge!(
          'layout' => 'note',
          'title' => (note.data['title_en'].to_s.empty? ? note.data['title'] : note.data['title_en']),
          'ko_title' => note.data['title'],
          'permalink' => note.data['en_url'],
          'ko_url' => note.url,
          'hide_backlinks' => true,
          'hub_en' => true,
          'lang' => 'en',
          'tags' => note.data['tags'],
          'description' => (note.data['intro_en'] || "#{note.data['title_en'] || note.data['title']} — LE SSERAFIM places (English)"),
          'sitemap' => true
        )
        page.data['manual_en'] = true if File.exist?(manual)
        %w[last_modified_at last_modified_at_timestamp created_at].each { |k| page.data[k] = note.data[k] if note.data[k] }
        site.pages << page
        n += 1
      end
      Jekyll.logger.info('HubEnPages', "영어판 허브 #{n}개 (/en/…)")
    end
  end
end

module HubEnPages
  # Liquid 가 만든 HTML 표(SNS 허브의 '해외' 표 등)는 마크다운 단계에서 못 보므로 변환 뒤 HTML 에서 한 번 더 번역한다
  def self.translate_html(site, html)
    return html if html.nil? || html.empty? || html !~ HANGUL
    d = BodyI18n.build(site)
    columns = dict(site, 'columns')
    by_url = {}
    site.collections['notes'].docs.each { |n| by_url[n.url] = n }
    frag = Nokogiri::HTML::DocumentFragment.parse(html)
    frag.css('table').each do |table|
      ths = table.css('thead th')
      next if ths.empty?
      headers = ths.map { |th| th.text.strip }
      ths.each { |th| th.content = columns[th.text.strip] if columns[th.text.strip] && th.element_children.empty? }
      table.css('tbody tr').each do |tr|
        tr.css('td').each_with_index do |td, i|
          h = headers[i].to_s
          td.css('a').each do |a|
            note = by_url[a['href'].to_s.sub(/\A#{Regexp.escape(site.baseurl.to_s)}/, '')]
            next unless note
            en = note.data['name_en'].to_s
            en = note.data['title_en'].to_s if en.empty? && note.data['hide_backlinks']
            a.content = en unless en.empty?
            a['href'] = "#{site.baseurl}#{note.data['en_url']}" if note.data['hide_backlinks'] && note.data['en_url']
          end
          next unless td.element_children.empty?
          txt = td.text.strip
          next if txt.empty? || txt !~ HANGUL
          td.content = case h
                       when '위치', '도시', 'Area', 'City' then region_cell(site, txt)
                       when '멤버', 'Members' then member_cell(site, txt)
                       when '날짜', 'Date' then txt
                       else generic_cell(site, txt, d[:rules])
                       end
        end
      end
    end
    frag.to_html
  end
end

# 영어판 본문: Liquid 표 번역 → body_i18n 의 data-en(링크 라벨·남은 토큰) — 영어 모드라 바로 바뀐다
Jekyll::Hooks.register [:pages], :post_convert do |page|
  next unless page.data['hub_en']
  # /en/ 아래에 있으므로 노트식 상대 경로(assets/…)는 /en/assets/… 로 깨진다 → 루트 기준으로
  base = page.site.baseurl.to_s
  page.content = page.content.gsub(/(src|href|poster)=(["'])assets\//) { "#{Regexp.last_match(1)}=#{Regexp.last_match(2)}#{base}/assets/" }
  page.content = HubEnPages.translate_html(page.site, page.content)
  d = BodyI18n.build(page.site)
  page.content = BodyI18n.transform(page.content, d)
end
