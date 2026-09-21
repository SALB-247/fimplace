# frozen_string_literal: true
#
# 외국인용 영어 장소명·주소 주입 (2026-09-21)
#
# _data/places_en.yml (scripts/places_en.py 가 구글맵 hl=en 에서 채움: title → name_en / address_en / category_en) 을
# 노트 데이터에 얹는다:
#   note.data['name_en']     구글의 영어 이름 (한글이면 안 씀)
#   note.data['title_en']    "English name (한글 제목)" — note.html 의 h1 data-en 슬롯 (허브의 title_en 과 같은 자리). 이미 있으면 그대로
#   note.data['address_en']  영어 주소 → 본문 '## 위치' 문단 뒤에 <p class="addr-en i18n-en-only" hidden> 으로 붙는다 (영어 모드에서만 보임)
#   note.data['category_en'] 구글 카테고리 ('Convenience store') — note_summary_en 이 유형 라벨로 우선 쓴다
# priority :normal — places_generator(:low)·search_index(:low) 보다 먼저 돌아야 places.json·검색 색인에 실린다.

require 'nokogiri'

module PlacesEn
  HANGUL = /[가-힣]/

  module_function

  def norm(s)
    s.to_s.downcase.gsub(/[\s\-_·.'’"()]/, '')
  end

  # 이벤트 노트 제목의 날짜 접미('델룰루_250317-250319') → ['델룰루', '2025-03-17 – 2025-03-19'] (없으면 nil)
  def split_dates(title)
    m = title.to_s.match(/\A(.+?)_(\d{6})(?:-(\d{6}))?\z/)
    return nil unless m
    iso = lambda { |d| "20#{d[0, 2]}-#{d[2, 2]}-#{d[4, 2]}" }
    [m[1], m[3] ? "#{iso.call(m[2])} – #{iso.call(m[3])}" : iso.call(m[2])]
  end

  def apply(site)
    data = site.data['places_en'] || {}
    n = 0
    site.collections['notes'].docs.each do |note|
      title = note.data['title'].to_s
      rec = data[title]
      base, dates = split_dates(title)
      # 이벤트 노트의 날짜 접미는 영어 제목에서 ISO 날짜로 풀어 쓴다 ('델룰루 · 2025-03-17 – 2025-03-19') — 외국인에게 250317 은 읽히지 않는다
      note.data['title_en'] ||= "#{base} · #{dates}" if dates
      next unless rec.is_a?(Hash)
      name = rec['name_en'].to_s.strip
      # 제목이 한글·일본어·한자일 때만 영어 이름을 쓴다 — 이미 로마자 제목('Akakara Shinjuku')이면 그대로가 낫다
      if !name.empty? && name !~ HANGUL && title =~ /[가-힣぀-ヿ㐀-鿿]/
        note.data['name_en'] ||= name
        if norm(name) != norm(base || title)
          # 원제에 괄호가 있으면('조은뮤직 메세나폴리스 (Made My Night)') 괄호를 겹치지 않게 대시로 잇는다
          if dates
            note.data['title_en'] = "#{name} (#{base}) · #{dates}"
          elsif !note.data['title_en']
            note.data['title_en'] = title.include?('(') ? "#{name} — #{title}" : "#{name} (#{title})"
          end
        end
      end
      addr = rec['address_en'].to_s.strip
      note.data['address_en'] ||= addr unless addr.empty?
      note.data['category_en'] ||= rec['category_en'].to_s if rec['category_en'].to_s != ''
      n += 1
    end
    Jekyll.logger.info('PlacesEn', "영어 이름·주소 주입 #{n}건 (places_en.yml #{data.size})")
  end

  class Generator < Jekyll::Generator
    safe true
    priority :normal

    def generate(site)
      PlacesEn.apply(site)
    end
  end
end

# 본문: '## 위치'(또는 '## 주소') 다음 문단 뒤에 영어 주소 줄
Jekyll::Hooks.register [:notes], :post_convert do |doc|
  addr = doc.data['address_en'].to_s
  next if addr.empty? || doc.content.to_s.empty?
  frag = Nokogiri::HTML::DocumentFragment.parse(doc.content)
  h = frag.css('h2,h3').find { |x| %w[위치 주소].include?(x.text.strip) }
  next unless h
  nxt = h.next_element
  target = (nxt && nxt.name == 'p') ? nxt : h
  # 해외 노트처럼 본문 주소에 이미 영어 주소가 들어 있으면 중복이라 안 붙인다
  next if target.name == 'p' && target.text.downcase.include?(addr[0, 12].downcase)
  en = Nokogiri::XML::Node.new('p', frag.document)
  en['class'] = 'addr-en i18n-en-only'
  en['hidden'] = 'hidden'
  en.content = "📍 #{addr}"
  target.add_next_sibling(en)
  doc.content = frag.to_html
end
