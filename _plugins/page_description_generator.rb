# frozen_string_literal: true
#
# 페이지별 meta description / og:description 자동 생성 (2026-09-19)
#
# 노트에 front matter `description:` 이 없으면 빌드 때 채운다. 예전엔 page.excerpt 가 비어
# (본문 첫 문단이 iframe) 장소 페이지의 description·og:description 이 전부 빈 문자열로 나갔다.
#
#   장소 노트: "허윤진 관련 전시회, 서울 종로구 국제갤러리의 위치와 관련 게시물을 확인하세요. 출처: 260831 윤진 인스타"
#   모음 페이지(hide_backlinks): "'SNS 장소' — 르세라핌 관련 장소 모음. 위치와 관련 게시물을 확인하세요."
#   태그/멤버 인덱스: "'카페' 태그가 붙은 르세라핌 관련 장소 132곳" / "허윤진 관련 장소 210곳 …"
#
# 재료는 다른 생성기가 이미 넣어 둔 값을 쓴다 — members(member_extractor), 주소(PlacesGenerator.extract_address),
# 태그 섹션(_data/tag_categories.yml). 그래서 priority :lowest 로 맨 마지막에 돈다.
# 노트가 직접 `description:` 을 주면 그대로 둔다 (head.html 의 우선순위와 같음).

module PageDescription
  KR_PREFIX_NORMALIZE = {
    '서울특별시' => '서울', '부산광역시' => '부산', '대구광역시' => '대구', '인천광역시' => '인천',
    '광주광역시' => '광주', '대전광역시' => '대전', '울산광역시' => '울산', '세종특별자치시' => '세종',
    '경기도' => '경기', '강원특별자치도' => '강원', '강원도' => '강원', '충청북도' => '충북', '충청남도' => '충남',
    '전북특별자치도' => '전북', '전라북도' => '전북', '전라남도' => '전남', '경상북도' => '경북', '경상남도' => '경남',
    '제주특별자치도' => '제주', '제주도' => '제주'
  }.freeze
  KR_REGIONS = %w[서울 부산 대구 인천 광주 대전 울산 세종 경기 강원 충북 충남 전북 전남 경북 경남 제주].freeze

  CATEGORY_NOUN = {
    '카페' => '카페', '음식점' => '음식점', '숙박시설' => '숙소', '상점' => '상점', '쇼핑' => '쇼핑 장소',
    '액티비티' => '액티비티 장소', '전시회' => '전시', '팝업스토어' => '팝업스토어', '관광지' => '관광지',
    '공연장' => '공연장', '기타장소' => '장소'
  }.freeze

  MEMBER_ORDER = %w[사쿠라 김채원 허윤진 카즈하 홍은채].freeze

  module_function

  def section(site, name)
    tc = site.data['tag_categories'] || {}
    Array(tc[name]).map(&:to_s)
  end

  def members_phrase(note)
    ms = Array(note.data['members']).map(&:to_s).uniq
    return '르세라핌' if ms.empty? || ms.size >= 5
    MEMBER_ORDER.select { |m| ms.include?(m) }.concat(ms - MEMBER_ORDER).join('·')
  end

  def category_noun(site, tags)
    types = section(site, '장소 유형')
    cat = tags.find { |t| types.include?(t) }
    cat ? (CATEGORY_NOUN[cat] || cat) : '장소'
  end

  # "서울 종로구" / "경기 가평군" / "일본 도쿄" / "미국 뉴욕" — 못 찾으면 ''
  def region_phrase(site, note, tags)
    country = note.data['country'].to_s.downcase
    country = 'kr' if country.empty?
    if country == 'kr'
      addr = PlacesGenerator.extract_address(note.content.to_s)
      unless addr.nil? || addr.empty?
        a = addr.dup
        KR_PREFIX_NORMALIZE.each { |long, short| a = a.sub(/\A\s*#{Regexp.escape(long)}/, short) }
        toks = a.split(/\s+/)
        if KR_REGIONS.include?(toks[0])
          return toks[1] && toks[1] =~ /(구|군|시)\z/ ? "#{toks[0]} #{toks[1]}" : toks[0]
        end
      end
      seoul = section(site, '서울 (구별)') + section(site, '서울(구별)')
      gu = tags.find { |t| seoul.include?(t) }
      return "서울 #{gu}" if gu
      wide = section(site, '광역 지역') + section(site, '경기')
      w = tags.find { |t| wide.include?(t) }
      return w.to_s
    end
    labels = section(site, '국가 (라벨)') + section(site, '국가(라벨)')
    cities = section(site, '일본 (지역)') + section(site, '일본(지역)') + section(site, '해외 (지역)') + section(site, '해외(지역)')
    label = tags.find { |t| labels.include?(t) }
    city  = tags.find { |t| cities.include?(t) && t != label }
    [label, city].compact.join(' ')
  end

  # 본문 첫 메모 줄: "260831 윤진 인스타" / "[LENIVERSE] EP.28 …"
  def source_line(note)
    body = note.content.to_s.gsub(/<!--.*?-->/m, '')
    body.each_line do |l|
      s = l.strip
      next if s.empty? || s.start_with?('<', '#', '|', '!', '```')
      next if s =~ /\A\[.*\]\(https?:/ # 링크 한 줄은 출처가 아님
      if s =~ /\A\d{6}[ _]/ || s.start_with?('[')
        s = s.gsub(/\[([^\]]+)\]\([^)]*\)/, '\1').gsub(/\*\*/, '')
        s = s.gsub('\|', '|')                        # 표 오인 방지 이스케이프(\|)는 설명문에서 뺀다
        s = s.split(' / ').first.to_s.strip           # 출처가 여럿이면 첫 번째만
        s = s.sub(/\A(\d{6})_/, '\1 ')                # "260831_윤진" → "260831 윤진"
        return s.length > 48 ? "#{s[0, 47]}…" : s
      end
      return nil
    end
    nil
  end

  def note_description(site, note)
    title = note.data['title'].to_s.strip
    tags  = Array(note.data['tags']).map(&:to_s)
    if note.data['hide_backlinks']
      return "'#{title}' — 르세라핌 관련 장소 모음. 위치와 관련 게시물을 확인하세요."
    end
    region = region_phrase(site, note, tags)
    place  = [region, title].reject { |x| x.nil? || x.empty? }.join(' ')
    desc = "#{members_phrase(note)} 관련 #{category_noun(site, tags)}, #{place}의 위치와 관련 게시물을 확인하세요."
    closed = note.data['closed']
    if closed && closed != false
      desc = desc.sub('확인하세요.', '확인하세요. (폐업)')
    elsif note.data['ended'] == true || (note.data['event_end'] && note.data['event_end'] < Date.today)
      desc = desc.sub('확인하세요.', '확인하세요. (종료된 이벤트)')
    end
    src = source_line(note)
    desc += " 출처: #{src}" if src && (desc.length + src.length) < 150
    desc
  end

  class Generator < Jekyll::Generator
    safe true
    priority :lowest

    def generate(site)
      return unless defined?(PlacesGenerator)
      n = 0
      site.collections['notes'].docs.each do |note|
        next if note.data['description'].to_s.strip != ''
        note.data['description'] = PageDescription.note_description(site, note)
        n += 1
      end
      site.pages.each do |pg|
        next if pg.data['description'].to_s.strip != ''
        kind = pg.data['kind']
        next unless kind
        term = pg.data['term'].to_s
        count = Array(pg.data['notes']).size
        pg.data['description'] =
          if kind == 'member'
            "#{term} 관련 장소 #{count}곳 — 카페·음식점·촬영지의 위치와 관련 게시물을 모았습니다."
          else
            "'#{term}' 태그가 붙은 르세라핌 관련 장소 #{count}곳의 위치와 관련 게시물을 확인하세요."
          end
        n += 1
      end
      Jekyll.logger.info('PageDescription', "description 자동 생성 #{n}건")
    end
  end
end
